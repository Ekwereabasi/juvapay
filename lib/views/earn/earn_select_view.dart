// earn_selection_view.dart
import 'package:flutter/material.dart';

import '../../../services/task_service.dart';
import 'task_execution_view.dart';
import 'worker_statistics_view.dart';
import 'worker_task_history_view.dart';
import 'worker_task_list_view.dart';

// --- EARN SELECTION VIEW (THE DIALOG PAGE) ---
class EarnSelectionView extends StatelessWidget {
  const EarnSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "How do you want to earn today?",
          style: Theme.of(
            context,
          ).appBarTheme.titleTextStyle?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actionsIconTheme: Theme.of(context).appBarTheme.actionsIconTheme,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Option 1: Perform Social Tasks
            Expanded(
              child: _buildChoiceCard(
                context,
                title: "Perform Social Tasks and Earn Daily",
                description:
                    "Complete social media tasks like posting adverts, following accounts, liking posts, and more. Get paid instantly for each completed task.",
                iconWidget: _buildSocialIcons(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerTaskListView(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Option 2: View Task Statistics
            Expanded(
              child: _buildChoiceCard(
                context,
                title: "View Your Earnings & Statistics",
                description:
                    "Check your task completion history, earnings, success rate, and available payouts. Track your performance as a social media worker.",
                iconWidget: const Icon(
                  Icons.analytics_outlined,
                  size: 50,
                  color: Colors.blue,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerStatisticsView(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard(
    BuildContext context, {
    required String title,
    required String description,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(height: 60, child: Center(child: iconWidget)),
          const SizedBox(height: 20),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.dividerColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "GET STARTED",
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcons() {
    return const Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        Icon(Icons.facebook, color: Colors.blue),
        Icon(Icons.camera_alt, color: Colors.pink),
        Icon(Icons.chat_bubble, color: Colors.green),
        Icon(Icons.alternate_email, color: Colors.lightBlue),
      ],
    );
  }
}
