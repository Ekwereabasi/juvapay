// // services/task_service.dart
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/task_models.dart';
// import '../services/cache_service.dart';

// class TaskService {
//   final SupabaseClient _supabase = Supabase.instance.client;
//   final CacheService _cacheService = CacheService();

//   // Fetch tasks by category from task_catalog table
//   Future<List<TaskModel>> getTasksByCategory(String category) async {
//     try {
//       debugPrint('Fetching tasks for category: $category');

//       final response = await _supabase
//           .from('task_catalog')
//           .select()
//           .eq('category', category)
//           .eq('status', 'active')
//           .order('sort_order', ascending: true)
//           .order('price', ascending: true);

//       if (response == null) {
//         debugPrint('No response from task_catalog');
//         return [];
//       }

//       debugPrint('Raw response from task_catalog: ${response.length} items');

//       final tasks = List<TaskModel>.from(
//         response
//             .map((taskData) {
//               try {
//                 // Parse platforms array
//                 List<String> platforms = [];
//                 if (taskData['platforms'] is List) {
//                   platforms = List<String>.from(taskData['platforms']);
//                 } else if (taskData['platforms'] is String) {
//                   // Handle string format if needed
//                   platforms = [taskData['platforms']];
//                 }

//                 // Parse tags array
//                 List<String> tags = [];
//                 if (taskData['tags'] is List) {
//                   tags = List<String>.from(taskData['tags']);
//                 }

//                 // Parse metadata
//                 Map<String, dynamic> metadata = {};
//                 if (taskData['metadata'] is Map) {
//                   metadata = Map<String, dynamic>.from(taskData['metadata']);
//                 } else if (taskData['metadata'] is String) {
//                   try {
//                     metadata = json.decode(taskData['metadata']);
//                   } catch (e) {
//                     debugPrint('Error parsing metadata: $e');
//                   }
//                 }

//                 return TaskModel(
//                   id: taskData['id']?.toString() ?? '',
//                   title: taskData['title']?.toString() ?? 'Unknown Task',
//                   price: (taskData['price'] as num?)?.toDouble() ?? 0.0,
//                   description: taskData['description']?.toString() ?? '',
//                   category: taskData['category']?.toString() ?? 'advert',
//                   platforms: platforms,
//                   iconKey: taskData['icon_key']?.toString() ?? 'star',
//                   tags: tags,
//                   isFeatured: taskData['is_featured'] as bool? ?? false,
//                   metadata: metadata,
//                   createdAt:
//                       taskData['created_at'] != null
//                           ? DateTime.parse(taskData['created_at'].toString())
//                           : DateTime.now(),
//                   difficulty: taskData['difficulty']?.toString(),
//                   estimatedTime: taskData['estimated_time'] as int?,
//                 );
//               } catch (e) {
//                 debugPrint('Error parsing task data: $e');
//                 debugPrint('Task data: $taskData');
//                 return null;
//               }
//             })
//             .where((task) => task != null),
//       );

//       debugPrint('Successfully parsed ${tasks.length} tasks');
//       return tasks;
//     } catch (e, stackTrace) {
//       debugPrint('Error fetching tasks by category: $e');
//       debugPrint('Stack trace: $stackTrace');

//       // Try to get from cache
//       try {
//         final cachedTasks = await _cacheService.getCachedTasks();
//         if (cachedTasks.isNotEmpty) {
//           return cachedTasks
//               .where((task) => task.category == category)
//               .toList();
//         }
//       } catch (cacheError) {
//         debugPrint('Error getting cached tasks: $cacheError');
//       }

//       return [];
//     }
//   }

//   // Get featured tasks
//   Future<List<TaskModel>> getFeaturedTasks() async {
//     try {
//       debugPrint('Fetching featured tasks');

//       final response = await _supabase
//           .from('task_catalog')
//           .select()
//           .eq('status', 'active')
//           .eq('is_featured', true)
//           .order('sort_order', ascending: true)
//           .limit(5);

//       if (response == null) {
//         return [];
//       }

//       return List<TaskModel>.from(
//         response.map((taskData) {
//           // Parse platforms array
//           List<String> platforms = [];
//           if (taskData['platforms'] is List) {
//             platforms = List<String>.from(taskData['platforms']);
//           }

