// error_boundary.dart
import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.onError != null) {
      return widget.onError!(_error!, _stackTrace ?? StackTrace.current);
    }
    
    return _ErrorBoundaryBuilder(
      onError: (error, stackTrace) {
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
        });
      },
      child: widget.child,
    );
  }
}

class _ErrorBoundaryBuilder extends StatefulWidget {
  final Widget child;
  final Function(Object error, StackTrace stackTrace) onError;

  const _ErrorBoundaryBuilder({
    required this.child,
    required this.onError,
  });

  @override
  State<_ErrorBoundaryBuilder> createState() => __ErrorBoundaryBuilderState();
}

class __ErrorBoundaryBuilderState extends State<_ErrorBoundaryBuilder> {
  @override
  void initState() {
    super.initState();
    // Reset error state when widget rebuilds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Reset any previous error state
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Helper function to catch errors in async operations
Future<T> runWithErrorHandling<T>({
  required Future<T> Function() operation,
  required Function(Object error, StackTrace stackTrace) onError,
  T? fallbackValue,
}) async {
  try {
    return await operation();
  } catch (error, stackTrace) {
    onError(error, stackTrace);
    if (fallbackValue != null) {
      return fallbackValue;
    }
    rethrow;
  }
}