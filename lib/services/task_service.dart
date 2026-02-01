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

      // Check if the response indicates success
      final success = response['success'] ?? false;
      final message = response['message']?.toString() ?? 'Unknown response';

      if (success) {
        return {
          'success': true,
          'order_id': response['order_id']?.toString(),
          'message': message,
          'total_amount':
              (response['total_amount'] as num?)?.toDouble() ?? totalAmount,
          'reference_id': response['reference_id']?.toString(),
          'raw_response': response,
        };
      } else {
        return {
          'success': false,
          'message': message,
          'error_code': 'ORDER_CREATION_FAILED',
          'raw_response': response,
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

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Error getting available tasks for worker: $e');
      return [];
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

      return {
        'success': true,
        'assignment_id': response['assignment_id'],
        'message': response['message'],
      };
    } catch (e) {
      debugPrint('Error claiming task: $e');
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  /// Submit task proof (for workers)
  Future<Map<String, dynamic>> submitTaskProof({
    required String assignmentId,
    required String proofScreenshotUrl,
    required String proofPlatformUsername,
    String? proofDescription,
  }) async {
    try {
      final response = await _supabase.rpc(
        'submit_task_proof',
        params: {
          'p_assignment_id': assignmentId,
          'p_proof_screenshot_url': proofScreenshotUrl,
          'p_proof_platform_username': proofPlatformUsername,
          'p_proof_description': proofDescription,
        },
      );

      return {'success': true, 'message': response['message']};
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