//           // Parse tags array
//           List<String> tags = [];
//           if (taskData['tags'] is List) {
//             tags = List<String>.from(taskData['tags']);
//           }

//           // Parse metadata
//           Map<String, dynamic> metadata = {};
//           if (taskData['metadata'] is Map) {
//             metadata = Map<String, dynamic>.from(taskData['metadata']);
//           }

//           return TaskModel(
//             id: taskData['id']?.toString() ?? '',
//             title: taskData['title']?.toString() ?? 'Unknown Task',
//             price: (taskData['price'] as num?)?.toDouble() ?? 0.0,
//             description: taskData['description']?.toString() ?? '',
//             category: taskData['category']?.toString() ?? 'advert',
//             platforms: platforms,
//             iconKey: taskData['icon_key']?.toString() ?? 'star',
//             tags: tags,
//             isFeatured: taskData['is_featured'] as bool? ?? false,
//             metadata: metadata,
//             createdAt:
//                 taskData['created_at'] != null
//                     ? DateTime.parse(taskData['created_at'].toString())
//                     : DateTime.now(),
//             difficulty: taskData['difficulty']?.toString(),
//             estimatedTime: taskData['estimated_time'] as int?,
//           );
//         }),
//       );
//     } catch (e) {
//       debugPrint('Error fetching featured tasks: $e');

//       // Try to get from cache
//       try {
//         final cachedTasks = await _cacheService.getCachedTasks();
//         if (cachedTasks.isNotEmpty) {
//           return cachedTasks.where((task) => task.isFeatured).take(5).toList();
//         }
//       } catch (cacheError) {
//         debugPrint('Error getting cached tasks: $cacheError');
//       }

//       return [];
//     }
//   }

//   // Get all active tasks (for HomeView) with caching support
//   Future<List<TaskModel>> getActiveTasks() async {
//     try {
//       final response = await _supabase
//           .from('task_catalog')
//           .select()
//           .eq('status', 'active')
//           .order('sort_order', ascending: true)
//           .order('is_featured', ascending: false);

//       if (response == null) {
//         // Try to get from cache
//         try {
//           final cachedTasks = await _cacheService.getCachedTasks();
//           if (cachedTasks.isNotEmpty) {
//             return cachedTasks;
//           }
//         } catch (cacheError) {
//           debugPrint('Error getting cached tasks: $cacheError');
//         }
//         return [];
//       }

//       final tasks = List<TaskModel>.from(
//         response.map((taskData) {
//           // Parse platforms array
//           List<String> platforms = [];
//           if (taskData['platforms'] is List) {
//             platforms = List<String>.from(taskData['platforms']);
//           }

//           // Parse tags array
//           List<String> tags = [];
//           if (taskData['tags'] is List) {
//             tags = List<String>.from(taskData['tags']);
//           }

//           // Parse metadata
//           Map<String, dynamic> metadata = {};
//           if (taskData['metadata'] is Map) {
//             metadata = Map<String, dynamic>.from(taskData['metadata']);
//           }

//           return TaskModel(
//             id: taskData['id']?.toString() ?? '',
//             title: taskData['title']?.toString() ?? 'Unknown Task',
//             price: (taskData['price'] as num?)?.toDouble() ?? 0.0,
//             description: taskData['description']?.toString() ?? '',
//             category: taskData['category']?.toString() ?? 'advert',
//             platforms: platforms,
//             iconKey: taskData['icon_key']?.toString() ?? 'star',
//             tags: tags,
//             isFeatured: taskData['is_featured'] as bool? ?? false,
//             metadata: metadata,
//             createdAt:
//                 taskData['created_at'] != null
//                     ? DateTime.parse(taskData['created_at'].toString())
//                     : DateTime.now(),
//             difficulty: taskData['difficulty']?.toString(),
//             estimatedTime: taskData['estimated_time'] as int?,
//           );
//         }),
//       );

//       // Cache the tasks
//       await _cacheService.cacheTasks(tasks);

//       return tasks;
//     } catch (e) {
//       debugPrint('Error fetching active tasks: $e');

//       // Try to get from cache
//       try {
//         final cachedTasks = await _cacheService.getCachedTasks();
//         if (cachedTasks.isNotEmpty) {
//           return cachedTasks;
//         }
//       } catch (cacheError) {
//         debugPrint('Error getting cached tasks: $cacheError');
//       }

