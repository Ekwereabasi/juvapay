import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:juvapay/services/supabase_auth_service.dart';
import 'package:juvapay/services/wallet_service.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:juvapay/views/market/marketplace_upload_page.dart';
import 'package:juvapay/views/settings/subpages/fund_wallet_view.dart';
import 'package:juvapay/utils/transaction_context.dart';

class AdvertPaymentView extends StatefulWidget {
  const AdvertPaymentView({super.key});

  @override
  State<AdvertPaymentView> createState() => _AdvertPaymentViewState();
}

class _AdvertPaymentViewState extends State<AdvertPaymentView> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final WalletService _walletService = WalletService();

  bool _isLoading = true;
  bool _hasActiveSubscription = false;
  bool _isProcessing = false;

  double _walletBalance = 0.0;
  double _availableBalance = 0.0;
  StreamSubscription? _walletStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeWalletStream();
    _checkSubscription();
  }

  @override
  void dispose() {
    _walletStreamSubscription?.cancel();
    super.dispose();
  }

  void _initializeWalletStream() {
    try {
      _walletStreamSubscription = _walletService.getWalletStream().listen(
        (walletData) {
          if (mounted) {
            setState(() {
              _walletBalance = walletData['current_balance'] ?? 0.0;
              _availableBalance = walletData['available_balance'] ?? 0.0;
            });
          }
        },
        onError: (error) {
          debugPrint('Error in wallet stream: $error');
        },
      );
    } catch (e) {
      debugPrint('Error initializing wallet stream: $e');
    }
  }

  Future<void> _checkSubscription() async {
    setState(() => _isLoading = true);

    try {
      final subscription = await _walletService.checkAdvertSubscription();
      _hasActiveSubscription = subscription['is_active'] == true;

      // If user already has active subscription, don't show this page
      if (_hasActiveSubscription && mounted) {
        _navigateToMarketplaceUpload();
      }
    } catch (e) {
      debugPrint('Error checking subscription: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // First check balance
      final balanceCheck = await _walletService.checkBalance(1000.0);

      if (balanceCheck['hasSufficientBalance'] == true) {
        // Show confirmation dialog similar to membership page
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Advert Payment'),
            content: const Text(
              'You will be charged ₦1000 for 1 month advert subscription. Do you want to proceed?',
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

        if (confirmed != true) {
          setState(() => _isProcessing = false);
          return;
        }

        // Process advert payment
        final txContext = await TransactionContext.fetch();
        final result = await _walletService.processAdvertPayment(
          ipAddress: txContext.ipAddress,
          userAgent: txContext.userAgent,
          deviceId: txContext.deviceId,
          location: txContext.location,
        );

        if (result['success'] == true) {
          // Show success animation and navigate
          await _showSuccessAnimation();
          
          // Navigate to MarketplaceUploadPage after successful payment
          if (mounted) {
            _navigateToMarketplaceUpload();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Show insufficient funds dialog
        _showInsufficientFundsDialog(
          currentBalance: balanceCheck['currentBalance'] as double,
          availableBalance: balanceCheck['availableBalance'] as double,
          deficit: balanceCheck['deficit'] as double,
          isWalletLocked: balanceCheck['isWalletLocked'] as bool,
        );
      }
    } catch (e) {
      debugPrint('Payment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _navigateToMarketplaceUpload() {
    // Use push instead of pushReplacement to avoid context issues
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MarketplaceUploadPage()),
    );
  }

  void _showInsufficientFundsDialog({
    required double currentBalance,
    required double availableBalance,
    required double deficit,
    required bool isWalletLocked,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWalletLocked)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your wallet is currently locked. Please contact support.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            if (isWalletLocked) const SizedBox(height: 10),
            const Text('You need ₦1,000 to activate advert subscription.'),
            const SizedBox(height: 10),
            Text('Current Balance: ₦${currentBalance.toStringAsFixed(2)}'),
            Text(
              'Available Balance: ₦${availableBalance.toStringAsFixed(2)}',
            ),
            Text('Required: ₦1,000.00'),
            Text('Deficit: ₦${deficit.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToFundWallet(context);
            },
            child: const Text('FUND WALLET'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessAnimation() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animations/success.json',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Redirecting to product upload...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToFundWallet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FundWalletScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If user already has active subscription, navigate directly
    if (_hasActiveSubscription) {
      // This will be caught by initState and redirected
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Advertise With Us",
          style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 0,
        automaticallyImplyLeading: true,
        centerTitle: true,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actionsIconTheme: Theme.of(context).appBarTheme.actionsIconTheme,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      "https://hdaxtvyvrnqhoghzfixx.supabase.co/storage/v1/object/public/assest/advertdiscription1.jpg",
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 180,
                        color: theme.cardColor,
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: theme.disabledColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Title
                  Center(
                    child: Text(
                      "Sell Anything Faster On Juvapay Market",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Description
                  Text(
                    "Place your products in front of thousands of daily users. Benefits include:",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Benefits List
                  _buildBenefitRow(
                    Icons.trending_up_rounded,
                    "High Advert Views",
                    "Massive daily traffic for your items.",
                    theme,
                  ),
                  _buildBenefitRow(
                    Icons.campaign_rounded,
                    "Social Media Adverts",
                    "We promote to Facebook & Instagram.",
                    theme,
                  ),
                  _buildBenefitRow(
                    Icons.forum_rounded,
                    "Direct Buyer Contact",
                    "Buyers contact you via WhatsApp.",
                    theme,
                  ),
                  _buildBenefitRow(
                    Icons.savings_rounded,
                    "Low Advert Cost",
                    "Only ₦1,000 per month.",
                    theme,
                  ),

                  const SizedBox(height: 20),

                  // Duration Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ADVERT DURATION: 1 MONTH",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Your advert is valid for 30 days. Auto-renews from wallet balance.",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Real-time Wallet Balance Info
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Your Wallet (Live)",
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.hintColor,
                              ),
                            ),
                            Icon(
                              Icons.refresh,
                              size: 16,
                              color: theme.primaryColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Balance",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.hintColor,
                                  ),
                                ),
                                Text(
                                  "₦${_walletBalance.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Available",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.hintColor,
                                  ),
                                ),
                                Text(
                                  "₦${_availableBalance.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _availableBalance >= 1000
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_availableBalance < 1000)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Add ₦${(1000 - _availableBalance).toStringAsFixed(2)} more to proceed',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _navigateToFundWallet(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('ADD FUNDS TO WALLET'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Payment Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_availableBalance < 1000)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Insufficient available balance',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Advert Fee",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.hintColor,
                          ),
                        ),
                        Text(
                          "₦1,000",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () async {
                              final balanceCheck = await _walletService
                                  .checkBalance(1000.0);
                              if (balanceCheck['isWalletLocked'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Your wallet is locked. Please contact support.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else if (balanceCheck['hasSufficientBalance'] ==
                                  true) {
                                _processPayment();
                              } else {
                                _showInsufficientFundsDialog(
                                  currentBalance:
                                      balanceCheck['currentBalance'] as double,
                                  availableBalance: balanceCheck[
                                      'availableBalance'] as double,
                                  deficit: balanceCheck['deficit'] as double,
                                  isWalletLocked: false,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _availableBalance >= 1000
                            ? theme.primaryColor
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _availableBalance >= 1000
                                  ? "PAY & CONTINUE"
                                  : "INSUFFICIENT BALANCE",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(
    IconData icon,
    String title,
    String desc,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor),
              color: theme.cardColor,
            ),
            child: Icon(icon, color: theme.primaryColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  desc,
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
