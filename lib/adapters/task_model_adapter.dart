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
  final String difficulty;

  @HiveField(9)
  final int? estimatedTime;

  @HiveField(10)
  final String status;

  @HiveField(11)
  final int sortOrder;

  @HiveField(12)
  final bool isFeatured;

  @HiveField(13)
  final List<String> tags;

  @HiveField(14)
  final Map<String, dynamic> metadata;

  @HiveField(15)
  final int version;

  @HiveField(16)
  final int minQuantity;

  @HiveField(17)
  final int maxQuantity;

  @HiveField(18)
  final List<dynamic> requirements;

  @HiveField(19)
  final List<dynamic> instructions;

  @HiveField(20)
  final double commissionRate;

  @HiveField(21)
  final double workerPayoutRate;

  TaskModelAdapter({
    required this.id,
    required this.createdAt,
    required this.category,
    required this.title,
    required this.price,
    required this.description,
    required this.platforms,
    required this.iconKey,
    required this.difficulty,
    required this.estimatedTime,
    required this.status,
    required this.sortOrder,
    required this.isFeatured,
    required this.tags,
    required this.metadata,
    required this.version,
    required this.minQuantity,
    required this.maxQuantity,
    required this.requirements,
    required this.instructions,
    required this.commissionRate,
    required this.workerPayoutRate,
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
      difficulty: task.difficulty,
      estimatedTime: task.estimatedTime,
      status: task.status,
      sortOrder: task.sortOrder,
      isFeatured: task.isFeatured,
      tags: task.tags,
      metadata: task.metadata,
      version: task.version,
      minQuantity: task.minQuantity,
      maxQuantity: task.maxQuantity,
      requirements: task.requirements,
      instructions: task.instructions,
      commissionRate: task.commissionRate,
      workerPayoutRate: task.workerPayoutRate,
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
      difficulty: difficulty,
      estimatedTime: estimatedTime,
      status: status,
      sortOrder: sortOrder,
      isFeatured: isFeatured,
      tags: tags,
      metadata: metadata,
      version: version,
      minQuantity: minQuantity,
      maxQuantity: maxQuantity,
      requirements: requirements,
      instructions: instructions,
      commissionRate: commissionRate,
      workerPayoutRate: workerPayoutRate,
    );
  }
}
