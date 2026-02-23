import 'package:flutter/material.dart';
import 'package:juvapay/utils/network_messages.dart';

/// A widget to display when there's no data
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final bool showActionButton;
  final bool compact;

  const EmptyState({
    Key? key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.iconColor,
    this.iconSize = 80.0,
    this.padding = const EdgeInsets.all(24.0),
    this.showActionButton = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColorValue = iconColor ?? theme.primaryColor.withOpacity(0.3);

    if (compact) {
      return Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize * 0.6, color: iconColorValue),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.hintColor,
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
                color: iconColorValue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: iconSize * 0.5, color: iconColorValue),
            ),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.hintColor,
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

            // Action Button
            if (showActionButton && actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    actionText!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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

/// Specific empty states for common scenarios
class NoResultsEmptyState extends StatelessWidget {
  final String? searchQuery;
  final VoidCallback? onClearSearch;
  final String? customMessage;

  const NoResultsEmptyState({
    Key? key,
    this.searchQuery,
    this.onClearSearch,
    this.customMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message =
        customMessage ??
        (searchQuery != null
            ? 'No results found for "$searchQuery"'
            : 'No items found');

    return EmptyState(
      icon: Icons.search_off,
      title: 'No Results',
      message: message,
      actionText: searchQuery != null ? 'Clear Search' : null,
      onAction: onClearSearch,
      showActionButton: searchQuery != null,
    );
  }
}

class NoInternetEmptyState extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NoInternetEmptyState({Key? key, this.onRetry, this.customMessage})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off_outlined,
      title: "This page couldn't load",
      message: customMessage ?? NetworkMessages.pageLoadFailed,
      actionText: 'Try Again',
      onAction: onRetry,
      iconColor: Colors.orange,
    );
  }
}

class NoTransactionsEmptyState extends StatelessWidget {
  final VoidCallback? onAddTransaction;
  final String? customMessage;

  const NoTransactionsEmptyState({
    Key? key,
    this.onAddTransaction,
    this.customMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'No Transactions',
      message:
          customMessage ??
          'Your transaction history will appear here when you make your first transaction.',
      actionText: onAddTransaction != null ? 'Make a Transaction' : null,
      onAction: onAddTransaction,
    );
  }
}

class NoProductsEmptyState extends StatelessWidget {
  final VoidCallback? onAddProduct;
  final bool isMarketplace;

  const NoProductsEmptyState({
    Key? key,
    this.onAddProduct,
    this.isMarketplace = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.shopping_bag_outlined,
      title: isMarketplace ? 'No Products Found' : 'Your Products',
      message:
          isMarketplace
              ? 'Be the first to list a product in the marketplace!'
              : 'You haven\'t listed any products yet. Start selling today!',
      actionText: onAddProduct != null ? 'Add Product' : null,
      onAction: onAddProduct,
    );
  }
}

/// An empty state with an image instead of an icon
class ImageEmptyState extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final double imageHeight;
  final EdgeInsetsGeometry padding;

  const ImageEmptyState({
    Key? key,
    required this.imageAsset,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.imageHeight = 150.0,
    this.padding = const EdgeInsets.all(24.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            Container(
              height: imageHeight,
              margin: const EdgeInsets.only(bottom: 24),
              child: Image.asset(imageAsset, fit: BoxFit.contain),
            ),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.hintColor,
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

            // Action Button
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    actionText!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
