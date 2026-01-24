import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:juvapay/providers/notification_provider.dart';
import 'package:juvapay/widgets/notification_item.dart';
import 'notification_settings_screen.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    // 1. Access the theme data
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    final notifications = state.notifications;
    final unreadCount = state.unreadCount;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Explicit background
      appBar: AppBar(
        title: const Text('Notifications'),
        // No hardcoded background allows AppBar to adapt to theme (light/dark)
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read),
              // Use primary color for actions to make them pop, or default icon color
              color: colorScheme.primary,
              tooltip: 'Mark all as read',
              onPressed: () => _showMarkAllReadDialog(context, notifier),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            // Default icon color adapts to app bar theme automatically
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                ),
          ),
        ],
      ),
      body:
          state.isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary, // Matches brand color
                ),
              )
              : notifications.isEmpty
              ? _buildEmptyState(theme) // Pass theme to helper
              : RefreshIndicator(
                color: colorScheme.primary,
                backgroundColor: theme.cardColor,
                onRefresh: () async => notifier.refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.only(top: 16, bottom: 80),
                  itemCount: notifications.length,
                  separatorBuilder:
                      (context, index) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    // Assuming NotificationItem handles its own internal theming
                    // If not, you might need to wrap this or pass style data
                    return NotificationItem(notification: notifications[index]);
                  },
                ),
              ),
      floatingActionButton:
          unreadCount > 0
              ? FloatingActionButton.extended(
                onPressed: () => notifier.markAllAsRead(),
                icon: const Icon(Icons.check),
                label: const Text('Mark All Read'),
                // Explicitly use scheme colors for better dark mode contrast
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              )
              : null,
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    // Using colorScheme.onSurface with opacity ensures
    // grey text looks correct on both black and white backgrounds
    final textColor = theme.colorScheme.onSurface.withOpacity(0.6);
    final iconColor = theme.disabledColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: iconColor, // Adapts to dark mode disabled state
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something arrives',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMarkAllReadDialog(
    BuildContext context,
    NotificationNotifier notifier,
  ) async {
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Mark All as Read'),
            content: const Text('Mark all notifications as read?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                // Cancel usually uses the secondary or hint color
                child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
              ),
              TextButton(
                onPressed: () {
                  notifier.markAllAsRead();
                  Navigator.pop(context);
                },
                // Action buttons use the primary color
                child: Text(
                  'Mark All Read',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
