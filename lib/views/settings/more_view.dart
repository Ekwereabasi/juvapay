import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/more_view_model.dart';
import '../../services/theme_service.dart';

// Subpage Imports
import 'subpages/edit_profile_view.dart';
import 'subpages/fund_wallet_view.dart';
import 'subpages/transaction_history_view.dart';
import 'subpages/order/my_orders_view.dart';
import 'subpages/update_password_view.dart';
import 'subpages/update_location_view.dart';
import 'subpages/update_bank_details_view.dart';
import 'subpages/place_withdrawal_view.dart';
import 'subpages/notifications/notifications_screen.dart';
import 'subpages/privacy_policy_view.dart';
import 'subpages/about_view.dart';
import 'subpages/terms_of_use_view.dart';
import 'subpages/chat_with_support_view.dart';

class MoreView extends StatelessWidget {
  const MoreView({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes from the parent/global provider
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => MoreViewModel(themeService),
      child: Consumer2<MoreViewModel, ThemeService>(
        builder: (context, viewModel, themeProvider, child) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              title: const Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: false,
              automaticallyImplyLeading: false,
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: 16.0,
                    top: 8,
                    bottom: 8,
                  ),
                  child: TextButton(
                    onPressed:
                        viewModel.isLoading
                            ? null
                            : () => viewModel.logout(context),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isDark
                              ? Colors.red.withOpacity(0.2)
                              : Colors.red.shade50,
                      foregroundColor:
                          isDark ? Colors.red.shade300 : Colors.red.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        viewModel.isLoading
                            ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.red,
                                ),
                              ),
                            )
                            : const Text(
                              'Logout',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, viewModel),
                  Divider(height: 32, thickness: 1, color: theme.dividerColor),

                  _buildSectionTitle(context, 'Account & Finance'),
                  _buildListItem(
                    context,
                    icon: Icons.list_alt,
                    title: 'My Orders',
                    targetView: const OrderHistoryView(),
                  ),
                  _buildListItem(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Fund Wallet',
                    targetView: const FundWalletScreen(),
                  ),
                  _buildListItem(
                    context,
                    icon: Icons.account_balance_outlined,
                    title: 'Place Withdrawals',
                    targetView: const WithdrawView(),
                  ),
                  _buildListItem(
                    context,
                    icon: Icons.history,
                    title: 'Transaction History',
                    targetView: const TransactionHistoryPage(),
                  ),

                  _buildListItem(
                    context,
                    icon: Icons.notifications_none,
                    title: 'My Notifications',
                    targetView: const NotificationsScreen(),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: theme.dividerColor),
                  ),

                  _buildSectionTitle(context, 'Profile & Security'),
                  _buildListItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    targetView: const EditProfileView(),
                  ),
                  _buildListItem(
                    context,
                    icon: Icons.lock_outline,
                    title: 'Update Password',
                    targetView: const UpdatePasswordView(),
                  ),
                  _buildListItem(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Update Location',
                    targetView: const UpdateLocationScreen(),
                  ),
                  _buildListItem(
                    context,
                    icon: Icons.credit_card_outlined,
                    title: 'Update Bank Details',
                    targetView: const UpdateBankDetailsPage(),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: theme.dividerColor),
                  ),

                  _buildSectionTitle(context, 'Appearance & Support'),
                  _buildThemeToggle(context, themeProvider),
                  _buildListItem(
                    context,
                    icon: Icons.support_agent,
                    title: 'Chat With Support',
                    targetView: const SupportPage(),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: theme.dividerColor),
                  ),

                  _buildSectionTitle(context, 'Legal & Information'),
                  _buildListItem(
                    context,
                    icon: Icons.security_outlined,
                    title: 'Privacy Policy',
                    targetView: const PrivacyPolicyView(),
                  ),
                  _buildListItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'About JuvaPay',
                    targetView: const AboutView(),
                  ),
                  _buildListItem(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Terms of Use',
                    targetView: const TermsOfUseView(),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildProfileHeader(BuildContext context, MoreViewModel viewModel) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            backgroundImage:
                (viewModel.profileUrl != null &&
                        viewModel.profileUrl!.isNotEmpty)
                    ? NetworkImage(viewModel.profileUrl!)
                    : null,
            child:
                (viewModel.profileUrl == null || viewModel.profileUrl!.isEmpty)
                    ? Text(
                      viewModel.fullName.isNotEmpty
                          ? viewModel.fullName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${viewModel.username}',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap:
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileView(),
                        ),
                      ),
                  child: Text(
                    'Edit Profile Settings',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget targetView,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 22, color: theme.iconTheme.color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: theme.disabledColor,
      ),
      onTap:
          () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => targetView)),
    );
  }

  // 🟢 UPDATED: Much cleaner dropdown logic ensuring clicks work
  Widget _buildThemeToggle(BuildContext context, ThemeService themeService) {
    final theme = Theme.of(context);
    final currentTheme = themeService.themeMode;

    // Get icon based on current theme
    IconData getThemeIcon() {
      switch (currentTheme) {
        case ThemeMode.light:
          return Icons.light_mode;
        case ThemeMode.dark:
          return Icons.dark_mode;
        case ThemeMode.system:
          return Icons.brightness_auto;
      }
    }

    return ListTile(
      leading: Icon(getThemeIcon(), color: theme.iconTheme.color),
      title: Text(
        'Theme Mode',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      // Simplified trailing widget for better hit testing
      trailing: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ThemeMode>(
            value: currentTheme,
            icon: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.arrow_drop_down,
                color: theme.primaryColor,
                size: 20,
              ),
            ),
            elevation: 4,
            dropdownColor: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primaryColor,
            ),
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                themeService.setThemeMode(newMode);
              }
            },
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
          ),
        ),
      ),
    );
  }
}
