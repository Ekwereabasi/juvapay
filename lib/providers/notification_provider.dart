import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:juvapay/models/notification.dart';
import 'package:juvapay/services/supabase_service.dart'; // Updated import
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/enums.dart';

// Update to use StateNotifierProvider for better Riverpod pattern
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final supabase = Supabase.instance.client;
      return NotificationNotifier(supabase);
    });

class NotificationState {
  final List<NotificationModel> notifications;
  final Map<String, dynamic> preferences;
  final int unreadCount;
  final bool isLoading;
  final bool showBadge;

  NotificationState({
    this.notifications = const [],
    this.preferences = const {},
    this.unreadCount = 0,
    this.isLoading = false,
    this.showBadge = true,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    Map<String, dynamic>? preferences,
    int? unreadCount,
    bool? isLoading,
    bool? showBadge,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      preferences: preferences ?? this.preferences,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      showBadge: showBadge ?? this.showBadge,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final SupabaseClient _supabase;
  late SupabaseNotificationService _service;
  RealtimeChannel? _subscription;

  NotificationNotifier(this._supabase) : super(NotificationState()) {
    _service = SupabaseNotificationService(_supabase);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);

      await _loadNotifications();
      await _loadPreferences();

      // Setup real-time subscription
      _setupRealtimeSubscription();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      print('Error initializing notification provider: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _service.getUserNotifications();
      final unreadCount = notifications.where((n) => n.isUnread).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _service.getPreferences();
      if (preferences.isEmpty) {
        // Set default preferences
        final defaultPrefs = {
          'email_enabled': true,
          'push_enabled': true,
          'in_app_enabled': true,
          'sms_enabled': false,
          'whatsapp_enabled': false,
          'quiet_hours_enabled': true,
          'quiet_hours_start': '22:00',
          'quiet_hours_end': '08:00',
        };
        state = state.copyWith(preferences: defaultPrefs);
      } else {
        state = state.copyWith(preferences: preferences);
      }
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  void _setupRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _subscription = _service.subscribeToNotifications((payload) {
      final newNotification = NotificationModel.fromJson(payload);

      final updatedNotifications = [newNotification, ...state.notifications];
      final newUnreadCount =
          state.unreadCount + (newNotification.isUnread ? 1 : 0);

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );

      // Show local notification if needed
      if (newNotification.isUnread &&
          newNotification.channels.contains(NotificationChannel.inApp)) {
        _showLocalNotification(newNotification);
      }
    });
  }

  void _showLocalNotification(NotificationModel notification) {
    // Implement local notifications using flutter_local_notifications
    print('New notification: ${notification.title}');
  }

  // Public method to mark as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _service.markAsRead(notificationId);

      final updatedNotifications =
          state.notifications.map((n) {
            if (n.id == notificationId) {
              return n.copyWith(
                status: NotificationStatus.read,
                readAt: DateTime.now(),
              );
            }
            return n;
          }).toList();

      final newUnreadCount =
          updatedNotifications.where((n) => n.isUnread).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (e) {
      print('Error marking as read: $e');
      rethrow;
    }
  }

  // Public method to mark all as read
  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();

      final updatedNotifications =
          state.notifications.map((n) {
            return n.copyWith(
              status: NotificationStatus.read,
              readAt: DateTime.now(),
            );
          }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      print('Error marking all as read: $e');
      rethrow;
    }
  }

  // Public method to delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _service.deleteNotification(notificationId);

      final updatedNotifications =
          state.notifications.where((n) => n.id != notificationId).toList();

      final newUnreadCount =
          updatedNotifications.where((n) => n.isUnread).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  // Public method to save preferences
  Future<void> savePreferences(Map<String, dynamic> newPreferences) async {
    try {
      await _service.updatePreferences(newPreferences);
      state = state.copyWith(preferences: newPreferences);
    } catch (e) {
      print('Error saving preferences: $e');
      rethrow;
    }
  }

  // Public method to refresh
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadNotifications();
    await _loadPreferences();
    state = state.copyWith(isLoading: false);
  }

  // Public method to toggle badge
  void toggleBadgeVisibility(bool show) {
    state = state.copyWith(showBadge: show);
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
