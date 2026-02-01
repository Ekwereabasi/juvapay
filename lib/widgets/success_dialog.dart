import 'package:flutter/material.dart';

/// Shows a success dialog with customizable options
Future<void> showSuccessDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? buttonText,
  VoidCallback? onPressed,
  bool dismissible = true,
  bool showIcon = true,
  bool autoClose = false,
  Duration autoCloseDuration = const Duration(seconds: 2),
  IconData? icon, // Add icon parameter
}) async {
  // If auto-close is enabled, show and then automatically close
  if (autoClose) {
    showDialog<void>(
      context: context,
      barrierDismissible: dismissible,
      builder: (BuildContext context) {
        return SuccessDialog(
          title: title,
          message: message,
          buttonText: buttonText,
          onPressed: onPressed,
          showIcon: showIcon,
          icon: icon, // Pass icon to dialog
        );
      },
    );

    // Auto close after duration
    await Future.delayed(autoCloseDuration);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  } else {
    // Regular dialog with button
    return showDialog<void>(
      context: context,
      barrierDismissible: dismissible,
      builder: (BuildContext context) {
        return SuccessDialog(
          title: title,
          message: message,
          buttonText: buttonText,
          onPressed: onPressed,
          showIcon: showIcon,
          icon: icon, // Pass icon to dialog
        );
      },
    );
  }
}

/// A customizable success dialog widget
class SuccessDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String? buttonText;
  final VoidCallback? onPressed;
  final bool showIcon;
  final IconData? icon; // Add icon field

  const SuccessDialog({
    Key? key,
    required this.title,
    this.message,
    this.buttonText,
    this.onPressed,
    this.showIcon = true,
    this.icon, // Add to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            if (showIcon)
              Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.check_circle, // Use custom icon or default
                  size: 32,
                  color: Colors.green,
                ),
              ),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),

            // Message
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],

            // Action Button
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed ?? () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(buttonText ?? 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a success snackbar message
void showSuccessSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 3),
  bool showAction = false,
  String actionLabel = 'OK',
  VoidCallback? onActionPressed,
}) {
  final theme = Theme.of(context);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action:
            showAction
                ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onActionPressed ?? () {},
                )
                : null,
        margin: const EdgeInsets.all(10),
      ),
    );
}

/// A success toast widget that can be shown at the bottom
class SuccessToast extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;

  const SuccessToast({
    Key? key,
    required this.message,
    this.icon,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.green,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-screen success widget
class FullScreenSuccess extends StatelessWidget {
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onContinue;
  final Widget? icon;

  const FullScreenSuccess({
    Key? key,
    required this.title,
    required this.message,
    this.buttonText,
    this.onContinue,
    this.icon,
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
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 50,
                      color: Colors.green,
                    ),
                  ),

              const SizedBox(height: 32),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 12),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),

              // Continue Button
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(buttonText ?? 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
