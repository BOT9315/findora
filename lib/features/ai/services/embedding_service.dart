import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/schema_constants.dart';
import '../domain/detected_object.dart';
import '../domain/visual_embedding.dart';

class EmbeddingService {
  EmbeddingService._internal();
  static final EmbeddingService instance = EmbeddingService._internal();

  static const int embeddingDimension = 64;

  static const List<String> _commonTokens = [
    'charger', 'cable', 'wire', 'adapter', 'plug', 'usb',
    'keys', 'keychain', 'car', 'house', 'lock',
    'wallet', 'card', 'id', 'college', 'badge', 'purse',
    'headphones', 'airpods', 'earbuds', 'buds',
    'glasses', 'spectacles', 'sunglasses',
    'backpack', 'bag', 'tote', 'laptop', 'macbook',
    'desk', 'table', 'shelf', 'bedroom', 'kitchen', 'office',
    'black', 'white', 'blue', 'red', 'green', 'yellow', 'silver', 'brown',
    'phone', 'watch', 'water', 'bottle', 'notebook', 'pen', 'book',
  ];

  /// Generates a dense 64-D embedding vector for a memory
  Future<VisualEmbedding> generateImageEmbedding({
    required String memoryId,
    required List<DetectedObject> detectedObjects,
    required String locationLabel,
    required Map<String, dynamic> visualMetadata,
    String? notes,
  }) async {
    final vector = List<double>.filled(embeddingDimension, 0.0);

    final dominantColor =
        (visualMetadata['dominantColor'] as String?) ?? 'grey';
    final brightness =
        ((visualMetadata['brightness'] as num?)?.toDouble() ?? 128.0) / 255.0;
    final colorIdx = _getColorIndex(dominantColor);
    vector[colorIdx % 8] += 0.8;
    vector[7] = brightness;

    for (final obj in detectedObjects) {
      _embedToken(vector, obj.label.toLowerCase(), weight: obj.confidence);
      if (obj.color != null) {
        _embedToken(vector, obj.color!.toLowerCase(), weight: 0.6);
      }
      if (obj.material != null) {
        _embedToken(vector, obj.material!.toLowerCase(), weight: 0.5);
      }
    }

    _embedToken(vector, locationLabel.toLowerCase(), weight: 0.7);

    if (notes != null && notes.isNotEmpty) {
      final words = notes.toLowerCase().split(RegExp(r'\s+'));
      for (final word in words) {
        _embedToken(vector, word, weight: 0.5);
      }
    }

    _l2Normalize(vector);

    final embedding = VisualEmbedding(
      memoryId: memoryId,
      vector: vector,
      dimension: embeddingDimension,
      createdAt: DateTime.now(),
    );

    await saveEmbedding(embedding);
    return embedding;
  }

  /// Generates a dense 64-D embedding for a text query
  List<double> generateQueryEmbedding(String query) {
    final vector = List<double>.filled(embeddingDimension, 0.0);
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((t) => t.isNotEmpty);

    for (final token in tokens) {
      _embedToken(vector, token, weight: 1.0);
    }

    _l2Normalize(vector);
    return vector;
  }

  /// Generates a dense 64-D embedding directly from an image file for multimodal search
  Future<List<double>> generateImageQueryEmbedding(File imageFile) async {
    final vector = List<double>.filled(embeddingDimension, 0.0);
    try {
      if (!await imageFile.exists()) return vector;
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return vector;

      int rTotal = 0, gTotal = 0, bTotal = 0;
      final sampleStep = (image.width * image.height / 2000).clamp(1, 100).toInt();
      int count = 0;
      for (int i = 0; i < image.width * image.height; i += sampleStep) {
        final pixel = image.getPixel(i % image.width, i ~/ image.width);
        rTotal += pixel.r.toInt();
        gTotal += pixel.g.toInt();
        bTotal += pixel.b.toInt();
        count++;
      }
      final rAvg = count > 0 ? rTotal / count : 128.0;
      final gAvg = count > 0 ? gTotal / count : 128.0;
      final bAvg = count > 0 ? bTotal / count : 128.0;
      final brightness = (0.299 * rAvg + 0.587 * gAvg + 0.114 * bAvg) / 255.0;

      String color = 'grey';
      if (rAvg > 160 && gAvg < 100 && bAvg < 100) {
        color = 'red';
      } else if (bAvg > 160 && rAvg < 100) {
        color = 'blue';
      } else if (gAvg > 160 && rAvg < 100) {
        color = 'green';
      } else if (rAvg > 180 && gAvg > 180 && bAvg > 180) {
        color = 'white';
      } else if (rAvg < 60 && gAvg < 60 && bAvg < 60) {
        color = 'black';
      } else if (rAvg > 160 && gAvg > 160 && bAvg < 80) {
        color = 'yellow';
      }

      final colorIdx = _getColorIndex(color);
      vector[colorIdx % 8] += 0.9;
      vector[7] = brightness;

      for (int s = 0; s < 8; s++) {
        final sx = (s % 4) * (image.width ~/ 4);
        final sy = (s ~/ 4) * (image.height ~/ 2);
        final px = image.getPixel(
          (sx + (image.width ~/ 8)).clamp(0, image.width - 1),
          (sy + (image.height ~/ 4)).clamp(0, image.height - 1),
        );
        final lum = (0.299 * px.r + 0.587 * px.g + 0.114 * px.b) / 255.0;
        vector[8 + s] += lum * 0.8;
      }

      _l2Normalize(vector);
    } catch (_) {
      // Return unpopulated vector on error
    }
    return vector;
  }

  void _embedToken(List<double> vector, String token,
      {required double weight}) {
    if (token.isEmpty) return;

    for (int i = 0; i < _commonTokens.length; i++) {
      if (_commonTokens[i] == token ||
          token.contains(_commonTokens[i])) {
        final dim = (8 + i) % embeddingDimension;
        vector[dim] += weight * 1.2;
      }
    }

    int hash = 5381;
    for (int i = 0; i < token.length; i++) {
      hash = ((hash << 5) + hash) + token.codeUnitAt(i);
    }
    final targetDim = (hash.abs() % (embeddingDimension - 8)) + 8;
    vector[targetDim] += weight * 0.7;
  }

  void _l2Normalize(List<double> vector) {
    double norm = 0.0;
    for (final val in vector) {
      norm += val * val;
    }
    norm = math.sqrt(norm);
    if (norm > 0.0) {
      for (int i = 0; i < vector.length; i++) {
        vector[i] /= norm;
      }
    }
  }

  int _getColorIndex(String color) {
    switch (color) {
      case 'black':
        return 0;
      case 'white':
        return 1;
      case 'blue':
        return 2;
      case 'red':
        return 3;
      case 'green':
        return 4;
      case 'yellow':
        return 5;
      case 'brown':
        return 6;
      default:
        return 7;
    }
  }

  Future<void> saveEmbedding(VisualEmbedding embedding) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      SchemaConstants.tableEmbeddings,
      embedding.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, VisualEmbedding>> getAllEmbeddings() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(SchemaConstants.tableEmbeddings);

    final Map<String, VisualEmbedding> map = {};
    for (final row in results) {
      final emb = VisualEmbedding.fromMap(row);
      map[emb.memoryId] = emb;
    }
    return map;
  }
}
