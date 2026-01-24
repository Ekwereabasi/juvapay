import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_auth_service.dart';
import '../../services/wallet_service.dart';
import 'package:lottie/lottie.dart';
import 'product_upload.dart';

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

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    setState(() => _isLoading = true);

    try {
      // Check if user has active subscription
      _hasActiveSubscription = await _authService.hasActiveSubscription();

      // Get wallet balance
      final wallet = await _walletService.getWalletBalance();
      _walletBalance = wallet['balance'] as double;

      // If already has subscription, navigate to upload page
      if (_hasActiveSubscription) {
        _navigateToUpload();
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
      final result = await _authService.processAdvertPayment();

      if (result['success'] == true) {
        await _showSuccessAnimation();

        // Navigate to upload page
        _navigateToUpload();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Advert subscription activated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result['message'] == 'INSUFFICIENT_FUNDS') {
        // Show insufficient funds dialog
        _showInsufficientFundsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Payment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Insufficient Balance'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('You need ₦1,000 to activate advert subscription.'),
                const SizedBox(height: 10),
                Text('Current Balance: ₦${_walletBalance.toStringAsFixed(2)}'),
                Text('Required: ₦1,000.00'),
                Text('Deficit: ₦${(1000 - _walletBalance).toStringAsFixed(2)}'),
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
                  Navigator.pushNamed(context, '/fund-wallet');
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
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
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
                'Advert access activated',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToUpload() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MarketplaceUploadPage()),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Advertise With Us",
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: true,
        centerTitle: true,
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
                      errorBuilder:
                          (c, e, s) => Container(
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

                  // Wallet Balance Info
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Wallet Balance",
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.hintColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₦${_walletBalance.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/fund-wallet');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('ADD FUNDS'),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Advert Fee",
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
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
                  onPressed: _isProcessing ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child:
                      _isProcessing
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            "PAY & CONTINUE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
