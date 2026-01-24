import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:uuid/uuid.dart';
import 'package:lottie/lottie.dart';


import '../../../services/wallet_service.dart';
import '../../../services/supabase_auth_service.dart';

class FundWalletScreen extends StatefulWidget {
  const FundWalletScreen({super.key});

  @override
  State<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends State<FundWalletScreen> {
  final WalletService _walletService = WalletService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  late Future<Wallet> _walletFuture;
  late Future<List<Transaction>> _historyFuture;

  bool _isLoading = false;
  bool _isVerifying = false;
  bool _showHistory = false;

  String? _pendingFlwTransactionId;
  String? _pendingReferenceId;
  double? _pendingAmount;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_NG',
    symbol: '₦',
    decimalDigits: 0,
  );

  final List<double> _quickAmounts = [500, 1000, 2000, 5000, 10000, 20000];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _initializeData() {
    setState(() {
      _walletFuture = _walletService.getWallet();
      _historyFuture = _walletService.getTransactionHistory(
        types: ['DEPOSIT'],
        limit: 10,
      );
    });
  }

  void _setQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    _amountFocusNode.unfocus();
    setState(() {});
  }

  void _clearAmount() {
    _amountController.clear();
    setState(() {});
  }

  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();

    final amount = double.tryParse(_amountController.text.trim());

    // Validation
    if (amount == null || amount < 100) {
      _showSnackBar('Minimum deposit is ₦100', true);
      return;
    }

    if (amount > 1000000) {
      _showSnackBar('Maximum deposit is ₦1,000,000', true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get user profile
      final profile = await _authService.getUserProfile();
      final user = _authService.getCurrentUser();

      final txRef = const Uuid().v4();

      final userEmail = user?.email ?? 'user@example.com';
      final userName = profile?['full_name'] ?? 'User';
      final userPhone = profile?['phone_number'] ?? '08000000000';

      // Store pending transaction info
      _pendingReferenceId = txRef;
      _pendingAmount = amount;

      // Initialize Flutterwave
      final flutterwave = Flutterwave(
        publicKey: 'FLWPUBK_TEST-6d3f26fb4ec53ac62c9ed8674a570ba7-X',
        currency: 'NGN',
        amount: amount.toStringAsFixed(0),
        txRef: txRef,
        redirectUrl: 'https://your-redirect-url.com',
        isTestMode: true,
        paymentOptions: 'card, banktransfer, ussd',
        customer: Customer(
          name: userName,
          email: userEmail,
          phoneNumber: userPhone,
        ),
        customization: Customization(
          title: 'Fund Wallet',
          description: 'Wallet top-up',
          logo: 'https://your-logo-url.com/logo.png',
        ),
      );

      // Launch payment
      final response = await flutterwave.charge(context);

      debugPrint('Flutterwave Response: ${response.toJson()}');

      // Handle response
      if (response.transactionId == null) {
        if (response.status != 'cancelled') {
          _showSnackBar('Payment was cancelled', true);
        }
        _resetPending();
        return;
      }

      _pendingFlwTransactionId = response.transactionId!.toString();

      // Create gateway response
      final gatewayResponse = {
        'id': _pendingFlwTransactionId,
        'tx_ref': txRef,
        'amount': amount,
        'status': response.status,
        'currency': 'NGN',
        'created_at': DateTime.now().toIso8601String(),
        'customer': {'email': userEmail, 'name': userName, 'phone': userPhone},
      };

      // Process deposit in our system using the correct method name
      final depositResult = await _walletService.processDeposit(
        amount: amount,
        referenceId: txRef,
        gatewayResponse: gatewayResponse,
        ipAddress: null,
        userAgent: null,
        deviceId: null,
      );

      debugPrint('Deposit Result: $depositResult');

      if (depositResult['success'] == true) {
        final status = depositResult['status'];

        if (status == 'COMPLETED') {
          await _showSuccessAnimation();
          await _refreshAndShowSuccess(depositResult);
        } else if (status == 'PENDING') {
          _showSnackBar('Payment is pending. Verifying...', false);
          await _verifyTransaction(_pendingFlwTransactionId!);
        } else {
          _showSnackBar('Payment failed: $status', true);
          _resetPending();
        }
      } else {
        final error = depositResult['error'];
        if (error == 'DUPLICATE_REFERENCE' || error == 'TRANSACTION_EXISTS') {
          _showSnackBar(
            'Transaction already processed. Checking status...',
            false,
          );
          await _verifyTransaction(_pendingFlwTransactionId!);
        } else {
          _showSnackBar('Error: ${depositResult['message']}', true);
          _resetPending();
        }
      }
    } catch (e) {
      debugPrint('Payment Error: $e');
      _showSnackBar('Payment failed: ${e.toString()}', true);
      _resetPending();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyTransaction(String flwId) async {
    if (!mounted) return;

    setState(() => _isVerifying = true);

    try {
      final result = await _walletService.verifyFlutterwaveTransaction(flwId);

      if (result['verified'] == true) {
        if (result['status'] == 'COMPLETED') {
          await _showSuccessAnimation();
          await _refreshAndShowSuccess(result);
        } else if (result['status'] == 'PENDING') {
          _showSnackBar('Payment still pending. We will notify you.', false);
          // Schedule another check in 30 seconds
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) {
              _verifyTransaction(flwId);
            }
          });
        }
      } else {
        _showSnackBar(result['message'] ?? 'Verification failed', true);
        _resetPending();
      }
    } catch (e) {
      debugPrint('Verification Error: $e');
      _showSnackBar('Verification failed: ${e.toString()}', true);
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

 Future<void> _refreshAndShowSuccess(Map<String, dynamic> result) async {
    // Refresh data - remove await since _initializeData() doesn't return a Future
    _initializeData(); // No await needed

    // Show success message
    final currentBalance = result['currentBalance'] as double? ?? 0.0;
    final availableBalance = result['availableBalance'] as double? ?? 0.0;

    _showSnackBar(
      'Payment successful! Current balance: ${_currencyFormat.format(currentBalance)}',
      false,
      duration: const Duration(seconds: 4),
    );

    // Clear form
    _amountController.clear();
    _resetPending();
  }

  void _resetPending() {
    _pendingFlwTransactionId = null;
    _pendingReferenceId = null;
    _pendingAmount = null;
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
                'Success!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Payment completed successfully',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(
    String message,
    bool isError, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fund Wallet'),
        centerTitle: true,
        actions: [
          if (_isVerifying)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Verifying...',
                    style: TextStyle(fontSize: 12, color: theme.primaryColor),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _initializeData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Balance Card
              _buildWalletCard(theme, isDarkMode),
              const SizedBox(height: 30),

              // Amount Input
              _buildAmountInput(theme),
              const SizedBox(height: 20),

              // Quick Amounts
              _buildQuickAmounts(theme),
              const SizedBox(height: 30),

              // Fund Button
              _buildFundButton(theme),
              const SizedBox(height: 40),

              // History Header
              _buildHistoryHeader(theme),

              // History List
              if (_showHistory) _buildHistoryList(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(ThemeData theme, bool isDarkMode) {
    return FutureBuilder<Wallet>(
      future: _walletFuture,
      builder: (context, snapshot) {
        final wallet = snapshot.data;
        final currentBalance = wallet?.currentBalance ?? 0.0;
        final availableBalance = wallet?.availableBalance ?? 0.0;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isDarkMode
                      ? [
                        theme.primaryColor.withOpacity(0.9),
                        theme.primaryColor.withOpacity(0.7),
                      ]
                      : [
                        theme.primaryColor,
                        theme.primaryColor.withOpacity(0.8),
                      ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Balance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currencyFormat.format(currentBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Available: ${_currencyFormat.format(availableBalance)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (isLoading)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 40,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Min: ₦100 • Max: ₦1,000,000',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmountInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Amount',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '₦',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 24,
                        color: theme.hintColor.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                if (_amountController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: theme.hintColor),
                    onPressed: _clearAmount,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAmounts(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Amounts',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              _quickAmounts.map((amount) {
                final isSelected =
                    _amountController.text == amount.toStringAsFixed(0);
                return ElevatedButton(
                  onPressed: () => _setQuickAmount(amount),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isSelected ? theme.primaryColor : theme.cardColor,
                    foregroundColor:
                        isSelected ? Colors.white : theme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            isSelected
                                ? theme.primaryColor
                                : theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '₦${amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildFundButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
          shadowColor: theme.primaryColor.withOpacity(0.3),
        ),
        child:
            _isLoading
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'FUND WALLET',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildHistoryHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.history_rounded, color: theme.primaryColor, size: 22),
        const SizedBox(width: 10),
        Text(
          'Recent Deposits',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(
            _showHistory
                ? Icons.expand_less_rounded
                : Icons.expand_more_rounded,
            color: theme.primaryColor,
            size: 24,
          ),
          onPressed: () => setState(() => _showHistory = !_showHistory),
        ),
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: theme.primaryColor,
            size: 22,
          ),
          onPressed: _initializeData,
        ),
      ],
    );
  }

  Widget _buildHistoryList(ThemeData theme) {
    return FutureBuilder<List<Transaction>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CircularProgressIndicator(color: theme.primaryColor),
            ),
          );
        }

        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            margin: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: theme.hintColor.withOpacity(0.5),
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  'No deposits yet',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your deposit history will appear here',
                  style: TextStyle(
                    color: theme.hintColor.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder:
              (context, index) => Divider(
                color: theme.dividerColor.withOpacity(0.3),
                height: 1,
              ),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 8, top: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                title: Text(
                  _currencyFormat.format(transaction.amount),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy • h:mm a',
                      ).format(transaction.createdAt),
                      style: TextStyle(color: theme.hintColor, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (transaction.referenceId.isNotEmpty)
                      Text(
                        'Ref: ${transaction.referenceId.substring(0, 8)}...',
                        style: TextStyle(
                          color: theme.hintColor.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: transaction.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        transaction.status == 'COMPLETED'
                            ? Icons.check_circle_rounded
                            : transaction.status == 'FAILED'
                            ? Icons.error_rounded
                            : transaction.status == 'CANCELLED'
                            ? Icons.cancel_rounded
                            : Icons.pending_rounded,
                        color: transaction.statusColor,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        transaction.status.toLowerCase(),
                        style: TextStyle(
                          color: transaction.statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
