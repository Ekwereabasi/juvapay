import 'package:flutter/material.dart';
import 'package:juvapay/services/supabase_auth_service.dart';
import 'package:juvapay/services/wallet_service.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.iconTheme,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Option 1: Social Tasks
            Expanded(
              child: _buildChoiceCard(
                context,
                title: "Perform Social Tasks and Earn Daily",
                description:
                    "Earn Daily by posting adverts of various businesses and performing tasks on your social media pages.",
                iconWidget: _buildSocialIcons(),
                onTap: () {
                  // TODO: Navigate to Social Tasks List
                },
              ),
            ),
            const SizedBox(width: 12),
            // Option 2: Reselling
            Expanded(
              child: _buildChoiceCard(
                context,
                title: "Resell Products and Earn Big Commissions",
                description:
                    "Resell products of top sellers and brands and earn up to ₦100,000 monthly in sales commissions.",
                iconWidget: const Icon(
                  Icons.payments_outlined,
                  size: 50,
                  color: Colors.green,
                ),
                onTap: () {
                  // TODO: Navigate to Marketplace Page
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
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
            ),
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

// --- MAIN EARN VIEW ---
class EarnView extends StatefulWidget {
  const EarnView({super.key});

  @override
  State<EarnView> createState() => _EarnViewState();
}

class _EarnViewState extends State<EarnView> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final WalletService _walletService = WalletService();
  bool _isLoading = true;
  bool _isMember = false;
  Map<String, dynamic>? _walletData;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _authService.fetchUserProfile(),
        _walletService.getWalletBalance(),
      ]);

      if (mounted) {
        setState(() {
          final profile = results[0] as Map<String, dynamic>?;
          _isMember = profile?['is_member'] ?? false;
          _walletData = results[1] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- PAYMENT LOGIC ---
  Future<void> _processExternalPayment() async {
    setState(() => _isLoading = true);
    try {
      final userProfile = await _authService.fetchUserProfile();
      final user = Supabase.instance.client.auth.currentUser;

      final String txRef = "MEM-${const Uuid().v4()}";
      const double membershipFee = 1000.0;

      final Customer customer = Customer(
        name: userProfile?['full_name'] ?? "User",
        phoneNumber: userProfile?['phone_number'] ?? "0000000000",
        email: user?.email ?? userProfile?['email'] ?? "user@example.com",
      );

      final Flutterwave flutterwave = Flutterwave(
        publicKey: "FLWPUBK_TEST-6d3f26fb4ec53ac62c9ed8674a570ba7-X",
        redirectUrl: "https://callbacks.flutterwave.com/v3/redirects",
        currency: "NGN",
        txRef: txRef,
        amount: membershipFee.toString(),
        customer: customer,
        paymentOptions: "card, banktransfer, ussd",
        customization: Customization(
          title: "Membership Activation",
          description: "One-time registration fee",
          logo:
              "https://hdaxtvyvrnqhoghzfixx.supabase.co/storage/v1/object/public/assest/logo.png",
        ),
        isTestMode: true,
      );

      final ChargeResponse response = await flutterwave.charge(context);

      if (response.success == true && response.status == "successful") {
        try {
          // Payment succeeded on gateway, now record in Supabase using WalletService
          await _walletService.recordFinancialTransaction(
            amount: membershipFee,
            type: 'MEMBERSHIP_PAYMENT',
            status: 'COMPLETED',
            description: 'Membership paid via Flutterwave',
            referenceId: response.transactionId ?? txRef,
            gatewayResponse: response.toJson(),
          );

          // Short delay to allow database triggers to complete
          await Future.delayed(const Duration(seconds: 1));

          _showSnackBar("Membership Activated!", isError: false);

          // Refresh data to show the EarnSelectionView
          await _loadInitialData();
        } catch (dbError) {
          debugPrint("Database Recording Error: $dbError");
          _showErrorDialog(
              "Payment successful, but membership activation failed. Please contact support with Ref: ${response.transactionId ?? txRef}");
        }
      } else {
        _showSnackBar("Payment was not successful or was cancelled.",
            isError: true);
      }
    } catch (e) {
      debugPrint("Payment Error: $e");
      _showErrorDialog("Payment Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleWalletPayment() async {
    const double fee = 1000.0;
    final balance = (_walletData?['balance'] as double?) ?? 0.0;
    
    if (balance < fee) {
      _showErrorDialog("Insufficient wallet balance.");
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      // Record the SPEND transaction
      await _walletService.recordFinancialTransaction(
        amount: fee,
        type: 'SPEND',
        status: 'COMPLETED',
        description: 'Membership Activation Fee',
      );

      // Record the MEMBERSHIP_PAYMENT transaction
      await _walletService.recordFinancialTransaction(
        amount: fee,
        type: 'MEMBERSHIP_PAYMENT',
        status: 'COMPLETED',
        description: 'Membership Activated',
      );

      _showSnackBar("Activated via Wallet!", isError: false);
      await _loadInitialData();
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPaymentOptions() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Select Payment Method",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.lock,
                color: theme.primaryColor,
                size: 30,
              ),
              title: const Text("Secure Online Payment"),
              subtitle: Text(
                "Card, Transfer, or USSD",
                style: TextStyle(color: theme.hintColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _processExternalPayment();
              },
            ),
            Divider(color: theme.dividerColor),
            ListTile(
              leading: Icon(
                Icons.wallet,
                color: theme.primaryColor,
                size: 30,
              ),
              title: const Text("Pay with Wallet"),
              subtitle: Text(
                "Balance: ₦${(_walletData?['balance'] as double?)?.toStringAsFixed(0) ?? '0'}",
                style: TextStyle(color: theme.hintColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleWalletPayment();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }

    if (_isMember) {
      return const EarnSelectionView();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Become a Member",
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: theme.iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "Turn Your Social Media Accounts into a Money Making Machine!",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            _buildBenefitItem(
              "Earn steady daily income by performing social tasks.",
              theme,
            ),
            _buildBenefitItem(
              "Earn ₦500 instant commission for every referral.",
              theme,
            ),
            const SizedBox(height: 30),
            _buildTermsBox(theme),
          ],
        ),
      ),
      bottomNavigationBar: _buildPaymentBar(theme),
    );
  }

  Widget _buildBenefitItem(String text, ThemeData theme) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
              ),
            ),
          ],
        ),
      );

  Widget _buildTermsBox(ThemeData theme) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
        ),
        child: Text(
          "Terms: One-time fee. No hidden charges. 24-48hr withdrawals.",
          textAlign: TextAlign.center,
          style:
              TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w500),
        ),
      );

  Widget _buildPaymentBar(ThemeData theme) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Membership Fee",
                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                ),
                Text(
                  "₦1,000",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: _showPaymentOptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "CLICK TO PAY",
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

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Notice"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? theme.colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}