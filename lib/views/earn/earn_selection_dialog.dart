// earn_selection_dialog.dart
import 'package:flutter/material.dart';

class EarnSelectionDialog extends StatelessWidget {
  final VoidCallback onMarketSelected;
  final VoidCallback onTaskSelected;

  const EarnSelectionDialog({
    super.key,
    required this.onMarketSelected,
    required this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              "How do you want to earn?",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              "Choose your preferred earning method",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Options Row
            Row(
              children: [
                // Market Option
                Expanded(
                  child: _buildOptionCard(
                    context,
                    title: "Earn with Market",
                    description: "Trade and invest in the market",
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                    onTap: onMarketSelected,
                  ),
                ),

                const SizedBox(width: 16),

                // Task Option
                Expanded(
                  child: _buildOptionCard(
                    context,
                    title: "Earn from Tasks",
                    description: "Complete social media tasks",
                    icon: Icons.task_alt,
                    color: Colors.green,
                    onTap: onTaskSelected,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),

            const SizedBox(height: 16),

            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              description,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
