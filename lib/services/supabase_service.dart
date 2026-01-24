import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:juvapay/models/notification.dart';
import 'package:juvapay/models/enums.dart';

class SupabaseNotificationService {
  final SupabaseClient _supabase;

  SupabaseNotificationService(this._supabase);

  // Get user notifications with pagination
  Future<List<NotificationModel>> getUserNotifications({
    int limit = 50,
    int offset = 0,
    NotificationStatus? status,
    NotificationType? type,
  }) async {
    try {
      // 1. Start the query builder (returns PostgrestFilterBuilder)
      var query = _supabase.from('notifications').select();

      // 2. Apply all filters FIRST (before ordering/ranging)
      query = query.eq('user_id', _supabase.auth.currentUser!.id);

      if (status != null) {
        query = query.eq('status', status.name.toUpperCase());
      }

      if (type != null) {
        query = query.eq('notification_type', type.name.toUpperCase());
      }

      // 3. Apply Modifiers (order and range) at the end
      // In v2, await returns the data list directly, not a 'response' object
      final List<dynamic> data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // 4. Map the data
      return data
          .map((json) => NotificationModel.fromJson(json))
          .where((notification) => notification.canShow)
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Get unread notifications count
  Future<int> getUnreadCount() async {
    try {
      // In v2, .count() returns the integer directly
      final count = await _supabase
          .from('notifications')
          .count(CountOption.exact) // Use CountOption.exact
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('status', 'UNREAD');

      return count;
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'status': 'READ',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final response = await _supabase.rpc('mark_all_notifications_as_read');
      return response as int? ?? 0;
    } catch (e) {
      print('Error marking all as read: $e');
      rethrow;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Archive notification
  Future<void> archiveNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'status': 'ARCHIVED',
            'archived_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId)
          .eq('user_id', _supabase.auth.currentUser!.id);
    } catch (e) {
      print('Error archiving notification: $e');
      rethrow;
    }
  }

  // Create notification
  Future<String> createNotification({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    NotificationPriority priority = NotificationPriority.medium,
    List<NotificationChannel>? channels,
    String? actionUrl,
    String? actionLabel,
    String? referenceId,
    String? referenceType,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_notification',
        params: {
          'p_user_id': userId,
          'p_title': title,
          'p_message': message,
          'p_notification_type': type.name.toUpperCase(),
          'p_priority': priority.name.toUpperCase(),
          'p_channels':
              channels?.map((c) => c.name.toUpperCase()).toList() ?? ['IN_APP'],
          'p_action_url': actionUrl,
          'p_action_label': actionLabel,
          'p_reference_id': referenceId,
          'p_reference_type': referenceType,
          'p_metadata': metadata,
        },
      );

      return response as String;
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  // Create notification from template
  Future<String> createNotificationFromTemplate({
    required String userId,
    required String templateKey,
    required Map<String, dynamic> variables,
    List<NotificationChannel>? channels,
  }) async {
    try {
      final response = await _supabase.rpc(
        'create_notification_from_template',
        params: {
          'p_user_id': userId,
          'p_template_key': templateKey,
          'p_variables': variables,
          'p_override_channels':
              channels?.map((c) => c.name.toUpperCase()).toList(),
        },
      );

      return response as String;
    } catch (e) {
      print('Error creating notification from template: $e');
      rethrow;
    }
  }

  // Get notification preferences
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      // .maybeSingle() is safer than .single() if no row exists (returns null instead of error)
      final response =
          await _supabase
              .from('notification_preferences')
              .select()
              .eq('user_id', _supabase.auth.currentUser!.id)
              .maybeSingle();

      if (response != null) {
        return response;
      }
      return {};
    } catch (e) {
      print('Error fetching preferences: $e');
      return {};
    }
  }

  // Update notification preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      await _supabase.from('notification_preferences').upsert({
        'user_id': _supabase.auth.currentUser!.id,
        ...preferences,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating preferences: $e');
      rethrow;
    }
  }

  // Subscribe to real-time notifications
  RealtimeChannel subscribeToNotifications(
    Function(Map<String, dynamic>) callback,
  ) {
    // Create a channel for notifications
    final channel = _supabase.channel('notifications');

    // Updated Realtime Syntax for v2
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              // Check if the notification is for the current user
              if (newRecord['user_id'] == _supabase.auth.currentUser?.id) {
                callback(newRecord);
              }
            }
          },
        )
        .subscribe();

    return channel;
  }
}
