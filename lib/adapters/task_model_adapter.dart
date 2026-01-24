// adapters/task_model_adapter.dart
import 'package:hive/hive.dart';
import '../models/task_models.dart';

part 'task_model_adapter.g.dart';

@HiveType(typeId: 1)
class TaskModelAdapter {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final double price;

  @HiveField(5)
  final String description;

  @HiveField(6)
  final List<String> platforms;

  @HiveField(7)
  final String iconKey;

  @HiveField(8)
  final bool isFeatured;

  @HiveField(9)
  final List<String> tags;

  @HiveField(10)
  final Map<String, dynamic> metadata;

  @HiveField(11) // Add this
  final String? difficulty;

  @HiveField(12) // Add this
  final int? estimatedTime;

  TaskModelAdapter({
    required this.id,
    required this.createdAt,
    required this.category,
    required this.title,
    required this.price,
    required this.description,
    required this.platforms,
    required this.iconKey,
    required this.isFeatured,
    required this.tags,
    required this.metadata,
    required this.difficulty, // Add this
    required this.estimatedTime, // Add this
  });

  // Convert TaskModel to TaskModelAdapter
  static TaskModelAdapter fromTaskModel(TaskModel task) {
    return TaskModelAdapter(
      id: task.id,
      createdAt: task.createdAt,
      category: task.category,
      title: task.title,
      price: task.price,
      description: task.description,
      platforms: task.platforms,
      iconKey: task.iconKey,
      isFeatured: task.isFeatured,
      tags: task.tags,
      metadata: task.metadata,
      difficulty: task.difficulty, // Add this
      estimatedTime: task.estimatedTime, // Add this
    );
  }

  // Convert TaskModelAdapter to TaskModel
  TaskModel toTaskModel() {
    return TaskModel(
      id: id,
      createdAt: createdAt,
      category: category,
      title: title,
      price: price,
      description: description,
      platforms: platforms,
      iconKey: iconKey,
      isFeatured: isFeatured,
      tags: tags,
      metadata: metadata,
      difficulty: difficulty, // Add this
      estimatedTime: estimatedTime, // Add this
    );
  }
}