//       return [];
//     }
//   }

//   // Get task by ID
//   Future<TaskModel?> getTaskById(String taskId) async {
//     try {
//       final response =
//           await _supabase
//               .from('task_catalog')
//               .select()
//               .eq('id', taskId)
//               .eq('status', 'active')
//               .single();

//       if (response == null) {
//         // Try to get from cache
//         try {
//           final cachedTasks = await _cacheService.getCachedTasks();
//           for (var task in cachedTasks) {
//             if (task.id == taskId) {
//               return task;
//             }
//           }
//           return null;
//         } catch (cacheError) {
//           debugPrint('Error getting cached task: $cacheError');
//           return null;
//         }
//       }

//       // Parse platforms array
//       List<String> platforms = [];
//       if (response['platforms'] is List) {
//         platforms = List<String>.from(response['platforms']);
//       }

//       // Parse tags array
//       List<String> tags = [];
//       if (response['tags'] is List) {
//         tags = List<String>.from(response['tags']);
//       }

//       // Parse metadata
//       Map<String, dynamic> metadata = {};
//       if (response['metadata'] is Map) {
//         metadata = Map<String, dynamic>.from(response['metadata']);
//       }

//       return TaskModel(
//         id: response['id']?.toString() ?? '',
//         title: response['title']?.toString() ?? 'Unknown Task',
//         price: (response['price'] as num?)?.toDouble() ?? 0.0,
//         description: response['description']?.toString() ?? '',
//         category: response['category']?.toString() ?? 'advert',
//         platforms: platforms,
//         iconKey: response['icon_key']?.toString() ?? 'star',
//         tags: tags,
//         isFeatured: response['is_featured'] as bool? ?? false,
//         metadata: metadata,
//         createdAt:
//             response['created_at'] != null
//                 ? DateTime.parse(response['created_at'].toString())
//                 : DateTime.now(),
//         difficulty: response['difficulty']?.toString(),
//         estimatedTime: response['estimated_time'] as int?,
//       );
//     } catch (e) {
//       debugPrint('Error fetching task by ID: $e');

//       // Try to get from cache
//       try {
//         final cachedTasks = await _cacheService.getCachedTasks();
//         for (var task in cachedTasks) {
//           if (task.id == taskId) {
//             return task;
//           }
//         }
//         return null;
//       } catch (cacheError) {
//         debugPrint('Error getting cached task: $cacheError');
//         return null;
//       }
//     }
//   }

//   // Search tasks
//   Future<List<TaskModel>> searchTasks(String query) async {
//     try {
//       final response = await _supabase
//           .from('task_catalog')
//           .select()
//           .or(
//             'title.ilike.%$query%,description.ilike.%$query%,tags.cs.{${query.toLowerCase()}}',
//           )
//           .eq('status', 'active')
//           .order('is_featured', ascending: false);

//       if (response == null) {
//         // Try to get from cache
//         try {
//           final cachedTasks = await _cacheService.getCachedTasks();
//           if (query.isEmpty) return cachedTasks;

//           return cachedTasks.where((task) {
//             return task.title.toLowerCase().contains(query.toLowerCase()) ||
//                 task.description.toLowerCase().contains(query.toLowerCase()) ||
//                 task.tags.any(
//                   (tag) => tag.toLowerCase().contains(query.toLowerCase()),
//                 );
//           }).toList();
//         } catch (cacheError) {
//           debugPrint('Error getting cached tasks: $cacheError');
//           return [];
//         }
//       }

//       return List<TaskModel>.from(
//         response.map((taskData) {
//           // Parse platforms array
//           List<String> platforms = [];
//           if (taskData['platforms'] is List) {
//             platforms = List<String>.from(taskData['platforms']);
//           }

//           // Parse tags array
//           List<String> tags = [];
//           if (taskData['tags'] is List) {
//             tags = List<String>.from(taskData['tags']);
//           }

//           // Parse metadata
//           Map<String, dynamic> metadata = {};
//           if (taskData['metadata'] is Map) {
//             metadata = Map<String, dynamic>.from(taskData['metadata']);
//           }

