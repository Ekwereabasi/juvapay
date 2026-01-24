// views/home/home_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/home_view_model.dart';
import '../../models/task_models.dart';
import '../../services/wallet_service.dart'; // Add this import for Transaction class
import '../../widgets/offline_indicator.dart';
import '../../services/cache_service.dart';
import '../../services/network_service.dart';
import '../../widgets/notification_bell.dart';

// Subpage Imports
import '../../views/settings/subpages/edit_profile_view.dart';
import '../../views/settings/subpages/chat_with_support_view.dart';
import '../../views/settings/subpages/fund_wallet_view.dart';
import '../../views/settings/subpages/place_withdrawal_view.dart';
import '../../views/earn/earn_select_view.dart';
import '../../views/advertise/advert_upload_page.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  // Method to show the view as a draggable dialog
  void _showEarnSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8, // 80% of screen height initially
            minChildSize: 0.5, // Minimum 50% of screen height
            maxChildSize: 0.9, // Maximum 90% of screen height
            expand: false, // Don't expand to fill entire screen
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle (visual only)
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // Close button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        padding: const EdgeInsets.only(right: 8),
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Your content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EarnSelectionView(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryPurple = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    return ChangeNotifierProvider(
      create:
          (_) => HomeViewModel(
            cacheService: context.read<CacheService>(),
            networkService: context.read<NetworkService>(),
          ),
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Get wallet data properly
          final wallet = viewModel.walletAsMap;
          final currentBalance = wallet['balance'] ?? 0.0;
          final totalEarned = wallet['totalEarned'] ?? 0.0;
          final lockedBalance = wallet['locked_balance'] ?? 0.0;
          final totalSpent = wallet['total_spent'] ?? 0.0;
          final formattedBalance = wallet['formattedBalance'] ?? '₦0.00';
          final formattedAvailableBalance =
              wallet['formattedAvailableBalance'] ?? '₦0.00';

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: _buildAppBar(context, viewModel, primaryPurple),
            body: Column(
              children: [
                OfflineIndicator(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => await viewModel.refreshAll(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBalanceSection(
                            context,
                            viewModel,
                            currentBalance,
                            formattedBalance,
                            primaryPurple,
                          ),
                          _buildStatsRow(
                            context,
                            totalEarned,
                            lockedBalance,
                            totalSpent,
                          ),
                          Divider(thickness: 8, color: dividerColor),
                          _buildWelcomeSection(
                            context,
                            viewModel,
                            primaryPurple,
                          ),
                          Divider(thickness: 8, color: dividerColor),
                          _buildAvailableTasksHeader(context, viewModel),
                          ...viewModel.tasks
                              .take(3)
                              .map(
                                (task) =>
                                    _buildTaskItem(context, viewModel, task),
                              )
                              .toList(),
                          if (viewModel.tasks.length > 3)
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed:
                                      () =>
                                          viewModel.navigateToAllTasks(context),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: primaryPurple),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    'VIEW ALL TASKS (${viewModel.tasks.length})',
                                    style: TextStyle(color: primaryPurple),
                                  ),
                                ),
                              ),
                            ),
                          Divider(thickness: 8, color: dividerColor),
                          _buildRecentTransactionsSection(
                            context,
                            viewModel,
                            formattedAvailableBalance,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    HomeViewModel viewModel,
    Color primaryColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black87;

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          SizedBox(
            height: 32,
            width: 32,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) =>
                      Icon(Icons.account_balance_wallet, color: primaryColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'JuvaPay',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: iconColor),
          onPressed: () => viewModel.refreshAll(force: true),
        ),
        IconButton(
          icon: Icon(Icons.help_outline, color: iconColor),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportPage()),
              ),
        ),
        NotificationBell(iconColor: iconColor),
        Padding(
          padding: const EdgeInsets.only(right: 20.0, left: 8.0),
          child: InkWell(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileView(),
                  ),
                ),
            borderRadius: BorderRadius.circular(18),
            child: CircleAvatar(
              radius: 18,
              backgroundImage:
                  viewModel.profilePictureUrl != null
                      ? NetworkImage(viewModel.profilePictureUrl!)
                      : null,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child:
                  viewModel.profilePictureUrl == null
                      ? Text(
                        viewModel.fullName.isNotEmpty
                            ? viewModel.fullName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSection(
    BuildContext context,
    HomeViewModel viewModel,
    double currentBalance,
    String formattedBalance,
    Color primaryColor,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Welcome, ${viewModel.fullName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (viewModel.isOffline)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, size: 12, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'My Balance',
            style: TextStyle(
              color: theme.textTheme.bodySmall?.color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            formattedBalance,
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FundWalletScreen(),
                        ),
                      ),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text(
                    "FUND",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WithdrawView(),
                        ),
                      ),
                  icon: Icon(
                    Icons.arrow_downward,
                    size: 18,
                    color: primaryColor,
                  ),
                  label: Text(
                    "WITHDRAW",
                    style: TextStyle(color: primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    double totalEarned,
    double lockedBalance,
    double totalSpent,
  ) {
    // Helper method to format currency - this is needed because viewModel isn't available here
    String formatCurrency(double amount) => '₦${amount.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildColorfulStat(
            context,
            icon: Icons.savings_outlined,
            color: Colors.green,
            label: "Total Earnings",
            amount: totalEarned,
            formatCurrency: formatCurrency,
          ),
          _buildColorfulStat(
            context,
            icon: Icons.hourglass_top_outlined,
            color: Colors.orange,
            label: "Pending Balance",
            amount: lockedBalance,
            formatCurrency: formatCurrency,
          ),
          _buildColorfulStat(
            context,
            icon: Icons.receipt_long_outlined,
            color: Colors.blue,
            label: "Amount Spent",
            amount: totalSpent,
            formatCurrency: formatCurrency,
          ),
        ],
      ),
    );
  }

  Widget _buildColorfulStat(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required double amount,
    required String Function(double) formatCurrency,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatCurrency(amount),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(
    BuildContext context,
    HomeViewModel viewModel,
    Color primaryColor,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome to JuvaPay",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            "Please select what you want to do on JuvaPay today",
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 30),
          const Text(
            "For Advertisers",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          const Text(
            "Buy Social Media Engagements",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdvertUploadPage(),
                    ),
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "GET STARTED NOW",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            "For Earners",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          const Text(
            "Get Paid for Posting Adverts",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showEarnSelectionDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "BECOME A MEMBER",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTasksHeader(
    BuildContext context,
    HomeViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Available Tasks",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (viewModel.tasks.isNotEmpty)
                Chip(
                  label: Text('${viewModel.tasks.length} tasks'),
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "See our currently available tasks below.",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    HomeViewModel viewModel,
    TaskModel task,
  ) {
    final platforms = task.platforms;
    final category = task.category;

    return InkWell(
      onTap: () => viewModel.navigateToTaskDetails(context, task),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: viewModel.getTaskCategoryColor(category),
                shape: BoxShape.circle,
              ),
              child: Icon(
                viewModel.getTaskCategoryIcon(category),
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              category == 'advert' ? Colors.blue : Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Price: ${viewModel.formatCurrency(task.price)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...platforms
                          .take(3)
                          .map(
                            (platform) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                viewModel.getPlatformIcon(platform),
                                size: 16,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                      if (platforms.length > 3)
                        Text(
                          '+${platforms.length - 3} more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
    BuildContext context,
    HomeViewModel viewModel,
    String formattedAvailableBalance,
  ) {
    final recentTransactions = viewModel.recentTransactions;
    if (recentTransactions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 5),
          child: Text(
            "Recent Transactions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your recent financial activities",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Available: $formattedAvailableBalance",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...recentTransactions.map(
          (transaction) =>
              _buildTransactionTile(context, transaction, viewModel),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTransactionTile(
    BuildContext context,
    Transaction transaction,
    HomeViewModel viewModel,
  ) {
    final type = transaction.type;
    final amount = transaction.amount;
    final status = transaction.status;
    final description = transaction.description;
    final createdAt = transaction.createdAt;

    final statusColor = transaction.statusColor;
    final statusText = transaction.statusText;
    final formattedAmount = transaction.formattedAmount;
    final formattedDate = transaction.formattedDate;
    final formattedTime = transaction.formattedTime;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            radius: 18,
            child: Icon(
              viewModel.getTransactionIcon(type),
              size: 20,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        viewModel.formatTransactionType(type),
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.1),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedAmount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: viewModel.getTransactionColor(type),
                ),
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
