import 'package:flutter/material.dart';

/// A widget to display when there's an error
class ErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final bool showActionButton;
  final String? errorCode;
  final bool compact;

  const ErrorState({
    Key? key,
    this.icon = Icons.error_outline,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.iconColor,
    this.iconSize = 80.0,
    this.padding = const EdgeInsets.all(24.0),
    this.showActionButton = true,
    this.errorCode,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = iconColor ?? theme.colorScheme.error;

    if (compact) {
      return Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize * 0.6, color: errorColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (errorCode != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: $errorCode',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: iconSize,
              height: iconSize,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize * 0.5, color: errorColor),
            ),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: errorColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Error Code
            if (errorCode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: $errorCode',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],

            // Action Button
            if (showActionButton && actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    actionText!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Specific error states for common scenarios
class NetworkErrorState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NetworkErrorState({Key? key, this.onRetry, this.customMessage})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.wifi_off,
      title: 'Network Error',
      message:
          customMessage ??
          'Unable to connect to the server. Please check your internet connection and try again.',
      actionText: 'Retry',
      onAction: onRetry,
      iconColor: Colors.orange,
      errorCode: 'ERR_NETWORK',
    );
  }
}

class ServerErrorState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? errorCode;
  final String? customMessage;

  const ServerErrorState({
    Key? key,
    this.onRetry,
    this.errorCode,
    this.customMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.cloud_off_outlined,
      title: 'Server Error',
      message:
          customMessage ??
          'Something went wrong on our servers. Please try again later.',
      actionText: 'Try Again',
      onAction: onRetry,
      iconColor: Colors.red,
      errorCode: errorCode ?? 'ERR_SERVER',
    );
  }
}

class AuthenticationErrorState extends StatelessWidget {
  final VoidCallback? onLogin;
  final String? customMessage;

  const AuthenticationErrorState({Key? key, this.onLogin, this.customMessage})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.lock_outline,
      title: 'Authentication Required',
      message:
          customMessage ?? 'You need to be logged in to access this feature.',
      actionText: 'Login',
      onAction: onLogin,
      iconColor: Colors.blue,
      errorCode: 'ERR_AUTH',
    );
  }
}

class PermissionErrorState extends StatelessWidget {
  final VoidCallback? onGrantPermission;
  final String? permissionName;
  final String? customMessage;

  const PermissionErrorState({
    Key? key,
    this.onGrantPermission,
    this.permissionName,
    this.customMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.security_outlined,
      title: 'Permission Required',
      message: customMessage ??
          'This feature requires ${permissionName ?? 'additional'} permission to work properly.',
      actionText: 'Grant Permission',
      onAction: onGrantPermission,
      iconColor: Colors.purple,
      errorCode: 'ERR_PERMISSION',
    );
  }
}

/// A full-screen error widget
class FullScreenError extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onRetry;
  final Widget? icon;
  final bool showRetryButton;

  const FullScreenError({
    Key? key,
    required this.title,
    required this.message,
    this.buttonText,
    this.onRetry,
    this.icon,
    this.showRetryButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              icon ??
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 50,
                      color: theme.colorScheme.error,
                    ),
                  ),

              const SizedBox(height: 32),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                  height: 1.5,
                ),
              ),

              // Retry Button
              if (showRetryButton) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: Text(buttonText ?? 'Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// An error state that can be placed inline (in lists, cards, etc.)
class InlineErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool showIcon;
  final EdgeInsetsGeometry margin;

  const InlineErrorState({
    Key? key,
    required this.message,
    this.onRetry,
    this.showIcon = true,
    this.margin = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
