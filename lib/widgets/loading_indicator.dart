import 'package:flutter/material.dart';

/// A customizable loading indicator widget
class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? message;
  final bool showMessageBelow;
  final TextStyle? messageStyle;
  final MainAxisAlignment alignment;

  const LoadingIndicator({
    Key? key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 3.0,
    this.message,
    this.showMessageBelow = false,
    this.messageStyle,
    this.alignment = MainAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.primaryColor;

    final progressIndicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
      ),
    );

    // If no message, just return the spinner
    if (message == null) {
      return Center(child: progressIndicator);
    }

    // With message
    if (showMessageBelow) {
      return Column(
        mainAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          progressIndicator,
          const SizedBox(height: 12),
          Text(
            message!,
            style:
                messageStyle ??
                theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          progressIndicator,
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message!,
              style:
                  messageStyle ??
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
  }
}

/// A linear loading indicator (for progress bars)
class LinearLoadingIndicator extends StatelessWidget {
  final double? value;
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final String? message;
  final EdgeInsetsGeometry padding;

  const LinearLoadingIndicator({
    Key? key,
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.height = 4.0,
    this.borderRadius,
    this.message,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.primaryColor.withOpacity(0.1);
    final color = valueColor ?? theme.primaryColor;

    final progressBar = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: bgColor,
        color: color,
        minHeight: height,
      ),
    );

    if (message == null) {
      return Padding(padding: padding, child: progressBar);
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          progressBar,
          const SizedBox(height: 8),
          Text(
            message!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}

/// A shimmer loading effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    Key? key,
    required this.child,
    required this.isLoading,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  _ShimmerLoadingState createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? theme.cardColor;
    final highlightColor =
        widget.highlightColor ?? theme.primaryColor.withOpacity(0.5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + (_controller.value * 2), 0.0),
              end: const Alignment(1.0, 0.0),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A loading placeholder for lists
class ListLoadingPlaceholder extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;
  final bool showShimmer;

  const ListLoadingPlaceholder({
    Key? key,
    this.itemCount = 3,
    this.itemHeight = 100.0,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0),
    this.showShimmer = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final placeholder = ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: padding,
          child: Container(
            height: itemHeight,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );

    if (!showShimmer) return placeholder;

    return ShimmerLoading(isLoading: true, child: placeholder);
  }
}

/// A loading overlay that dims the background
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? overlayColor;
  final double opacity;
  final Color? progressColor;
  final double progressSize;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.overlayColor,
    this.opacity = 0.7,
    this.progressColor,
    this.progressSize = 50.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Main content
        child,

        // Loading overlay
        if (isLoading)
          ModalBarrier(
            color: overlayColor ?? Colors.black.withOpacity(opacity),
            dismissible: false,
          ),

        // Loading indicator
        if (isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress indicator
                  SizedBox(
                    width: progressSize,
                    height: progressSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressColor ?? theme.primaryColor,
                      ),
                    ),
                  ),

                  // Optional message
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.8,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