//           return TaskModel(
//             id: taskData['id']?.toString() ?? '',
//             title: taskData['title']?.toString() ?? 'Unknown Task',
//             price: (taskData['price'] as num?)?.toDouble() ?? 0.0,
//             description: taskData['description']?.toString() ?? '',
//             category: taskData['category']?.toString() ?? 'advert',
//             platforms: platforms,
//             iconKey: taskData['icon_key']?.toString() ?? 'star',
//             tags: tags,
//             isFeatured: taskData['is_featured'] as bool? ?? false,
//             metadata: metadata,
//             createdAt:
//                 taskData['created_at'] != null
//                     ? DateTime.parse(taskData['created_at'].toString())
//                     : DateTime.now(),
//             difficulty: taskData['difficulty']?.toString(),
//             estimatedTime: taskData['estimated_time'] as int?,
//           );
//         }),
//       );
//     } catch (e) {
//       debugPrint('Error searching tasks: $e');

//       // Try to get from cache
//       try {
//         final cachedTasks = await _cacheService.getCachedTasks();
//         if (query.isEmpty) return cachedTasks;

//         return cachedTasks.where((task) {
//           return task.title.toLowerCase().contains(query.toLowerCase()) ||
//               task.description.toLowerCase().contains(query.toLowerCase()) ||
//               task.tags.any(
//                 (tag) => tag.toLowerCase().contains(query.toLowerCase()),
//               );
//         }).toList();
//       } catch (cacheError) {
//         debugPrint('Error getting cached tasks: $cacheError');
//         return [];
//       }
//     }
//   }

//   // Get tasks by platform
//   Future<List<TaskModel>> getTasksByPlatform(String platform) async {
//     try {
//       final response = await _supabase
//           .from('task_catalog')
//           .select()
//           .eq('status', 'active')
//           .contains('platforms', [platform])
//           .order('sort_order', ascending: true);

//       if (response == null) {
//         // Try to get from cache
//         try {
//           final cachedTasks = await _cacheService.getCachedTasks();
//           return cachedTasks
//               .where((task) => task.platforms.contains(platform))
//               .toList();
//         } catch (cacheError) {
//           debugPrint('Error getting cached tasks: $cacheError');
//           return [];
//         }
//       }

//       return List<TaskModel>.from(
//         response.map((taskData) {
//           // Parse platforms array
//           List<String> platforms = [];
//           if (taskData['platforms'] is List) {
//             platforms = List<String>.from(taskData['platforms']);
//           }

//           // Parse tags array
//           List<String> tags = [];
//           if (taskData['tags'] is List) {
//             tags = List<String>.from(taskData['tags']);
//           }

//           // Parse metadata
//           Map<String, dynamic> metadata = {};
//           if (taskData['metadata'] is Map) {
//             metadata = Map<String, dynamic>.from(taskData['metadata']);
//           }

//           return TaskModel(
//             id: taskData['id']?.toString() ?? '',
//             title: taskData['title']?.toString() ?? 'Unknown Task',
//             price: (taskData['price'] as num?)?.toDouble() ?? 0.0,
//             description: taskData['description']?.toString() ?? '',
//             category: taskData['category']?.toString() ?? 'advert',
//             platforms: platforms,
//             iconKey: taskData['icon_key']?.toString() ?? 'star',
//             tags: tags,
//             isFeatured: taskData['is_featured'] as bool? ?? false,
//             metadata: metadata,
//             createdAt:
//                 taskData['created_at'] != null
//                     ? DateTime.parse(taskData['created_at'].toString())
//                     : DateTime.now(),
//             difficulty: taskData['difficulty']?.toString(),
//             estimatedTime: taskData['estimated_time'] as int?,
//           );
//         }),
//       );
//     } catch (e) {
//       debugPrint('Error getting tasks by platform: $e');

//       // Try to get from cache
//       try {
//         final cachedTasks = await _cacheService.getCachedTasks();
//         return cachedTasks
//             .where((task) => task.platforms.contains(platform))
//             .toList();
//       } catch (cacheError) {
//         debugPrint('Error getting cached tasks: $cacheError');
//         return [];
//       }
//     }
//   }

//   // Get tasks with caching support for offline mode
//   Future<List<TaskModel>> getTasksWithCache({bool forceRefresh = false}) async {
//     // Try to get from cache first if not forcing refresh
//     if (!forceRefresh) {
//       try {
//         final cachedTasks = await _cacheService.getCachedTasks();
//         if (cachedTasks.isNotEmpty) {
//           // Check if cache is stale (older than 5 minutes)
//           final isCacheExpired = await _cacheService.isCacheExpired('tasks');
//           if (!isCacheExpired) {
//             return cachedTasks;
//           }
//         }
//       } catch (cacheError) {
//         debugPrint('Cache error: $cacheError');
//       }
//     }

