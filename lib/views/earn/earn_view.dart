// earn_view.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:juvapay/services/supabase_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:juvapay/view_models/wallet_view_model.dart';

// Import other pages
import 'earn_membership_view.dart';
import 'earn_selection_dialog.dart';
import '../../views/market/market_view.dart';
import 'earn_task_view.dart'; 
import '../../views/settings/subpages/fund_wallet_view.dart';

class EarnView extends StatefulWidget {
  const EarnView({super.key});

  @override
  State<EarnView> createState() => _EarnViewState();
}

class _EarnViewState extends State<EarnView> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  bool _isMember = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _authService.getUserProfile();
      setState(() {
        _userProfile = profile;
        _isMember = profile?['is_member'] == true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletViewModel = Provider.of<WalletViewModel>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If user is NOT a member, show membership page
    if (!_isMember) {
      return EarnMembershipView(
        onBecomeMember: () {
          _processMembershipPayment(walletViewModel);
        },
      );
    }

    // If user IS a member, show the selection dialog
    return _buildMemberView(context);
  }

  Widget _buildMemberView(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Earn Money",
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome message
              Text(
                "Welcome to Juvapay Earnings!",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                "Choose how you want to earn money today",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Start Earning Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _showEarnSelectionDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "START EARNING",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  void _showEarnSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => EarnSelectionDialog(
            onMarketSelected: () {
              Navigator.pop(context);
              _navigateToMarketView(context);
            },
            onTaskSelected: () {
              Navigator.pop(context);
              _navigateToTaskView(context);
            },
          ),
    );
  }

  void _navigateToMarketView(BuildContext context) {
    // Navigate to market view
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MarketView()),
    );
  }

  void _navigateToTaskView(BuildContext context) {
    // Navigate to task view (with all task features)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EarnTaskView()),
    );
  }

  Future<void> _processMembershipPayment(
    WalletViewModel walletViewModel,
  ) async {
    const membershipFee = 1000.0;

    // Check balance
    final balanceCheck = await walletViewModel.checkBalance(membershipFee);

    if (!balanceCheck['hasSufficientBalance']) {
      _showInsufficientBalanceDialog(context);
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Membership'),
            content: const Text(
              'You will be charged ₦$membershipFee for membership. Do you want to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      // Process membership payment
      final result = await walletViewModel.processPayment(
        amount: membershipFee,
        transactionType: 'MEMBERSHIP_PAYMENT',
        description: 'Membership Registration',
      );

      if (result['success'] == true) {
        // Update user profile to mark as member
        await _updateUserToMember();

        // Refresh profile
        await _loadUserProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Juvapay Membership!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Payment failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserToMember() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return;

      final SupabaseClient _supabase = Supabase.instance.client;
      await _supabase
          .from('profiles')
          .update({
            'is_member': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating membership status: $e');
      rethrow;
    }
  }

  void _showInsufficientBalanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Insufficient Balance'),
            content: const Text(
              'You need at least ₦1000 to become a member. Please fund your wallet first.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _navigateToFundWallet(context);
                },
                child: const Text('Fund Wallet'),
              ),
            ],
          ),
    );
  }

  void _navigateToFundWallet(BuildContext context) {
    // Navigate to your FundWalletScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FundWalletScreen(), // Make sure this is imported
      ),
    );
  }
}
