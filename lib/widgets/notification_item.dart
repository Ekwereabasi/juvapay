import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:juvapay/providers/notification_provider.dart';
import 'package:juvapay/models/notification.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/enums.dart';

class NotificationItem extends ConsumerWidget {
  final NotificationModel notification;
  final bool showDeleteButton;

  const NotificationItem({
    super.key,
    required this.notification,
    this.showDeleteButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationProvider.notifier);

    // Access theme data once to avoid repeated lookups
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation:
          notification.isUnread ? 2 : 0, // Lower elevation for read items
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            notification.isUnread
                ? BorderSide(
                  color: colorScheme.primary.withOpacity(0.2),
                  width: 1,
                )
                : BorderSide.none,
      ),
      // Use colorScheme for background logic
      color:
          notification.isUnread
              ? colorScheme.primaryContainer.withOpacity(
                0.4,
              ) // Dark mode friendly tint
              : theme.cardColor,
      child: InkWell(
        onTap: () {
          notifier.markAsRead(notification.id);
          if (notification.actionUrl != null) {
            // Handle navigation
            // Navigator.pushNamed(context, notification.actionUrl!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  // Use the helper method but adapt the opacity/mix
                  color: _getIconColor(
                    notification.type,
                    theme,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    _getIcon(notification.type),
                    color: _getIconColor(notification.type, theme),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  notification.isUnread
                                      ? colorScheme.primary
                                      : textTheme.bodyMedium?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (notification.isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      // Use proper typography for secondary text
                      style: textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(
                              notification.priority,
                              theme,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getPriorityColor(
                                notification.priority,
                                theme,
                              ).withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            _getPriorityText(notification.priority),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(
                                notification.priority,
                                theme,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Time
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 10,
                              color: theme.hintColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeago.format(notification.createdAt),
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Action Label
                        if (notification.actionLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              notification.actionLabel!,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              if (showDeleteButton)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    // Use onSurface with opacity for proper dark/light mode adaption
                    color: theme.disabledColor,
                  ),
                  onPressed: () => _showDeleteDialog(context, notifier),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.shopping_bag;
      case NotificationType.transaction:
        return Icons.account_balance_wallet;
      case NotificationType.support:
        return Icons.help_outline;
      case NotificationType.task:
        return Icons.task_alt;
      case NotificationType.wallet:
        return Icons.account_balance;
      case NotificationType.security:
        return Icons.security;
      case NotificationType.promotion:
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(NotificationType type, ThemeData theme) {
    // We pass theme here to handle the default case or specific theme overrides
    switch (type) {
      case NotificationType.order:
        return Colors.blue;
      case NotificationType.transaction:
        return Colors.green;
      case NotificationType.support:
        return Colors.purple;
      case NotificationType.task:
        return Colors.orange;
      case NotificationType.wallet:
        return Colors.teal;
      case NotificationType.security:
        return theme.colorScheme.error; // Use theme error color
      case NotificationType.promotion:
        return Colors.pink;
      default:
        return theme.iconTheme.color ?? Colors.grey;
    }
  }

  Color _getPriorityColor(NotificationPriority priority, ThemeData theme) {
    switch (priority) {
      case NotificationPriority.urgent:
        return theme.colorScheme.error; // Use theme error
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.medium:
        return Colors.blue;
      case NotificationPriority.low:
        return theme.disabledColor; // Use theme disabled
    }
  }

  String _getPriorityText(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return 'URGENT';
      case NotificationPriority.high:
        return 'HIGH';
      case NotificationPriority.medium:
        return 'MEDIUM';
      case NotificationPriority.low:
        return 'LOW';
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    NotificationNotifier notifier,
  ) async {
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text(
              'Are you sure you want to delete this notification?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
              ),
              TextButton(
                onPressed: () {
                  notifier.deleteNotification(notification.id);
                  Navigator.pop(context);
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }
}