//     // If no cache or force refresh, get from network
//     try {
//       final tasks = await getActiveTasks();
//       return tasks;
//     } catch (e) {
//       // Fallback to cache if network fails
//       try {
//         final cachedTasks = await _cacheService.getCachedTasks();
//         if (cachedTasks.isNotEmpty) {
//           return cachedTasks;
//         }
//       } catch (cacheError) {
//         debugPrint('Error getting cached tasks: $cacheError');
//       }
//       rethrow;
//     }
//   }
// // }

// import 'package:flutter/foundation.dart'; // Added for debugPrint
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/task_models.dart';
// import '../utils/task_helper.dart';

// class TaskService {
//   final _supabase = Supabase.instance.client;

//   /// Fetches all available tasks from the 'task_catalog' table.
//   Future<List<TaskModel>> getAvailableTasks() async {
//     try {
//       final response = await _supabase
//           .from('task_catalog')
//           .select()
//           .eq('is_active', true)
//           .order('sort_order', ascending: true); // Order by your new field

//       return (response as List).map((json) {
//         final String category = json['category'] ?? 'social';

//         // Handle platforms fallback logic
//         List<String> platforms = [];
//         if (json['platforms'] != null) {
//           platforms = List<String>.from(json['platforms']);
//         } else {
//           platforms = TaskHelper.getSupportedPlatforms(category);
//         }

//         return TaskModel(
//           id: json['id']?.toString() ?? '',
//           createdAt:
//               json['created_at'] != null
//                   ? DateTime.parse(json['created_at'].toString())
//                   : DateTime.now(),
//           category: category,
//           title: json['title'] ?? TaskHelper.getTaskTypeDisplayName(category),
//           price: (json['price'] ?? 0.0).toDouble(),
//           description: json['description'] ?? 'No description provided.',
//           platforms: platforms,
//           iconKey: json['icon_key'] ?? 'work',
//           isFeatured: json['is_featured'] ?? false,
//           isActive: json['is_active'] ?? true, // This now matches your Model
//           tags:
//               json['tags'] != null
//                   ? List<String>.from(json['tags'])
//                   : [category],
//           metadata: json['metadata'] ?? {},
//           difficulty: json['difficulty'],
//           estimatedTime: json['estimated_time'],
//           sortOrder: json['sort_order'] ?? 0,
//         );
//       }).toList();
//     } catch (e) {
//       debugPrint('Error in TaskService.getAvailableTasks: $e');
//       return [];
//     }
//   }

//   /// Fetches a specific task by its ID
//   Future<TaskModel?> getTaskById(String taskId) async {
//     try {
//       final response =
//           await _supabase
//               .from('task_catalog')
//               .select()
//               .eq('id', taskId)
//               .single();

//       final String category = response['category'] ?? 'social';

//       return TaskModel(
//         id: response['id'].toString(),
//         createdAt:
//             response['created_at'] != null
//                 ? DateTime.parse(response['created_at'].toString())
//                 : DateTime.now(),
//         category: category,
//         title: response['title'],
//         price: (response['price'] ?? 0.0).toDouble(),
//         description: response['description'],
//         platforms:
//             response['platforms'] != null
//                 ? List<String>.from(response['platforms'])
//                 : TaskHelper.getSupportedPlatforms(category),
//         iconKey: response['icon_key'] ?? 'work',
//         isFeatured: response['is_featured'] ?? false,
//         isActive: response['is_active'] ?? true,
//         tags: List<String>.from(response['tags'] ?? []),
//         metadata: response['metadata'] ?? {},
//         difficulty: response['difficulty'],
//         estimatedTime: response['estimated_time'],
//         sortOrder: response['sort_order'] ?? 0,
//       );
//     } catch (e) {
//       debugPrint('Error fetching task by ID: $e');
//       return null;
//     }
//   }

//   /// Get tasks filtered by category
//   Future<List<TaskModel>> getTasksByCategory(String category) async {
//     final allTasks = await getAvailableTasks();
//     return allTasks
//         .where((task) => task.category.toLowerCase() == category.toLowerCase())
//         .toList();
//   }
// }


