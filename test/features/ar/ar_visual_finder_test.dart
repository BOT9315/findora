import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_my_stuff_ai/features/ar/presentation/ar_visual_finder_screen.dart';
import 'package:find_my_stuff_ai/features/ar/services/ar_compatibility_service.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('ArCompatibilityService', () {
    test('checkArSupport returns assessment with documented technical limitations', () async {
      final service = ArCompatibilityService.instance;
      final assessment = await service.checkArSupport();

      expect(assessment, isNotNull);
      expect(assessment.technicalLimitations.isNotEmpty, isTrue);
      expect(assessment.canRunLiveFinder, isTrue);
      expect(
        assessment.technicalLimitations.any((l) => l.contains('Visual Drift')),
        isTrue,
      );
      expect(
        assessment.technicalLimitations.any((l) => l.contains('Physical Movement')),
        isTrue,
      );
    });
  });

  group('ArVisualFinderScreen Widget', () {
    testWidgets('renders finder screen and targeting reticle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ArVisualFinderScreen(
            targetItemName: 'House Keys',
            targetLocation: 'Kitchen Counter',
          ),
        ),
      );

      // Pump through async init
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AR Finder: House Keys'), findsOneWidget);
      expect(find.text('Searching for "House Keys"'), findsOneWidget);
      expect(find.text('Point camera toward Kitchen Counter surface'), findsOneWidget);
      expect(find.text('Lock Target on Surface'), findsOneWidget);
    });
  });
}
