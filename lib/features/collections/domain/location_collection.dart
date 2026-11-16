class LocationCollection {
  final String id;
  final String name;
  final String iconName;
  final String? description;
  final DateTime createdAt;
  final int memoryCount;

  const LocationCollection({
    required this.id,
    required this.name,
    required this.iconName,
    this.description,
    required this.createdAt,
    this.memoryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory LocationCollection.fromMap(Map<String, dynamic> map, {int count = 0}) {
    return LocationCollection(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: (map['icon_name'] as String?) ?? 'folder',
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      memoryCount: count,
    );
  }

  LocationCollection copyWith({
    String? id,
    String? name,
    String? iconName,
    String? description,
    DateTime? createdAt,
    int? memoryCount,
  }) {
    return LocationCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      memoryCount: memoryCount ?? this.memoryCount,
    );
  }
}
