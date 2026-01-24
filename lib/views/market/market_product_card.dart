import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MarketProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const MarketProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatCurrency = NumberFormat.simpleCurrency(
      name: 'NGN',
      decimalDigits: 0,
    );

    // Data extraction
    final double price = (product['price'] as num).toDouble();
    final double? oldPrice =
        product['old_price'] != null
            ? (product['old_price'] as num).toDouble()
            : null;
    final String title = product['title'] ?? 'No Title';
    final int likes = product['likes_count'] ?? 0;
    final int views = product['views_count'] ?? 0;

    // Get first image or placeholder
    final List images = product['marketplace_product_images'] ?? [];
    final String imageUrl =
        images.isNotEmpty
            ? images[0]['image_url']
            : 'https://via.placeholder.com/150';

    // Calculate Discount %
    int discountPercent = 0;
    if (oldPrice != null && oldPrice > price) {
      discountPercent = ((oldPrice - price) / oldPrice * 100).round();
    }

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (c, e, s) => Container(
                        color: theme.canvasColor,
                        child: Icon(
                          Icons.broken_image,
                          color: theme.iconTheme.color?.withOpacity(0.3),
                        ),
                      ),
                ),
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer,
                          size: 10,
                          color: theme.primaryColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product['main_category'] ?? 'Item',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.primaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // "More Details" Link
                  Text(
                    "More Details ↗",
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price Row
                  Text(
                    formatCurrency.format(price),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  // Old Price & Discount Row
                  if (oldPrice != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Text(
                            formatCurrency.format(oldPrice),
                            style: theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: theme.hintColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "-$discountPercent%",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$likes Likes",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${(views / 1000).toStringAsFixed(1)}k Views",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                        side: BorderSide(color: theme.dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        "VIEW PRODUCT",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
