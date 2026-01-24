import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:juvapay/providers/notification_provider.dart';
import 'package:juvapay/views/settings/subpages/notifications/notifications_screen.dart';

class NotificationBell extends ConsumerWidget {
  final Color? iconColor;
  final double? iconSize;
  final Function(String)? onNotificationTap;

  const NotificationBell({
    super.key,
    this.iconColor,
    this.iconSize,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(notificationProvider);

    // Access the current theme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IconButton(
      icon: Stack(
        clipBehavior:
            Clip.none, // Ensures badge isn't clipped if slightly outside
        children: [
          Icon(
            Icons.notifications_outlined,
            // Fallback to theme's default icon color if iconColor is null
            color: iconColor ?? theme.iconTheme.color,
            size: iconSize ?? 24,
          ),
          if (provider.showBadge && provider.unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  // Use error color for badges (typically red)
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                  // Use surface color for border to blend with AppBar/Background
                  border: Border.all(color: colorScheme.surface, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    provider.unreadCount > 9 ? '9+' : '${provider.unreadCount}',
                    style: TextStyle(
                      // onError ensures text is legible against the badge color
                      color: colorScheme.onError,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        );
      },
    );
  }
}