import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_models.dart';
import '../utils/task_helper.dart';
import '../services/cache_service.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheService _cacheService = CacheService();

  /// Helper method to parse JSON into a TaskModel instance
  TaskModel _parseTask(Map<String, dynamic> json) {
    final String category = json['category'] ?? 'social';

    // Parse platforms array with fallback to TaskHelper
    List<String> platforms = [];
    if (json['platforms'] is List) {
      platforms = List<String>.from(json['platforms']);
    } else if (json['platforms'] is String) {
      platforms = [json['platforms']];
    } else {
      platforms = TaskHelper.getSupportedPlatforms(category);
    }

    // Parse tags array
    List<String> tags = [];
    if (json['tags'] is List) {
      tags = List<String>.from(json['tags']);
    } else {
      tags = [category];
    }

    // Parse metadata
    Map<String, dynamic> metadata = {};
    if (json['metadata'] is Map) {
      metadata = Map<String, dynamic>.from(json['metadata']);
    } else if (json['metadata'] is String) {
      try {
        metadata = jsonDecode(json['metadata']);
      } catch (_) {}
    }

    return TaskModel(
      id: json['id']?.toString() ?? '',
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : DateTime.now(),
      category: category,
      title: json['title'] ?? TaskHelper.getTaskTypeDisplayName(category),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? 'No description provided.',
      platforms: platforms,
      iconKey: json['icon_key'] ?? 'work',
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      tags: tags,
      metadata: metadata,
      difficulty: json['difficulty']?.toString(),
      estimatedTime: json['estimated_time'] as int?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  /// Fetches all active tasks with cache-aside strategy
  Future<List<TaskModel>> getAvailableTasks({bool forceRefresh = false}) async {
    // 1. Check Cache first if not forcing refresh
    if (!forceRefresh) {
      try {
        final cachedTasks = await _cacheService.getCachedTasks();
        final isStale = await _cacheService.isCacheExpired('tasks');
        if (cachedTasks.isNotEmpty && !isStale) {
          debugPrint('Returning tasks from cache');
          return cachedTasks;
        }
      } catch (e) {
        debugPrint('Cache read error: $e');
      }
    }

    // 2. Fetch from Network
    try {
      debugPrint('Fetching tasks from network...');
      final response = await _supabase
          .from('task_catalog')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final tasks = (response as List).map((json) => _parseTask(json)).toList();

      // 3. Update Cache
      await _cacheService.cacheTasks(tasks);
      return tasks;
    } catch (e) {
      debugPrint('Network error in getAvailableTasks: $e');

      // 4. Fallback to Cache on Network failure
      final fallback = await _cacheService.getCachedTasks();
      return fallback;
    }
  }

  /// Fetches tasks by category (Uses getAvailableTasks to leverage cache)
  Future<List<TaskModel>> getTasksByCategory(String category) async {
    final allTasks = await getAvailableTasks();
    return allTasks
        .where((task) => task.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Fetches featured tasks (Uses getAvailableTasks to leverage cache)
  Future<List<TaskModel>> getFeaturedTasks() async {
    final allTasks = await getAvailableTasks();
    return allTasks.where((task) => task.isFeatured).take(5).toList();
  }

  /// Fetches a specific task by its ID
  Future<TaskModel?> getTaskById(String taskId) async {
    try {
      // Try cache first
      final cached = await _cacheService.getCachedTasks();
      final foundInCache = cached.cast<TaskModel?>().firstWhere(
        (t) => t?.id == taskId,
        orElse: () => null,
      );

      if (foundInCache != null) return foundInCache;

      // Fetch from network if not in cache
      final response =
          await _supabase
              .from('task_catalog')
              .select()
              .eq('id', taskId)
              .single();

      return _parseTask(response);
    } catch (e) {
      debugPrint('Error in getTaskById: $e');
      return null;
    }
  }

  /// Search tasks locally within the cached/available tasks
  Future<List<TaskModel>> searchTasks(String query) async {
    if (query.isEmpty) return await getAvailableTasks();

    final allTasks = await getAvailableTasks();
    final lowercaseQuery = query.toLowerCase();

    return allTasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          task.description.toLowerCase().contains(lowercaseQuery) ||
          task.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
}
