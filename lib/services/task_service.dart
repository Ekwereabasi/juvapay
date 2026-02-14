import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_models.dart';
import '../utils/task_helper.dart';
import '../services/cache_service.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CacheService _cacheService = CacheService();

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text != 'null') {
        return text;
      }
    }
    return null;
  }

  Map<String, dynamic> _metadataMap(dynamic metadata) {
    if (metadata is Map<String, dynamic>) return metadata;
    if (metadata is Map) {
      return metadata.map((key, value) => MapEntry(key.toString(), value));
    }
    if (metadata is String && metadata.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(metadata);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {}
    }
    return {};
  }

  String? _firstUrlFromList(dynamic value) {
    if (value is List) {
      for (final entry in value) {
        final extracted = _extractUrl(entry);
        if (extracted != null) return extracted;
      }
    }
    return null;
  }

  String? _extractUrl(dynamic value) {
    if (value == null) return null;

    final asText = value.toString().trim();
    if (asText.isNotEmpty && asText.startsWith('http')) {
      return asText;
    }

    if (value is Map) {
      for (final key in [
        'url',
        'image_url',
        'media_url',
        'src',
        'file_url',
        'public_url',
        'path',
      ]) {
        final candidate = value[key]?.toString().trim();
        if (candidate != null &&
            candidate.isNotEmpty &&
            candidate.startsWith('http')) {
          return candidate;
        }
      }
    }

    return null;
  }

  String? _imageFromMetadata(Map<String, dynamic> metadata) {
    return _firstNonEmptyString([
      metadata['ad_image_url'],
      metadata['image_url'],
      metadata['target_image_url'],
      metadata['media_url'],
      _extractUrl(metadata['media']),
      _extractUrl(metadata['asset']),
      _firstUrlFromList(metadata['media_urls']),
      _firstUrlFromList(metadata['images']),
      _firstUrlFromList(metadata['assets']),
      _firstUrlFromList(metadata['attachments']),
      _firstUrlFromList(metadata['files']),
      _firstUrlFromList(metadata['gallery']),
    ]);
  }

  /// Helper method to parse JSON into a TaskModel instance
  TaskModel _parseTask(Map<String, dynamic> json) {
    final String category = json['category'] ?? 'social';

    // Parse platforms array
    List<String> platforms = [];
    if (json['platforms'] is List) {
      platforms = List<String>.from(json['platforms']);
    } else if (json['platforms'] is String) {
      try {
        platforms = List<String>.from(jsonDecode(json['platforms']));
      } catch (_) {
        platforms = [json['platforms']];
      }
    }

    // Parse tags array
    List<String> tags = [];
    if (json['tags'] is List) {
      tags = List<String>.from(json['tags']);
    }

    // Parse metadata
    Map<String, dynamic> metadata = {};
    if (json['metadata'] is Map) {
      metadata = Map<String, dynamic>.from(json['metadata']);
    } else if (json['metadata'] is String) {
      try {
        metadata = jsonDecode(json['metadata']);
      } catch (_) {
        metadata = {};
      }
    }

    // Parse requirements and instructions
    List<dynamic> requirements = [];
    if (json['requirements'] is List) {
      requirements = List<dynamic>.from(json['requirements']);
    } else if (json['requirements'] is String) {
      try {
        requirements = jsonDecode(json['requirements']);
      } catch (_) {
        requirements = [];
      }
    }

    List<dynamic> instructions = [];
    if (json['instructions'] is List) {
      instructions = List<dynamic>.from(json['instructions']);
    } else if (json['instructions'] is String) {
      try {
        instructions = jsonDecode(json['instructions']);
      } catch (_) {
        instructions = [];
      }
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
      platforms:
          platforms.isNotEmpty
              ? platforms
              : TaskHelper.getSupportedPlatforms(category),
      iconKey: json['icon_key'] ?? 'work',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      estimatedTime: json['estimated_time'] as int?,
      status: json['status']?.toString() ?? 'active',
      sortOrder: json['sort_order'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      tags: tags.isNotEmpty ? tags : [category],
      metadata: metadata,
      version: json['version'] as int? ?? 1,
      minQuantity: json['min_quantity'] as int? ?? 1,
      maxQuantity: json['max_quantity'] as int? ?? 10000,
      requirements: requirements,
      instructions: instructions,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.20,
      workerPayoutRate:
          (json['worker_payout_rate'] as num?)?.toDouble() ?? 0.80,
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
          .eq('status', 'active') // Changed from is_active to status
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

  /// Fetches tasks by category
  Future<List<TaskModel>> getTasksByCategory(String category) async {
    final allTasks = await getAvailableTasks();
    return allTasks
        .where((task) => task.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Fetches featured tasks
  Future<List<TaskModel>> getFeaturedTasks() async {
    final allTasks = await getAvailableTasks();
    return allTasks
        .where((task) => task.isFeatured && task.isActive)
        .take(5)
        .toList();
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
          task.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
          task.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Create an advertiser order (for advertisers) - UPDATED VERSION
  Future<Map<String, dynamic>> createAdvertiserOrder({
    required String taskId,
    required String platform,
    required int quantity,
    String? adContent,
    String? adImageUrl,
    String? targetLink,
    String? targetUsername,
    Map<String, dynamic> metadata = const {},
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    Map<String, dynamic>? location,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not authenticated. Please log in.',
          'error_code': 'AUTH_REQUIRED',
        };
      }

      // Debug: Check wallet balance first
      try {
        final walletDebug = await _supabase.rpc(
          'debug_wallet_balance',
          params: {
            'p_user_id': user.id,
            'p_required_amount': 0.0, // Just to check wallet exists
          },
        );
        debugPrint('Wallet debug result: $walletDebug');
      } catch (e) {
        debugPrint('Wallet debug error: $e');
      }

      // Get task price first to calculate total
      final taskResponse =
          await _supabase
              .from('task_catalog')
              .select('price, title, worker_payout_rate')
              .eq('id', taskId)
              .eq('status', 'active')
              .single();

      final taskPrice = (taskResponse['price'] as num).toDouble();
      final totalAmount = taskPrice * quantity;

      debugPrint(
        'Task Price: $taskPrice, Quantity: $quantity, Total: $totalAmount',
      );
      debugPrint('User ID: ${user.id}');

      // Call the create_advertiser_order function
      final response = await _supabase
          .rpc(
            'create_advertiser_order',
            params: {
              'p_advertiser_id': user.id,
              'p_task_id': taskId,
              'p_platform': platform,
              'p_quantity': quantity,
              'p_ad_content': adContent,
              'p_ad_image_url': adImageUrl,
              'p_target_link': targetLink,
              'p_target_username': targetUsername,
              'p_metadata': metadata,
              if (ipAddress != null) 'p_ip_address': ipAddress,
              if (userAgent != null) 'p_user_agent': userAgent,
              if (deviceId != null) 'p_device_id': deviceId,
              if (location != null) 'p_location': location,
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('create_advertiser_order response: $response');

      if (response == null) {
        return {
          'success': false,
          'message': 'Failed to create order. No response from server.',
          'error_code': 'NO_RESPONSE',
        };
      }

      dynamic normalizedResponse = response;
      if (response is String) {
        try {
          normalizedResponse = jsonDecode(response);
        } catch (_) {
          return {
            'success': false,
            'message': 'Failed to create order. Invalid response format.',
            'error_code': 'INVALID_RESPONSE',
          };
        }
      }

      if (normalizedResponse is List) {
        if (response.isEmpty) {
          return {
            'success': false,
            'message': 'Failed to create order. Empty response from server.',
            'error_code': 'EMPTY_RESPONSE',
          };
        }
        normalizedResponse = normalizedResponse.first;
      }

      if (normalizedResponse is! Map) {
        return {
          'success': false,
          'message': 'Failed to create order. Invalid response format.',
          'error_code': 'INVALID_RESPONSE',
        };
      }

      // Check if the response indicates success
      final success = normalizedResponse['success'] ?? false;
      final message =
          normalizedResponse['message']?.toString() ?? 'Unknown response';

      if (success) {
        return {
          'success': true,
          'order_id': normalizedResponse['order_id']?.toString(),
          'message': message,
          'total_amount':
              (normalizedResponse['total_amount'] as num?)?.toDouble() ??
              totalAmount,
          'reference_id': normalizedResponse['reference_id']?.toString(),
          'raw_response': normalizedResponse,
        };
      } else {
        return {
          'success': false,
          'message': message,
          'error_code': 'ORDER_CREATION_FAILED',
          'raw_response': normalizedResponse,
        };
      }
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException in createAdvertiserOrder: $e');
      debugPrint('Details: ${e.details}, Hint: ${e.hint}, Code: ${e.code}');

      return {
        'success': false,
        'message': _parsePostgrestError(e),
        'error_code': 'DATABASE_ERROR',
        'database_error': {
          'message': e.message,
          'details': e.details,
          'hint': e.hint,
          'code': e.code,
        },
      };
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException in createAdvertiserOrder: $e');
      return {
        'success': false,
        'message':
            'Request timed out. Please check your connection and try again.',
        'error_code': 'TIMEOUT',
      };
    } catch (e, stackTrace) {
      debugPrint('Unexpected error in createAdvertiserOrder: $e');
      debugPrint('Stack trace: $stackTrace');

      return {
        'success': false,
        'message': 'Failed to create order: ${_getDetailedErrorMessage(e)}',
        'error_code': 'UNKNOWN_ERROR',
        'error_details': e.toString(),
      };
    }
  }

  /// Helper method to parse Postgrest errors
  String _parsePostgrestError(PostgrestException e) {
    // Check for specific error codes
    if (e.code == '42501') {
      return 'Permission denied. Please ensure you have the correct permissions.';
    } else if (e.code == '23505') {
      return 'Duplicate order detected. Please try again.';
    } else if (e.code == '23503') {
      return 'Invalid task or user. Please check your details.';
    } else if (e.code == 'P0001') {
      // Custom exception from PostgreSQL
      return e.message;
    }

    // Return detailed message
    return 'Database error: ${e.message}';
  }

  /// Get detailed error message
  String _getDetailedErrorMessage(dynamic error) {
    if (error is String) return error;

    try {
      if (error is Map<String, dynamic>) {
        if (error.containsKey('message')) return error['message'].toString();
        if (error.containsKey('error')) return error['error'].toString();
      }

      final errorString = error.toString();
      if (errorString.contains('Insufficient balance')) {
        return 'Insufficient wallet balance. Please fund your wallet.';
      } else if (errorString.contains('wallet locked')) {
        return 'Your wallet is locked. Please contact support.';
      } else if (errorString.contains('Task not found')) {
        return 'The selected task is no longer available.';
      } else if (errorString.contains('payment')) {
        return 'Payment processing failed. Please try again.';
      }

      return errorString;
    } catch (_) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Helper method for error messages
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      return error.message;
    }
    if (error is PostgrestException) {
      // Use the instance method through a static context - create a helper
      final taskService = TaskService();
      return taskService._parsePostgrestError(error);
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Get available tasks for workers
  Future<List<Map<String, dynamic>>> getAvailableTasksForWorker({
    String? platform,
    int limit = 20,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _supabase.rpc(
        'get_available_tasks_for_worker',
        params: {
          'p_worker_id': user.id,
          'p_platform': platform,
          'p_limit': limit,
        },
      );

      final tasks = List<Map<String, dynamic>>.from(response ?? []);
      return tasks.map((task) {
        final metadata = _metadataMap(task['metadata']);
        final caption = _firstNonEmptyString([
          task['ad_content'],
          task['caption'],
          task['ad_caption'],
          metadata['ad_content'],
          metadata['caption'],
        ]);
        final imageUrl = _firstNonEmptyString([
          task['ad_image_url'],
          task['ad_image'],
          task['image_url'],
          task['target_image_url'],
          _imageFromMetadata(metadata),
        ]);

        return {
          ...task,
          if (caption != null) 'ad_content': caption,
          if (imageUrl != null) 'ad_image_url': imageUrl,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting available tasks for worker: $e');
      return [];
    }
  }

  /// Get the latest queue/assignment task details for execution.
  Future<Map<String, dynamic>?> getTaskExecutionDetails({
    String? assignmentId,
    String? queueId,
    Map<String, dynamic> fallbackTaskData = const {},
  }) async {
    try {
      if ((assignmentId == null || assignmentId.isEmpty) &&
          (queueId == null || queueId.isEmpty)) {
        return null;
      }

      Map<String, dynamic>? queueData;
      Map<String, dynamic>? catalogData;
      Map<String, dynamic>? orderData;
      Map<String, dynamic>? assignmentData;
      String? proofUsername;

      if (assignmentId != null && assignmentId.isNotEmpty) {
        // Primary path for current schema: task_assignments -> advertiser_orders -> task_catalog.
        try {
          final assignmentResponse =
              await _supabase
                  .from('task_assignments')
                  .select('''
                    id,
                    order_id,
                    worker_payout,
                    assigned_at,
                    completed_at,
                    proof_platform_username,
                    status,
                    advertiser_orders:order_id (
                      id,
                      platform,
                      ad_content,
                      ad_image_url,
                      target_link,
                      target_username,
                      metadata,
                      task_catalog:task_id (
                        title,
                        description,
                        instructions,
                        requirements,
                        estimated_time
                      )
                    )
                  ''')
                  .eq('id', assignmentId)
                  .maybeSingle();

          if (assignmentResponse != null) {
            assignmentData = assignmentResponse;
            orderData =
                assignmentResponse['advertiser_orders']
                    as Map<String, dynamic>?;
            catalogData = orderData?['task_catalog'] as Map<String, dynamic>?;
            proofUsername =
                assignmentResponse['proof_platform_username']?.toString();
          }
        } catch (_) {
          // Backward compatibility path for older schema.
          final assignmentResponse =
              await _supabase
                  .from('task_assignments')
                  .select('''
                    id,
                    queue_id,
                    proof_platform_username,
                    task_queue:queue_id (
                      *,
                      task_catalog:task_catalog_id (*)
                    )
                  ''')
                  .eq('id', assignmentId)
                  .maybeSingle();

          if (assignmentResponse != null) {
            assignmentData = assignmentResponse;
            queueData =
                assignmentResponse['task_queue'] as Map<String, dynamic>?;
            catalogData = queueData?['task_catalog'] as Map<String, dynamic>?;
            proofUsername =
                assignmentResponse['proof_platform_username']?.toString();
          }
        }
      }

      if (queueId != null && queueId.isNotEmpty) {
        final queueResponse =
            await _supabase
                .from('task_queue')
                .select('*')
                .eq('id', queueId)
                .maybeSingle();

        if (queueResponse != null) {
          queueData = queueResponse;
          final queueOrderId = _firstNonEmptyString([
            queueData['order_id'],
            orderData?['id'],
            assignmentData?['order_id'],
          ]);
          if (queueOrderId != null && queueOrderId.isNotEmpty) {
            final orderResponse =
                await _supabase
                    .from('advertiser_orders')
                    .select('''
                      *,
                      task_catalog:task_id (
                        title,
                        description,
                        instructions,
                        requirements,
                        estimated_time
                      )
                    ''')
                    .eq('id', queueOrderId)
                    .maybeSingle();
            if (orderResponse != null) {
              orderData = orderResponse;
              catalogData = orderData?['task_catalog'] as Map<String, dynamic>?;
            }
          }
        }
      }

      // If queue id wasn't passed, try lookup via assignment.
      if (queueData == null &&
          assignmentId != null &&
          assignmentId.isNotEmpty) {
        final queueFromAssignment =
            await _supabase
                .from('task_queue')
                .select('*')
                .eq('assignment_id', assignmentId)
                .order('created_at', ascending: false)
                .maybeSingle();
        if (queueFromAssignment != null) {
          queueData = queueFromAssignment;
        }
      }

      // If assignment exists but order wasn't loaded, load order now.
      if (assignmentData != null && orderData == null) {
        final assignmentOrderId = assignmentData['order_id']?.toString().trim();
        if (assignmentOrderId != null && assignmentOrderId.isNotEmpty) {
          final orderResponse =
              await _supabase
                  .from('advertiser_orders')
                  .select('''
                    *,
                    task_catalog:task_id (
                      title,
                      description,
                      instructions,
                      requirements,
                      estimated_time
                    )
                  ''')
                  .eq('id', assignmentOrderId)
                  .maybeSingle();
          if (orderResponse != null) {
            orderData = orderResponse;
            catalogData = orderData?['task_catalog'] as Map<String, dynamic>?;
          }
        }
      }

      if (queueData == null &&
          catalogData == null &&
          orderData == null &&
          assignmentData == null) {
        return null;
      }

      final queueMetadata = _metadataMap(queueData?['metadata']);
      final catalogMetadata = _metadataMap(catalogData?['metadata']);
      final orderMetadata = _metadataMap(orderData?['metadata']);
      final fallbackMetadata = _metadataMap(fallbackTaskData['metadata']);
      final orderId = _firstNonEmptyString([
        assignmentData?['order_id'],
        orderData?['id'],
        queueData?['order_id'],
        fallbackTaskData['order_id'],
      ]);
      String? orderImageUrl;

      if (orderId != null && orderId.isNotEmpty) {
        try {
          final orderResponse =
              await _supabase
                  .from('advertiser_orders')
                  .select('ad_image_url, metadata')
                  .eq('id', orderId)
                  .maybeSingle();
          if (orderResponse != null) {
            final dbOrderMetadata = _metadataMap(orderResponse['metadata']);
            orderImageUrl = _firstNonEmptyString([
              orderResponse['ad_image_url'],
              _imageFromMetadata(dbOrderMetadata),
            ]);
          }
        } catch (_) {
          // Non-blocking fallback.
        }

        // Legacy fallback for environments still using "orders".
        if (orderImageUrl == null) {
          try {
            final orderResponse =
                await _supabase
                    .from('orders')
                    .select('media_url, media_urls')
                    .eq('id', orderId)
                    .maybeSingle();
            if (orderResponse != null) {
              orderImageUrl = _firstNonEmptyString([
                orderResponse['media_url'],
                _firstUrlFromList(orderResponse['media_urls']),
              ]);
            }
          } catch (_) {}
        }
      }

      final caption = _firstNonEmptyString([
        orderData?['ad_content'],
        queueData?['ad_content'],
        queueData?['caption'],
        queueData?['ad_caption'],
        queueMetadata['ad_content'],
        queueMetadata['caption'],
        orderMetadata['ad_content'],
        orderMetadata['caption'],
        catalogData?['caption'],
        catalogMetadata['caption'],
        fallbackTaskData['ad_content'],
        fallbackTaskData['caption'],
      ]);
      final imageUrl = _firstNonEmptyString([
        orderData?['ad_image_url'],
        queueData?['ad_image_url'],
        queueData?['ad_image'],
        queueData?['image_url'],
        queueData?['target_image_url'],
        _imageFromMetadata(queueMetadata),
        _imageFromMetadata(orderMetadata),
        catalogData?['ad_image_url'],
        catalogData?['image_url'],
        _imageFromMetadata(catalogMetadata),
        fallbackTaskData['ad_image_url'],
        fallbackTaskData['image_url'],
        _imageFromMetadata(fallbackMetadata),
        orderImageUrl,
      ]);
      final targetLink = _firstNonEmptyString([
        orderData?['target_link'],
        queueData?['target_link'],
        queueData?['link'],
        queueData?['url'],
        queueMetadata['target_link'],
        queueMetadata['link'],
        queueMetadata['url'],
        orderMetadata['target_link'],
        orderMetadata['link'],
        orderMetadata['url'],
        catalogData?['target_link'],
        fallbackTaskData['target_link'],
      ]);

      return {
        'queue_id': queueData?['id']?.toString() ?? queueId,
        'assignment_id':
            assignmentId ??
            assignmentData?['id']?.toString() ??
            fallbackTaskData['assignment_id'],
        'order_id': orderId,
        'platform':
            queueData?['platform']?.toString() ??
            orderData?['platform']?.toString() ??
            fallbackTaskData['platform'],
        'task_title':
            catalogData?['title']?.toString() ??
            queueData?['task_title']?.toString() ??
            fallbackTaskData['task_title'],
        'task_description':
            catalogData?['description']?.toString() ??
            queueData?['task_description']?.toString() ??
            fallbackTaskData['task_description'],
        'payout_amount':
            (queueData?['payout_amount'] as num?)?.toDouble() ??
            (assignmentData?['worker_payout'] as num?)?.toDouble() ??
            fallbackTaskData['payout_amount'],
        'target_username':
            orderData?['target_username']?.toString() ??
            queueData?['target_username']?.toString() ??
            fallbackTaskData['target_username'],
        'target_link': targetLink,
        'ad_content': caption,
        'ad_image_url': imageUrl,
        'metadata':
            queueData?['metadata'] ??
            orderData?['metadata'] ??
            fallbackTaskData['metadata'],
        'instructions':
            queueData?['instructions'] ??
            catalogData?['instructions'] ??
            fallbackTaskData['instructions'],
        'requirements':
            queueData?['requirements'] ??
            catalogData?['requirements'] ??
            fallbackTaskData['requirements'],
        'expires_at':
            queueData?['expires_at']?.toString() ??
            fallbackTaskData['expires_at'],
        'estimated_time':
            catalogData?['estimated_time'] as int? ??
            fallbackTaskData['estimated_time'],
        'proof_platform_username':
            proofUsername ?? fallbackTaskData['proof_platform_username'],
      };
    } catch (e) {
      debugPrint('Error getting task execution details: $e');
      return null;
    }
  }

  /// Claim a task (for workers)
  Future<Map<String, dynamic>> claimTask(String queueId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final response = await _supabase.rpc(
        'claim_task',
        params: {'p_worker_id': user.id, 'p_queue_id': queueId},
      );

      dynamic normalizedResponse = response;
      if (normalizedResponse is String) {
        try {
          normalizedResponse = jsonDecode(normalizedResponse);
        } catch (_) {
          return {
            'success': false,
            'message': 'Failed to claim task. Invalid response format.',
          };
        }
      }

      if (normalizedResponse is List) {
        if (normalizedResponse.isEmpty) {
          return {
            'success': false,
            'message': 'Failed to claim task. Empty response from server.',
          };
        }
        normalizedResponse = normalizedResponse.first;
      }

      if (normalizedResponse is! Map) {
        return {
          'success': false,
          'message': 'Failed to claim task. Invalid response format.',
        };
      }

      if (normalizedResponse['success'] == false) {
        return {
          'success': false,
          'message':
              normalizedResponse['message']?.toString() ??
              'Failed to claim task.',
        };
      }

      return {
        'success': true,
        'assignment_id': normalizedResponse['assignment_id'],
        'message': normalizedResponse['message']?.toString(),
      };
    } catch (e) {
      debugPrint('Error claiming task: $e');
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  /// Submit task proof (for workers)
  /// TaskService - Update the submitTaskProof method
  Future<Map<String, dynamic>> submitTaskProof({
    required String assignmentId,
    required String platformUsername,
    required File proofImage,
    String? proofDescription,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }
      if (assignmentId.trim().isEmpty) {
        return {'success': false, 'message': 'Invalid task assignment'};
      }

      // Upload image to storage first
      final fileName =
          '${assignmentId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'task_proofs/${user.id}/$fileName';

      await _supabase.storage
          .from('task_proofs')
          .upload(
            storagePath,
            proofImage,
            fileOptions: const FileOptions(upsert: true),
          )
          .timeout(const Duration(seconds: 30));

      final proofImageUrl = _supabase.storage
          .from('task_proofs')
          .getPublicUrl(storagePath);

      // Now call the RPC function
      final response = await _supabase
          .rpc(
            'submit_task_proof',
            params: {
              'p_assignment_id': assignmentId,
              'p_proof_screenshot_url': proofImageUrl,
              'p_proof_platform_username': platformUsername,
              'p_proof_description': proofDescription,
            },
          )
          .timeout(const Duration(seconds: 30));

      dynamic normalizedResponse = response;
      if (normalizedResponse is String) {
        try {
          normalizedResponse = jsonDecode(normalizedResponse);
        } catch (_) {}
      }

      if (normalizedResponse is List) {
        if (normalizedResponse.isEmpty) {
          return {
            'success': false,
            'message': 'Submission failed. Empty response from server.',
          };
        }
        normalizedResponse = normalizedResponse.first;
      }

      if (normalizedResponse is Map) {
        final successFlag = normalizedResponse['success'];
        if (successFlag == false) {
          return {
            'success': false,
            'message':
                normalizedResponse['message']?.toString() ??
                normalizedResponse['error']?.toString() ??
                'Submission failed. Please try again.',
            'raw_response': normalizedResponse,
          };
        }

        return {
          'success': true,
          'message':
              normalizedResponse['message']?.toString() ??
              'Proof submitted successfully',
          'raw_response': normalizedResponse,
        };
      }

      return {
        'success': true,
        'message':
            normalizedResponse?.toString().isNotEmpty == true
                ? normalizedResponse.toString()
                : 'Proof submitted successfully',
      };
    } on PostgrestException catch (e) {
      debugPrint('Postgrest error submitting task proof: $e');
      return {
        'success': false,
        'message': _parsePostgrestError(e),
        'error_code': e.code,
        'error_details': e.details,
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Please check your connection and retry.',
      };
    } catch (e) {
      debugPrint('Error submitting task proof: $e');
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  /// Get worker statistics
  Future<Map<String, dynamic>> getWorkerStatistics() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final response = await _supabase.rpc(
        'get_worker_statistics',
        params: {'p_worker_id': user.id},
      );

      return {'success': true, 'data': response};
    } catch (e) {
      debugPrint('Error getting worker statistics: $e');
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  /// Get worker task history
  Future<List<Map<String, dynamic>>> getWorkerTaskHistory({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _supabase.rpc(
        'get_worker_task_history',
        params: {
          'p_worker_id': user.id,
          'p_status': status,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Error getting worker task history: $e');
      return [];
    }
  }

  /// Get advertiser order analytics
  Future<Map<String, dynamic>> getAdvertiserOrderAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      final response = await _supabase.rpc(
        'get_advertiser_order_analytics',
        params: {
          'p_advertiser_id': user.id,
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
        },
      );

      return {'success': true, 'data': response};
    } catch (e) {
      debugPrint('Error getting advertiser analytics: $e');
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  /// Upload image to storage
  Future<String?> uploadImage(File imageFile, String path) async {
    try {
      await _supabase.storage
          .from('task_proofs')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      return _supabase.storage.from('task_proofs').getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Upload order media files to `order-media` bucket and set first file as ad image.
  Future<Map<String, dynamic>> uploadOrderMediaFiles({
    required String orderId,
    required List<File> mediaFiles,
  }) async {
    try {
      if (orderId.trim().isEmpty) {
        return {'success': false, 'message': 'Invalid order ID'};
      }
      if (mediaFiles.isEmpty) {
        return {'success': false, 'message': 'No media files selected'};
      }

      final List<String> uploadedUrls = [];
      final bucket = _supabase.storage.from('order-media');

      for (final file in mediaFiles) {
        final originalName = file.path.split('/').last.split('\\').last;
        final sanitizedName = originalName.replaceAll(
          RegExp(r'[^A-Za-z0-9._-]'),
          '_',
        );
        final storagePath =
            '$orderId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

        await bucket.upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: false),
        );
        uploadedUrls.add(bucket.getPublicUrl(storagePath));
      }

      if (uploadedUrls.isNotEmpty) {
        await _supabase
            .from('advertiser_orders')
            .update({'ad_image_url': uploadedUrls.first})
            .eq('id', orderId);
      }

      return {
        'success': true,
        'message': 'Media uploaded successfully',
        'media_urls': uploadedUrls,
        'ad_image_url': uploadedUrls.isNotEmpty ? uploadedUrls.first : null,
      };
    } catch (e) {
      debugPrint('Error uploading order media: $e');
      return {
        'success': false,
        'message': 'Failed to upload media: ${e.toString()}',
      };
    }
  }

  /// Helper method to format transaction type for display
  static String formatTransactionType(String type) {
    switch (type) {
      case 'DEPOSIT':
        return 'Deposit';
      case 'WITHDRAWAL':
        return 'Withdrawal';
      case 'TASK_EARNING':
        return 'Task Earnings';
      case 'ORDER_PAYMENT':
        return 'Order Payment';
      case 'ADVERT_FEE':
        return 'Advert Fee';
      case 'MEMBERSHIP_PAYMENT':
        return 'Membership';
      case 'REFUND':
        return 'Refund';
      case 'TRANSFER_IN':
        return 'Transfer Received';
      case 'TRANSFER_OUT':
        return 'Transfer Sent';
      case 'CHARGEBACK':
        return 'Chargeback';
      case 'FEE':
        return 'Service Fee';
      case 'BONUS':
        return 'Bonus';
      case 'CORRECTION':
        return 'Balance Correction';
      default:
        return type.replaceAll('_', ' ');
    }
  }
}
