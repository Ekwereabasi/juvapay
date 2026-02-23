// views/home/home_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:juvapay/services/supabase_auth_service.dart';
import 'package:juvapay/services/task_service.dart';
import '../../view_models/home_view_model.dart';
import '../../services/wallet_service.dart';
import '../../widgets/offline_indicator.dart';
import '../../services/cache_service.dart';
import '../../services/network_service.dart';
import '../../widgets/notification_bell.dart';

// Subpage Imports
import '../../views/settings/subpages/edit_profile_view.dart';
import '../../views/settings/subpages/chat_with_support_view.dart';
import '../../views/settings/subpages/fund_wallet_view.dart';
import '../../views/settings/subpages/place_withdrawal_view.dart';
import '../../views/earn/earn_view.dart';
import '../../views/advertise/advert_upload_page.dart';
import '../../views/earn/task_execution_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});
  static final SupabaseAuthService _authService = SupabaseAuthService();
  static final TaskService _taskService = TaskService();
  static final WalletService _walletService = WalletService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryPurple = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) => HomeViewModel(
                cacheService: context.read<CacheService>(),
                networkService: context.read<NetworkService>(),
              ),
        ),
      ],
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final walletMap = viewModel.walletAsMap;
          double toDouble(dynamic value) {
            if (value is num) return value.toDouble();
            return 0.0;
          }

          return StreamBuilder<Wallet>(
            stream: _walletService.watchWallet(),
            builder: (context, walletSnapshot) {
              final realtimeWallet = walletSnapshot.data;
              final currentBalance =
                  realtimeWallet?.currentBalance ??
                  toDouble(walletMap['balance']);
              final totalEarned =
                  realtimeWallet?.totalEarned ??
                  toDouble(walletMap['totalEarned']);
              final lockedBalance =
                  realtimeWallet?.lockedBalance ??
                  toDouble(walletMap['locked_balance']);
              final totalSpent =
                  realtimeWallet?.totalSpent ??
                  toDouble(walletMap['total_spent']);
              final formattedBalance =
                  realtimeWallet?.formattedBalance ??
                  walletMap['formattedBalance']?.toString() ??
                  '₦0.00';
              final formattedAvailableBalance =
                  realtimeWallet?.formattedAvailableBalance ??
                  walletMap['formattedAvailableBalance']?.toString() ??
                  '₦0.00';

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

                              // Show available tasks only for members
                              if (viewModel.isMember)
                                _buildAvailableTasksSection(context, viewModel),

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
          Text(
            viewModel.isMember
                ? "Continue Earning with Tasks"
                : "Get Paid for Posting Adverts",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EarnView()),
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                viewModel.isMember ? "EARN NOW" : "BECOME A MEMBER",
                style: const TextStyle(
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

  Widget _buildAvailableTasksSection(
    BuildContext context,
    HomeViewModel viewModel,
  ) {
    final theme = Theme.of(context);

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
              if (viewModel.availableTasks.isNotEmpty)
                Chip(
                  label: Text('${viewModel.availableTasks.length} tasks'),
                  backgroundColor: theme.primaryColor.withOpacity(0.1),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Complete social media tasks and earn instantly",
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
          ),
        ),
        const SizedBox(height: 20),

        // Show limited tasks (3 max)
        ...viewModel.availableTasks
            .take(3)
            .map((task) => _buildTaskCard(context, task))
            .toList(),

        // View all button if there are more tasks
        if (viewModel.availableTasks.length > 3)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _navigateToTasks(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'VIEW ALL TASKS (${viewModel.availableTasks.length})',
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    final theme = Theme.of(context);
    final platform = task['platform']?.toString() ?? 'social';
    final payout = (task['payout_amount'] as num?)?.toDouble() ?? 0.0;
    final taskTitle = task['task_title']?.toString() ?? 'Social Media Task';

    return InkWell(
      onTap: () => _navigateToTaskDetails(context, task),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getPlatformColor(platform).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        _getPlatformIcon(platform),
                        color: _getPlatformColor(platform),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taskTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          platform.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₦${payout.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task['task_description']?.toString() ??
                    'Complete the social media task',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (task['requirements'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Requirements:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task['requirements'].toString(),
                      style: TextStyle(color: theme.hintColor, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _claimTask(context, task),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'CLAIM TASK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'x':
      case 'twitter':
        return Colors.black;
      case 'tiktok':
        return const Color(0xFF000000);
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'youtube':
        return const Color(0xFFFF0000);
      default:
        return Colors.blue;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'x':
      case 'twitter':
        return Icons.alternate_email;
      case 'tiktok':
        return Icons.music_note;
      case 'whatsapp':
        return Icons.chat;
      case 'youtube':
        return Icons.play_circle_filled;
      default:
        return Icons.link;
    }
  }

  void _navigateToTasks(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EarnView()),
    );
  }

  void _navigateToTaskDetails(BuildContext context, Map<String, dynamic> task) {
    // Navigate to task details or directly claim
    _claimTask(context, task);
  }

  Future<void> _claimTask(
    BuildContext context,
    Map<String, dynamic> task,
  ) async {
    final queueId = task['queue_id']?.toString();
    if (queueId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await _authService.claimTask(queueId);
    if (result['success'] != true) {
      final message = result['message']?.toString() ?? 'Failed to claim task';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return;
    }

    final assignmentId = result['assignment_id']?.toString();
    final details = await _taskService.getTaskExecutionDetails(
      assignmentId: assignmentId,
      queueId: queueId,
      fallbackTaskData: {
        ...task,
        'assignment_id': assignmentId,
        'queue_id': queueId,
      },
    );
    final taskData =
        details ??
        {...task, 'assignment_id': assignmentId, 'queue_id': queueId};

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskExecutionScreen(taskData: taskData),
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
              WalletService.getTransactionIcon(type),
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
                        WalletService.formatTransactionType(type),
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
                  color: transaction.isCredit ? Colors.green : Colors.red,
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
