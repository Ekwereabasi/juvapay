// // models/task_models.dart
// import 'dart:convert';


// class TaskModel {
//   final String id;
//   final DateTime createdAt;
//   final String category;
//   final String title;
//   final double price;
//   final String description;
//   final List<String> platforms;
//   final String iconKey;
//   final bool isFeatured;
//   final bool isActive;
//   final List<String> tags;
//   final Map<String, dynamic> metadata;
//   final String? difficulty;
//   final int? estimatedTime;
//   final int sortOrder;
//   final String status;

//   TaskModel({
//     required this.id,
//     required this.createdAt,
//     required this.category,
//     required this.title,
//     required this.price,
//     required this.description,
//     required this.platforms,
//     required this.iconKey,
//     this.isFeatured = false,
//     this.isActive = true,
//     this.tags = const [],
//     this.metadata = const {},
//     this.difficulty,
//     this.estimatedTime,
//     this.sortOrder = 0,
//     this.status = 'active',
//   });

//   factory TaskModel.fromMap(Map<String, dynamic> map) {
//     // Parse platforms
//     List<String> platforms = [];
//     if (map['platforms'] is List) {
//       platforms = List<String>.from(map['platforms']);
//     } else if (map['platforms'] is String) {
//       try {
//         final decoded = jsonDecode(map['platforms']);
//         if (decoded is List) {
//           platforms = List<String>.from(decoded);
//         }
//       } catch (_) {
//         platforms = [map['platforms']];
//       }
//     }

//     // Parse tags
//     List<String> tags = [];
//     if (map['tags'] is List) {
//       tags = List<String>.from(map['tags']);
//     }

//     // Parse metadata
//     Map<String, dynamic> metadata = {};
//     if (map['metadata'] is Map) {
//       metadata = Map<String, dynamic>.from(map['metadata']);
//     } else if (map['metadata'] is String) {
//       try {
//         metadata = jsonDecode(map['metadata']);
//       } catch (_) {
//         metadata = {};
//       }
//     }

//     // Determine active status from status field
//     final status = map['status']?.toString() ?? 'active';
//     final isActive = status == 'active';

//     return TaskModel(
//       id: map['id']?.toString() ?? '',
//       createdAt:
//           map['created_at'] != null
//               ? DateTime.parse(map['created_at'].toString())
//               : DateTime.now(),
//       category: map['category']?.toString() ?? '',
//       title: map['title']?.toString() ?? '',
//       price: (map['price'] as num?)?.toDouble() ?? 0.0,
//       description: map['description']?.toString() ?? '',
//       platforms: platforms,
//       iconKey: map['icon_key']?.toString() ?? 'work',
//       isFeatured: map['is_featured'] as bool? ?? false,
//       isActive: isActive,
//       status: status,
//       tags: tags,
//       metadata: metadata,
//       difficulty: map['difficulty']?.toString(),
//       estimatedTime: map['estimated_time'] as int?,
//       sortOrder: map['sort_order'] as int? ?? 0,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'created_at': createdAt.toIso8601String(),
//       'category': category,
//       'title': title,
//       'price': price,
//       'description': description,
//       'platforms': jsonEncode(platforms),
//       'icon_key': iconKey,
//       'is_featured': isFeatured,
//       'status': isActive ? 'active' : 'inactive',
//       'tags': tags,
//       'metadata': jsonEncode(metadata),
//       'difficulty': difficulty,
//       'estimated_time': estimatedTime,
//       'sort_order': sortOrder,
//     };
//   }

//   TaskModel copyWith({
//     String? id,
//     DateTime? createdAt,
//     String? category,
//     String? title,
//     double? price,
//     String? description,
//     List<String>? platforms,
//     String? iconKey,
//     bool? isFeatured,
//     bool? isActive,
//     List<String>? tags,
//     Map<String, dynamic>? metadata,
//     String? difficulty,
//     int? estimatedTime,
//     int? sortOrder,
//     String? status,
//   }) {
//     return TaskModel(
//       id: id ?? this.id,
//       createdAt: createdAt ?? this.createdAt,
//       category: category ?? this.category,
//       title: title ?? this.title,
//       price: price ?? this.price,
//       description: description ?? this.description,
//       platforms: platforms ?? this.platforms,
//       iconKey: iconKey ?? this.iconKey,
//       isFeatured: isFeatured ?? this.isFeatured,
//       isActive: isActive ?? this.isActive,
//       tags: tags ?? this.tags,
//       metadata: metadata ?? this.metadata,
//       difficulty: difficulty ?? this.difficulty,
//       estimatedTime: estimatedTime ?? this.estimatedTime,
//       sortOrder: sortOrder ?? this.sortOrder,
//       status: status ?? this.status,
//     );
//   }

//   // Helper methods
//   String get formattedPrice => '₦${price.toStringAsFixed(2)}';

//   List<String> get platformIcons {
//     return platforms.map((platform) {
//       switch (platform.toLowerCase()) {
//         case 'facebook':
//           return 'facebook';
//         case 'instagram':
//           return 'instagram';
//         case 'whatsapp':
//           return 'whatsapp';
//         case 'x':
//         case 'twitter':
//           return 'twitter';
//         case 'tiktok':
//           return 'tiktok';
//         case 'youtube':
//           return 'youtube';
//         case 'linkedin':
//           return 'linkedin';
//         case 'telegram':
//           return 'telegram';
//         default:
//           return 'link';
//       }
//     }).toList();
//   }
// }


// models/task_models.dart
import 'dart:convert';

