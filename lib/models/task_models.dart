// models/task_models.dart
class TaskModel {
  final String id;
  final DateTime createdAt;
  final String category;
  final String title;
  final double price;
  final String description;
  final List<String> platforms;
  final String iconKey;
  final bool isFeatured;
  final bool isActive; // Added this field to resolve the Service error
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final String? difficulty;
  final int? estimatedTime;
  final int sortOrder;

  TaskModel({
    required this.id,
    required this.createdAt,
    required this.category,
    required this.title,
    required this.price,
    required this.description,
    required this.platforms,
    required this.iconKey,
    this.isFeatured = false,
    this.isActive = true, // Default to true
    this.tags = const [],
    this.metadata = const {},
    this.difficulty,
    this.estimatedTime,
    this.sortOrder = 0,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id']?.toString() ?? '',
      createdAt:
          map['created_at'] != null
              ? DateTime.parse(map['created_at'].toString())
              : DateTime.now(),
      category: map['category']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      description: map['description']?.toString() ?? '',
      platforms:
          (map['platforms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      iconKey: map['icon_key']?.toString() ?? 'work',
      isFeatured: map['is_featured'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true, // Map from DB is_active
      tags:
          (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      metadata: (map['metadata'] as Map<String, dynamic>?) ?? {},
      difficulty: map['difficulty']?.toString(),
      estimatedTime: map['estimated_time'] as int?,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'category': category,
      'title': title,
      'price': price,
      'description': description,
      'platforms': platforms,
      'icon_key': iconKey,
      'is_featured': isFeatured,
      'is_active': isActive, // Save back to DB as is_active
      'tags': tags,
      'metadata': metadata,
      'difficulty': difficulty,
      'estimated_time': estimatedTime,
      'sort_order': sortOrder,
    };
  }

  // Added copyWith to make state management easier in the future
  TaskModel copyWith({
    String? id,
    DateTime? createdAt,
    String? category,
    String? title,
    double? price,
    String? description,
    List<String>? platforms,
    String? iconKey,
    bool? isFeatured,
    bool? isActive,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    String? difficulty,
    int? estimatedTime,
    int? sortOrder,
  }) {
    return TaskModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      platforms: platforms ?? this.platforms,
      iconKey: iconKey ?? this.iconKey,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      difficulty: difficulty ?? this.difficulty,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
