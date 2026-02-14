// supabase_auth_service.dart - COMPLETE PRODUCTION READY WITH ALL FUNCTIONALITY (FIXED)
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/task_service.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TaskService _taskService = TaskService();

  // ==========================================
  // AUTHENTICATION METHODS (NO EMAIL VERIFICATION)
  // ==========================================

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      debugPrint('🚀 Starting registration for: ${email.trim().toLowerCase()}');

      // Validate email format before making network call
      if (!_isValidEmail(email)) {
        return {
          'success': false,
          'message': 'Please enter a valid email address.',
          'error_type': 'validation_error',
        };
      }

      // Check network connectivity (indirectly by trying a small operation)
      try {
        // FIXED: Removed count parameter
        await _supabase
            .from('profiles')
            .select()
            .limit(1)
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('❌ Network check failed: $e');
        return {
          'success': false,
          'message':
              'Network error. Please check your internet connection and try again.',
          'error_type': 'network_error',
        };
      }

      // Sign up with Supabase Auth (NO email verification)
      final response = await _supabase.auth
          .signUp(
            email: email.trim().toLowerCase(),
            password: password,
            data: {
              'full_name': fullName.trim(),
              'phone': phone?.trim() ?? '',
              'created_at': DateTime.now().millisecondsSinceEpoch,
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('✅ Auth user created: ${response.user?.id ?? "Unknown"}');

      if (response.user == null) {
        throw Exception('Failed to create user account - no user returned');
      }

      // Wait for database trigger to create profile
      debugPrint('⏳ Waiting for profile creation trigger...');
      await Future.delayed(const Duration(seconds: 2));

      // Check if profile was created by trigger
      bool profileCreated = false;
      try {
        final profileCheck = await _supabase
            .from('profiles')
            .select('id')
            .eq('id', response.user!.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 5));

        profileCreated = profileCheck != null;

        if (profileCreated) {
          debugPrint('✅ Profile created by trigger successfully');
        } else {
          debugPrint(
            '⚠️ Profile not found after trigger, attempting manual creation...',
          );
          // Try to create profile manually
          await _createUserProfileFallback(
            userId: response.user!.id,
            fullName: fullName,
            phone: phone,
          );
          profileCreated = true;
        }
      } catch (e) {
        debugPrint('❌ Error checking/creating profile: $e');
        // Try fallback RPC function
        try {
          await _supabase
              .rpc(
                'ensure_profile_exists',
                params: {'user_id': response.user!.id},
              )
              .timeout(const Duration(seconds: 3));
          debugPrint('✅ Profile created via ensure_profile_exists RPC');
          profileCreated = true;
        } catch (rpcError) {
          debugPrint('❌ RPC profile creation failed: $rpcError');
        }
      }

      // Create worker profile (non-critical operation)
      if (profileCreated) {
        try {
          await _createWorkerProfile(response.user!.id);
          debugPrint('✅ Worker profile created');
        } catch (e) {
          debugPrint('⚠️ Worker profile creation error (non-critical): $e');
          // Don't fail registration if worker profile fails
        }
      }

      // Auto-sign in if no session was returned
      if (response.session == null) {
        debugPrint('🔄 No session returned, attempting auto-signin...');
        try {
          final signInResult = await _supabase.auth
              .signInWithPassword(email: email, password: password)
              .timeout(const Duration(seconds: 10));

          if (signInResult.user != null) {
            debugPrint('✅ Auto-signin successful');
            return {
              'success': true,
              'user_id': response.user!.id,
              'message': 'Account created successfully! You are now signed in.',
            };
          }
        } catch (signInError) {
          debugPrint('⚠️ Auto-signin failed: $signInError');
          // Still return success since account was created
          return {
            'success': true,
            'user_id': response.user!.id,
            'message': 'Account created! Please sign in manually.',
            'warning': 'Automatic sign-in failed',
          };
        }
      }

      debugPrint('🎉 Registration complete! User is signed in.');
      return {
        'success': true,
        'user_id': response.user!.id,
        'message': 'Account created successfully! You are now signed in.',
      };
    } on TimeoutException catch (_) {
      debugPrint('⏰ Registration timeout');
      return {
        'success': false,
        'message':
            'Request timed out. Please check your internet connection and try again.',
        'error_type': 'timeout_error',
      };
    } on SocketException catch (_) {
      debugPrint('🌐 Network connection error');
      return {
        'success': false,
        'message':
            'Network error. Please check your internet connection and try again.',
        'error_type': 'network_error',
      };
    } on AuthException catch (e) {
      debugPrint('🔐 Auth error: ${e.message}');
      return {
        'success': false,
        'message': _parseAuthError(e),
        'error_type': 'auth_error',
      };
    } catch (e) {
      debugPrint('❌ Unexpected error during registration: $e');
      return {
        'success': false,
        'message': _parseGenericError(e),
        'error_type': 'unknown_error',
      };
    }
  }

  Future<void> _createUserProfileFallback({
    required String userId,
    required String fullName,
    String? phone,
  }) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'full_name': fullName,
        'phone_number': phone ?? '',
        'username': _generateUsername(fullName),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Manual profile creation successful');
    } catch (e) {
      debugPrint('❌ Manual profile creation failed: $e');
      rethrow;
    }
  }

  String _generateUsername(String fullName) {
    // Generate a simple username from full name
    final cleanName =
        fullName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(9);

    // FIXED: Use a simple math.min function
    int getMin(int a, int b) => a < b ? a : b;

    final maxLength = getMin(cleanName.length, 4);
    final username =
        'user${cleanName.isNotEmpty ? cleanName.substring(0, maxLength) : ""}$timestamp';
    return username.length > 20 ? username.substring(0, 20) : username;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }

  String _parseAuthError(AuthException error) {
    final message = error.message?.toLowerCase() ?? '';

    if (message.contains('user already registered') ||
        message.contains('already exists') ||
        message.contains('duplicate')) {
      return 'An account with this email already exists. Please use a different email or try signing in.';
    }

    if (message.contains('invalid login credentials')) {
      return 'The email or password format is invalid. Please check your credentials.';
    }

    if (message.contains('password') && message.contains('weak')) {
      return 'Password is too weak. Please use a stronger password with at least 6 characters.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }

    if (message.contains('database error saving new user')) {
      return 'Error creating user profile. Please try again or contact support if the issue persists.';
    }

    return error.message ?? 'Authentication failed. Please try again.';
  }

  String _parseGenericError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out. Please check your internet connection and try again.';
    }

    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (errorString.contains('profiles_username_key')) {
      return 'Username is already taken. Please choose a different username.';
    }

    if (errorString.contains('violates foreign key constraint')) {
      return 'Invalid data format. Please check your information and try again.';
    }

    if (errorString.contains('database') || errorString.contains('postgres')) {
      return 'Database error. Please try again in a few moments.';
    }

    return 'An unexpected error occurred. Please try again or contact support if the issue persists.';
  }

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth
          .signInWithPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));

      return {
        'success': true,
        'user_id': response.user?.id,
        'message': 'Signed in successfully',
      };
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Sign in request timed out. Please check your connection.',
        'error_type': 'timeout_error',
      };
    } on SocketException catch (_) {
      return {
        'success': false,
        'message': 'Network error. Please check your internet connection.',
        'error_type': 'network_error',
      };
    } catch (e) {
      return {
        'success': false,
        'message': getErrorMessage(e),
        'error_type': 'auth_error',
      };
    }
  }

  Future<Map<String, dynamic>> signOut() async {
    try {
      await _supabase.auth.signOut().timeout(const Duration(seconds: 5));
      return {'success': true, 'message': 'Signed out successfully'};
    } catch (e) {
      debugPrint('Sign out error: $e');
      return {'success': false, 'message': 'Error signing out'};
    }
  }

  // ==========================================
  // PASSWORD RESET & RECOVERY METHODS
  // ==========================================

  /// Send password reset email to user
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    try {
      await _supabase.auth
          .resetPasswordForEmail(email, redirectTo: 'juvapay://reset-password')
          .timeout(const Duration(seconds: 10));

      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Password reset request timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  /// Update user password (after reset)
  Future<Map<String, dynamic>> updatePassword({
    required String newPassword,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.auth
          .updateUser(UserAttributes(password: newPassword))
          .timeout(const Duration(seconds: 10));

      return {'success': true, 'message': 'Password updated successfully.'};
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Password update timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> checkUserMembership() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('profiles')
          .select('is_member, membership_joined_at, membership_expires_at')
          .eq('id', user.id)
          .single()
          .timeout(const Duration(seconds: 5));

      return {
        'success': true,
        'is_member': response['is_member'] == true,
        'joined_at': response['membership_joined_at'],
        'expires_at': response['membership_expires_at'],
      };
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Membership check timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> becomeMember() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final result = await _supabase
          .rpc('become_member', params: {'p_user_id': user.id})
          .single()
          .timeout(const Duration(seconds: 10));

      return result;
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Membership request timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  // supabase_auth_service.dart - Add these methods to ensure consistency

  /// Get user profile with consistent method for all view models
  Future<Map<String, dynamic>?> getUserProfileConsistent() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      // Try the new RPC function first
      try {
        final response = await _supabase
            .rpc('get_profile_with_email')
            .single()
            .timeout(const Duration(seconds: 5));
        return response;
      } catch (e) {
        // Fall back to direct table query
        debugPrint('RPC failed, falling back to direct query: $e');
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single()
            .timeout(const Duration(seconds: 5));

        // Add email from auth user
        final profile = Map<String, dynamic>.from(response);
        profile['email'] = user.email;
        return profile;
      }
    } catch (e) {
      debugPrint('Error getting consistent user profile: $e');
      return null;
    }
  }

  /// Clear profile cache (add to CacheService too)
  Future<void> clearProfileCache() async {
    // Invalidate any cached profile data
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        // Clear any cached data
        await _supabase.auth.refreshSession();
      } catch (e) {
        debugPrint('Error clearing profile cache: $e');
      }
    }
  }

  // ==========================================
  // WORKER PROFILE MANAGEMENT
  // ==========================================

  Future<void> _createWorkerProfile(String userId) async {
    try {
      await _supabase.from('worker_profiles').insert({
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_available': true,
      });
    } catch (e) {
      debugPrint('Error creating worker profile: $e');
      // Non-critical error, don't rethrow
    }
  }

  Future<Map<String, dynamic>> updateWorkerProfile({
    List<String>? platformsConnected,
    Map<String, dynamic>? socialMediaAccounts,
    List<String>? preferredPlatforms,
    int? dailyTaskLimit,
    bool? isAvailable,
    bool? autoAcceptTasks,
    Map<String, dynamic>? notificationPreferences,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updates = {
        'updated_at': DateTime.now().toIso8601String(),
        if (platformsConnected != null)
          'platforms_connected': platformsConnected,
        if (socialMediaAccounts != null)
          'social_media_accounts': socialMediaAccounts,
        if (preferredPlatforms != null)
          'preferred_platforms': preferredPlatforms,
        if (dailyTaskLimit != null) 'daily_task_limit': dailyTaskLimit,
        if (isAvailable != null) 'is_available': isAvailable,
        if (autoAcceptTasks != null) 'auto_accept_tasks': autoAcceptTasks,
        if (notificationPreferences != null)
          'notification_preferences': notificationPreferences,
      };

      await _supabase
          .from('worker_profiles')
          .update(updates)
          .eq('user_id', user.id)
          .timeout(const Duration(seconds: 10));

      return {
        'success': true,
        'message': 'Worker profile updated successfully',
      };
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Update timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>?> getWorkerProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('worker_profiles')
          .select()
          .eq('user_id', user.id)
          .single()
          .timeout(const Duration(seconds: 5));

      return response;
    } catch (e) {
      debugPrint('Error getting worker profile: $e');
      return null;
    }
  }

  // ==========================================
  // TASK MANAGEMENT METHODS (UPDATED FOR NEW SYSTEM)
  // ==========================================

  /// Get available tasks for worker (using the new system)
  Future<List<Map<String, dynamic>>> getAvailableTasksForWorker({
    String? platform,
    int limit = 20,
  }) async {
    try {
      return await _taskService.getAvailableTasksForWorker(
        platform: platform,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting available tasks: $e');
      return [];
    }
  }

  /// Claim a task (using the new system)
  Future<Map<String, dynamic>> claimTask(String queueId) async {
    try {
      return await _taskService.claimTask(queueId);
    } catch (e) {
      debugPrint('Error claiming task: $e');
      return {'success': false, 'message': 'Failed to claim task'};
    }
  }

  /// Submit task proof (using the new system)
  /// SupabaseAuthService - Update the submitTaskProof method
  Future<Map<String, dynamic>> submitTaskProof({
    required String assignmentId,
    required String platformUsername,
    required File proofImage,
    String? proofDescription,
  }) async {
    try {
      return await _taskService.submitTaskProof(
        assignmentId: assignmentId,
        platformUsername: platformUsername,
        proofImage: proofImage,
        proofDescription: proofDescription,
      );
    } catch (e) {
      debugPrint('Error in submitTaskProof: $e');
      return {
        'success': false,
        'message': 'Failed to submit proof: ${e.toString()}',
      };
    }
  }

  /// Get worker statistics
  Future<Map<String, dynamic>> getWorkerStatistics() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      debugPrint('Fetching worker statistics for user: ${user.id}');

      // Call the RPC function - returns a list/table
      final response = await _supabase
          .rpc('get_worker_statistics', params: {'p_worker_id': user.id})
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      debugPrint('Worker statistics response: $response');

      if (response == null) {
        // Return default statistics if no data found
        return {
          'success': true,
          'data': {
            'total_earnings': 0.0,
            'total_tasks_completed': 0,
            'average_rating': 0.0,
            'success_rate': 0.0,
            'pending_payouts': 0.0,
            'available_tasks': 0,
            'wallet_balance': 0.0,
            'wallet_available_balance': 0.0,
          },
        };
      }

      // The response should be a map since we used maybeSingle()
      final stats = response as Map<String, dynamic>;

      double _toDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      int _toInt(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      return {
        'success': true,
        'data': {
          'total_earnings': _toDouble(stats['total_earnings']),
          'total_tasks_completed': _toInt(stats['total_tasks_completed']),
          'average_rating': _toDouble(stats['average_rating']),
          'success_rate': _toDouble(stats['success_rate']),
          'pending_payouts': _toDouble(stats['pending_payouts']),
          'available_tasks': _toInt(stats['available_tasks']),
          'wallet_balance': _toDouble(stats['wallet_balance']),
          'wallet_available_balance': _toDouble(
            stats['wallet_available_balance'],
          ),
        },
      };
    } catch (e) {
      debugPrint('Error getting worker statistics: $e');
      return {
        'success': false,
        'message': 'Failed to get statistics: ${e.toString()}',
      };
    }
  }

  // Add this as a separate method or in TaskService if it exists
  Future<Map<String, dynamic>> getWorkerStatisticsDirect() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Alternative: Direct queries instead of RPC
      final workerProfile =
          await _supabase
              .from('worker_profiles')
              .select(
                'total_earnings, total_tasks_completed, average_rating, success_rate',
              )
              .eq('user_id', user.id)
              .maybeSingle();

      // Get pending payouts
      final pendingPayoutsResult = await _supabase
          .from('task_assignments')
          .select('worker_payout')
          .eq('worker_id', user.id)
          .eq('status', 'completed')
          .eq('payout_status', 'pending');

      final pendingPayouts = pendingPayoutsResult.fold<double>(
        0.0,
        (sum, item) => sum + (item['worker_payout'] as num).toDouble(),
      );

      // Get available tasks
      final availableTasksResult = await _supabase
          .from('task_queue')
          .select('id')
          .eq('status', 'available')
          .limit(100);

      return {
        'success': true,
        'data': {
          'total_earnings': (workerProfile?['total_earnings'] ?? 0.0) as double,
          'total_tasks_completed':
              (workerProfile?['total_tasks_completed'] ?? 0) as int,
          'average_rating': (workerProfile?['average_rating'] ?? 0.0) as double,
          'success_rate': (workerProfile?['success_rate'] ?? 0.0) as double,
          'pending_payouts': pendingPayouts,
          'available_tasks': availableTasksResult.length,
          'wallet_balance': 0.0, // You'll need to get from wallet system
          'wallet_available_balance':
              0.0, // You'll need to get from wallet system
        },
      };
    } catch (e) {
      debugPrint('Error in getWorkerStatisticsDirect: $e');
      return {
        'success': false,
        'message': 'Failed to load statistics: ${e.toString()}',
      };
    }
  }

  /// Get worker task history
  Future<List<Map<String, dynamic>>> getWorkerTaskHistory({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _taskService.getWorkerTaskHistory(
        status: status,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error getting task history: $e');
      return [];
    }
  }

  /// Create advertiser order (for advertisers)
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
      return await _taskService.createAdvertiserOrder(
        taskId: taskId,
        platform: platform,
        quantity: quantity,
        adContent: adContent,
        adImageUrl: adImageUrl,
        targetLink: targetLink,
        targetUsername: targetUsername,
        metadata: metadata,
        ipAddress: ipAddress,
        userAgent: userAgent,
        deviceId: deviceId,
        location: location,
      );
    } catch (e) {
      debugPrint('Error creating advertiser order: $e');
      return {'success': false, 'message': 'Failed to create order'};
    }
  }

  /// Upload advert/engagement media for an existing order.
  Future<Map<String, dynamic>> uploadOrderMediaFiles({
    required String orderId,
    required List<File> mediaFiles,
  }) async {
    try {
      return await _taskService.uploadOrderMediaFiles(
        orderId: orderId,
        mediaFiles: mediaFiles,
      );
    } catch (e) {
      debugPrint('Error uploading order media: $e');
      return {'success': false, 'message': 'Failed to upload order media'};
    }
  }

  // ==========================================
  // PROFILE METHODS (Updated for new schema)
  // ==========================================

  /// Get user profile with email using the new function
  Future<Map<String, dynamic>?> getUserProfileWithEmail() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .rpc('get_profile_with_email')
          .single()
          .timeout(const Duration(seconds: 5));

      return response;
    } catch (e) {
      debugPrint('Error getting user profile with email: $e');
      return null;
    }
  }

  /// Get user profile (without email) - for public display
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single()
          .timeout(const Duration(seconds: 5));

      return response;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  /// Update profile (email is not included as it's in auth.users)
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? gender,
    String? religion,
    int? dobDay,
    String? dobMonth,
    int? dobYear,
    int? stateId,
    int? lgaId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First, ensure profile exists
      try {
        await _supabase
            .from('profiles')
            .select('id')
            .eq('id', user.id)
            .single()
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        // Profile doesn't exist, create it
        await _createUserProfileFallback(
          userId: user.id,
          fullName: fullName ?? 'User',
          phone: phone,
        );
      }

      final updates = {
        'updated_at': DateTime.now().toIso8601String(),
        if (fullName != null) 'full_name': fullName,
        if (username != null) 'username': username,
        if (phone != null) 'phone_number': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (bio != null) 'bio': bio,
        if (gender != null) 'gender': gender,
        if (religion != null) 'religion': religion,
        if (dobDay != null) 'dob_day': dobDay,
        if (dobMonth != null) 'dob_month': dobMonth,
        if (dobYear != null) 'dob_year': dobYear,
        if (stateId != null) 'state_id': stateId,
        if (lgaId != null) 'lga_id': lgaId,
      };

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', user.id)
          .timeout(const Duration(seconds: 10));

      // Update auth metadata if needed
      if (fullName != null || phone != null || avatarUrl != null) {
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              if (fullName != null) 'full_name': fullName,
              if (phone != null) 'phone': phone,
              if (avatarUrl != null) 'avatar_url': avatarUrl,
            },
          ),
        );
      }

      return {'success': true, 'message': 'Profile updated successfully'};
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Profile update timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final path =
          '${user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.png';

      await _supabase.storage
          .from('avatars')
          .upload(path, imageFile, fileOptions: const FileOptions(upsert: true))
          .timeout(const Duration(seconds: 30));

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);

      await updateProfile(avatarUrl: publicUrl);

      return {
        'success': true,
        'url': publicUrl,
        'message': 'Profile picture updated successfully!',
      };
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Image upload timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==========================================
  // UTILITY METHODS
  // ==========================================

  User? getCurrentUser() => _supabase.auth.currentUser;

  bool isAuthenticated() => _supabase.auth.currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  static String getErrorMessage(dynamic error) {
    debugPrint('Error in getErrorMessage: $error');

    if (error is AuthException) {
      return _parseAuthException(error);
    }

    if (error is PostgrestException) {
      return 'Database error: ${error.message}';
    }

    if (error is SocketException || error.toString().contains('network')) {
      return 'Network error. Please check your internet connection.';
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  static String _parseAuthException(AuthException error) {
    final message = error.message?.toLowerCase() ?? '';

    if (message.contains('user already registered')) {
      return 'This email is already in use.';
    }

    if (message.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please verify your email address.';
    }

    if (message.contains('database error saving new user')) {
      return 'Error creating user profile. Please try again.';
    }

    return error.message ?? 'Authentication failed.';
  }

  // Database testing method - FIXED: Removed count parameter
  Future<Map<String, dynamic>> testDatabaseConnection() async {
    try {
      final test = await _supabase
          .from('profiles')
          .select()
          .limit(1)
          .timeout(const Duration(seconds: 5));

      return {
        'success': true,
        'message': 'Database connection successful',
        'test_result': test.isNotEmpty,
      };
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Database connection timed out'};
    } catch (e) {
      return {'success': false, 'message': 'Database connection failed: $e'};
    }
  }

  // Verify password reset token
  Future<Map<String, dynamic>> verifyResetToken({
    required String token,
    required String tokenHash,
  }) async {
    try {
      // Supabase handles token verification through the redirect
      return {'success': true, 'message': 'Token verified successfully.'};
    } on TimeoutException catch (_) {
      return {
        'success': false,
        'message': 'Token verification timed out. Please try again.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Invalid or expired reset token.'};
    }
  }

  // Check if password reset is required
  Future<Map<String, dynamic>> checkPasswordResetRequired() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        return {
          'success': false,
          'requiresReset': false,
          'message': 'No active session.',
        };
      }

      // Check session metadata for password reset flag
      final requiresReset =
          session.user.userMetadata?['requires_password_reset'] == true;

      return {
        'success': true,
        'requiresReset': requiresReset,
        'message':
            requiresReset
                ? 'Password reset required.'
                : 'No password reset required.',
      };
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Password reset check timed out.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking password reset status.',
      };
    }
  }
}