class TaskModel {
  final String id;
  final DateTime createdAt;
  final String category;
  final String title;
  final double price;
  final String description;
  final List<String> platforms;
  final String iconKey;
  final String difficulty;
  final int? estimatedTime;
  final String status;
  final int sortOrder;
  final bool isFeatured;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final int version;
  final int minQuantity;
  final int maxQuantity;
  final List<dynamic> requirements;
  final List<dynamic> instructions;
  final double commissionRate;
  final double workerPayoutRate;

  TaskModel({
    required this.id,
    required this.createdAt,
    required this.category,
    required this.title,
    required this.price,
    required this.description,
    required this.platforms,
    required this.iconKey,
    required this.difficulty,
    this.estimatedTime,
    required this.status,
    this.sortOrder = 0,
    this.isFeatured = false,
    this.tags = const [],
    this.metadata = const {},
    this.version = 1,
    this.minQuantity = 1,
    this.maxQuantity = 10000,
    this.requirements = const [],
    this.instructions = const [],
    this.commissionRate = 0.20,
    this.workerPayoutRate = 0.80,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    // Parse platforms array
    List<String> platforms = [];
    if (map['platforms'] is List) {
      platforms = List<String>.from(map['platforms']);
    } else if (map['platforms'] is String) {
      try {
        final decoded = jsonDecode(map['platforms']);
        if (decoded is List) {
          platforms = List<String>.from(decoded);
        }
      } catch (_) {
        platforms = [map['platforms']];
      }
    }

    // Parse tags array
    List<String> tags = [];
    if (map['tags'] is List) {
      tags = List<String>.from(map['tags']);
    }

    // Parse metadata
    Map<String, dynamic> metadata = {};
    if (map['metadata'] is Map) {
      metadata = Map<String, dynamic>.from(map['metadata']);
    } else if (map['metadata'] is String) {
      try {
        metadata = jsonDecode(map['metadata']);
      } catch (_) {
        metadata = {};
      }
    }

    // Parse requirements and instructions
    List<dynamic> requirements = [];
    if (map['requirements'] is List) {
      requirements = List<dynamic>.from(map['requirements']);
    } else if (map['requirements'] is String) {
      try {
        requirements = jsonDecode(map['requirements']);
      } catch (_) {
        requirements = [];
      }
    }

    List<dynamic> instructions = [];
    if (map['instructions'] is List) {
      instructions = List<dynamic>.from(map['instructions']);
    } else if (map['instructions'] is String) {
      try {
        instructions = jsonDecode(map['instructions']);
      } catch (_) {
        instructions = [];
      }
    }

    return TaskModel(
      id: map['id']?.toString() ?? '',
      createdAt:
          map['created_at'] != null
              ? DateTime.parse(map['created_at'].toString())
              : DateTime.now(),
      category: map['category']?.toString() ?? 'social',
      title: map['title']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      description: map['description']?.toString() ?? '',
      platforms: platforms,
      iconKey: map['icon_key']?.toString() ?? 'work',
      difficulty: map['difficulty']?.toString() ?? 'medium',
      estimatedTime: map['estimated_time'] as int?,
      status: map['status']?.toString() ?? 'active',
      sortOrder: map['sort_order'] as int? ?? 0,
      isFeatured: map['is_featured'] as bool? ?? false,
      tags: tags,
      metadata: metadata,
      version: map['version'] as int? ?? 1,
      minQuantity: map['min_quantity'] as int? ?? 1,
      maxQuantity: map['max_quantity'] as int? ?? 10000,
      requirements: requirements,
      instructions: instructions,
      commissionRate: (map['commission_rate'] as num?)?.toDouble() ?? 0.20,
      workerPayoutRate: (map['worker_payout_rate'] as num?)?.toDouble() ?? 0.80,
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
      'platforms': jsonEncode(platforms),
      'icon_key': iconKey,
      'difficulty': difficulty,
      'estimated_time': estimatedTime,
      'status': status,
      'sort_order': sortOrder,
      'is_featured': isFeatured,
      'tags': tags,
      'metadata': jsonEncode(metadata),
      'version': version,
      'min_quantity': minQuantity,
      'max_quantity': maxQuantity,
      'requirements': jsonEncode(requirements),
      'instructions': jsonEncode(instructions),
      'commission_rate': commissionRate,
      'worker_payout_rate': workerPayoutRate,
    };
  }

  TaskModel copyWith({
    String? id,
    DateTime? createdAt,
    String? category,
    String? title,
    double? price,
    String? description,
    List<String>? platforms,
    String? iconKey,
    String? difficulty,
    int? estimatedTime,
    String? status,
    int? sortOrder,
    bool? isFeatured,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    int? version,
    int? minQuantity,
    int? maxQuantity,
    List<dynamic>? requirements,
    List<dynamic>? instructions,
    double? commissionRate,
    double? workerPayoutRate,
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
      difficulty: difficulty ?? this.difficulty,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      isFeatured: isFeatured ?? this.isFeatured,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      version: version ?? this.version,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      requirements: requirements ?? this.requirements,
      instructions: instructions ?? this.instructions,
      commissionRate: commissionRate ?? this.commissionRate,
      workerPayoutRate: workerPayoutRate ?? this.workerPayoutRate,
    );
  }

  // Helper methods
  String get formattedPrice => '₦${price.toStringAsFixed(2)}';
  bool get isActive => status == 'active';

  List<String> get platformIcons {
    return platforms.map((platform) {
      switch (platform.toLowerCase()) {
        case 'facebook':
          return 'facebook';
        case 'instagram':
          return 'instagram';
        case 'whatsapp':
          return 'whatsapp';
        case 'x':
        case 'twitter':
          return 'twitter';
        case 'tiktok':
          return 'tiktok';
        case 'youtube':
          return 'youtube';
        case 'linkedin':
          return 'linkedin';
        case 'telegram':
          return 'telegram';
        default:
          return 'link';
      }
    }).toList();
  }
}
