import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juvapay/services/supabase_auth_service.dart';
import 'package:juvapay/view_models/wallet_view_model.dart';
import 'update_bank_details_view.dart';
import 'withdrawal_history_view.dart';

class WithdrawView extends StatefulWidget {
  const WithdrawView({super.key});

  @override
  State<WithdrawView> createState() => _WithdrawViewState();
}

class _WithdrawViewState extends State<WithdrawView> {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  PackageInfo? _packageInfo;
  SharedPreferences? _prefs;

  // State Management
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, dynamic>? _bankDetails;

  // Rate limiting
  static const int _withdrawalCooldownHours = 1; // 1 hour cooldown
  static const int _maxWithdrawalsPerDay = 5; // Maximum withdrawals per day

  // Controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      await Future.wait([
        _initPackageInfo(),
        _initSharedPreferences(),
        _loadData(),
      ]);
    } catch (e) {
      print('Initialization error: $e');
      if (mounted) _showTopSnackbar('Failed to initialize: $e', isError: true);
    }
  }

  Future<void> _initPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Load bank details from Supabase
      final user = _authService.getCurrentUser();
      if (user != null) {
        final userProfile = await _authService.getUserProfile();
        if (userProfile != null && mounted) {
          setState(() {
            _bankDetails = {
              'account_number': userProfile['account_number'] ?? '',
              'account_name': userProfile['account_name'] ?? '',
              'bank_name': userProfile['bank_name'] ?? '',
              'bank_code': userProfile['bank_code'] ?? '',
            };
          });
        }
      }
    } catch (e) {
      if (mounted) _showTopSnackbar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkWithdrawalLimits() async {
    if (_prefs == null) return true;

    final now = DateTime.now();
    final lastWithdrawalTime = _prefs!.getInt('last_withdrawal_time') ?? 0;
    final withdrawalsToday = _prefs!.getInt('withdrawals_today') ?? 0;
    final lastResetDate = _prefs!.getString('withdrawals_reset_date') ?? '';

    // Reset daily counter if it's a new day
    final today = DateFormat('yyyy-MM-dd').format(now);
    if (lastResetDate != today) {
      await _prefs!.setInt('withdrawals_today', 0);
      await _prefs!.setString('withdrawals_reset_date', today);
      return true;
    }

    // Check daily limit
    if (withdrawalsToday >= _maxWithdrawalsPerDay) {
      _showTopSnackbar(
        'Daily withdrawal limit reached. Maximum $_maxWithdrawalsPerDay withdrawals per day.',
        isError: true,
      );
      return false;
    }

    // Check cooldown period
    final lastWithdrawal = DateTime.fromMillisecondsSinceEpoch(
      lastWithdrawalTime,
    );
    final hoursSinceLast = now.difference(lastWithdrawal).inHours;

    if (hoursSinceLast < _withdrawalCooldownHours) {
      final remainingHours = _withdrawalCooldownHours - hoursSinceLast;
      final remainingMinutes = (remainingHours * 60).ceil();

      _showTopSnackbar(
        'Please wait $remainingMinutes minutes before making another withdrawal.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  Future<void> _updateWithdrawalLimits() async {
    if (_prefs == null) return;

    final now = DateTime.now();
    await _prefs!.setInt('last_withdrawal_time', now.millisecondsSinceEpoch);

    final withdrawalsToday = _prefs!.getInt('withdrawals_today') ?? 0;
    await _prefs!.setInt('withdrawals_today', withdrawalsToday + 1);
  }

  Future<void> _handleWithdraw() async {
    // Check withdrawal limits
    final canWithdraw = await _checkWithdrawalLimits();
    if (!canWithdraw) return;

    final walletViewModel = context.read<WalletViewModel>();
    final amountText = _amountController.text.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );
    final double? amount = double.tryParse(amountText);
    final String password = _passwordController.text.trim();

    // Validate amount
    if (amount == null || amount <= 0) {
      _showTopSnackbar('Please enter a valid amount', isError: true);
      return;
    }

    if (amount < 100) {
      _showTopSnackbar('Minimum withdrawal amount is ₦100', isError: true);
      return;
    }

    // Check if user has sufficient balance using WalletViewModel
    final balanceCheck = await walletViewModel.checkBalance(amount);
    if (!balanceCheck['hasSufficientBalance']) {
      _showTopSnackbar(
        'Insufficient funds. Available balance: ₦${balanceCheck['availableBalance']?.toStringAsFixed(2) ?? '0.00'}',
        isError: true,
      );
      return;
    }

    if (password.isEmpty) {
      _showTopSnackbar('Please enter your password', isError: true);
      return;
    }

    // Verify password
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      _showTopSnackbar('User not authenticated', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Re-authenticate user with password
      final reauthResult = await _authService.signIn(
        email: currentUser.email ?? '',
        password: password,
      );

      if (!reauthResult['success']) {
        throw Exception('Invalid password. Please try again.');
      }

      // Prepare bank details for withdrawal
      final bankDetails = {
        'account_number': _bankDetails?['account_number'] ?? '',
        'account_name': _bankDetails?['account_name'] ?? '',
        'bank_name': _bankDetails?['bank_name'] ?? '',
        'bank_code': _bankDetails?['bank_code'] ?? '',
      };

      // Validate bank details
      final accountNumber = bankDetails['account_number']?.isEmpty ?? true;
      final accountName = bankDetails['account_name']?.isEmpty ?? true;
      final bankName = bankDetails['bank_name']?.isEmpty ?? true;

      if (accountNumber || accountName || bankName) {
        throw Exception(
          'Invalid bank details. Please update your bank information.',
        );
      }

      // Get actual IP address and user agent
      final ipAddress = await _getIpAddress();
      final userAgent = await _getUserAgent();

      // Store sensitive data securely
      await _secureStorage.write(key: 'last_withdrawal_ip', value: ipAddress);
      await _secureStorage.write(
        key: 'last_withdrawal_time',
        value: DateTime.now().toIso8601String(),
      );

      // Process withdrawal using WalletViewModel
      final result = await walletViewModel.processWithdrawal(
        amount: amount,
        bankDetails: bankDetails,
        description: 'Withdrawal to ${bankDetails['bank_name']}',
        ipAddress: ipAddress,
        userAgent: userAgent,
      );

      if (result['success'] == true) {
        if (mounted) {
          // Update withdrawal limits
          await _updateWithdrawalLimits();

          _showTopSnackbar(
            'Withdrawal request submitted successfully!',
            isError: false,
          );

          // Refresh wallet data
          await walletViewModel.refreshWalletData();

          // Clear form
          _amountController.clear();
          _passwordController.clear();

          // Close keyboard
          FocusScope.of(context).unfocus();

          // Show success dialog
          _showSuccessDialog(amount, result, bankDetails);
        }
      } else {
        throw Exception(result['message'] ?? 'Withdrawal failed');
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception:', '').trim();
      if (mounted) _showTopSnackbar(errorMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Get IP address using multiple fallback methods with better error handling
  Future<String> _getIpAddress() async {
    final fallbackUrls = [
      'https://api.ipify.org',
      'https://api64.ipify.org',
      'https://ipinfo.io/ip',
      'https://ifconfig.me/ip',
      'https://icanhazip.com',
    ];

    for (final url in fallbackUrls) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: {'Accept': 'text/plain'})
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final ip = response.body.trim();
          if (ip.isNotEmpty && _isValidIpAddress(ip)) {
            return ip;
          }
        }
      } catch (e) {
        print('IP fetch failed from $url: $e');
        continue;
      }
    }

    // If all methods fail, return timestamp-based unique identifier
    return '${DateTime.now().millisecondsSinceEpoch}_fallback';
  }

  bool _isValidIpAddress(String ip) {
    // Basic IP validation
    final ipv4Regex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    final ipv6Regex = RegExp(
      r'^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$',
    );

    return ipv4Regex.hasMatch(ip) || ipv6Regex.hasMatch(ip);
  }

  // Get detailed user agent
  Future<String> _getUserAgent() async {
    try {
      final packageInfo = _packageInfo ?? await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;
      final appVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      String deviceInfo = '';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceInfo =
            'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt}); ${androidInfo.model} (${androidInfo.brand})';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceInfo =
            'iOS ${iosInfo.systemVersion}; ${iosInfo.utsname.machine} (${iosInfo.model})';
      } else if (kIsWeb) {
        deviceInfo = 'Web/${_getBrowserInfo()}';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceInfo =
            'Windows ${windowsInfo.computerName} (${windowsInfo.buildNumber})';
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        deviceInfo = 'macOS ${macInfo.kernelVersion} (${macInfo.model})';
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceInfo = 'Linux ${linuxInfo.prettyName} (${linuxInfo.version})';
      }

      // Include platform info
      final platform = _getPlatform();

      return '$appName/$appVersion ($buildNumber) [$platform] $deviceInfo';
    } catch (e) {
      print('Error getting user agent: $e');
      return 'JuvaPay/${DateTime.now().year}';
    }
  }

  String _getPlatform() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  String _getBrowserInfo() {
    // Simple browser detection for web
    if (kIsWeb) {
      final userAgent = defaultTargetPlatform.toString();
      if (userAgent.contains('Chrome')) return 'Chrome';
      if (userAgent.contains('Safari')) return 'Safari';
      if (userAgent.contains('Firefox')) return 'Firefox';
      if (userAgent.contains('Edge')) return 'Edge';
    }
    return 'Browser';
  }

  void _showSuccessDialog(
    double amount,
    Map<String, dynamic> result,
    Map<String, dynamic> bankDetails,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24),
              SizedBox(width: 10),
              Text('Withdrawal Requested'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your withdrawal request has been submitted successfully. It will be processed within 24 hours.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Amount',
                      currencyFormat.format(amount),
                      Colors.black,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Reference',
                      result['referenceId'] ?? 'N/A',
                      Colors.grey[600]!,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Account',
                      '${bankDetails['account_name']}\n${bankDetails['account_number']}',
                      Colors.grey[600]!,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Bank',
                      bankDetails['bank_name'] ?? 'N/A',
                      Colors.grey[600]!,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Status', 'PENDING', Colors.orange),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WalletHistoryPage(),
                  ),
                );
              },
              child: const Text('VIEW HISTORY'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showTopSnackbar(String message, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor:
            isError ? theme.colorScheme.error : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 160,
          left: 20,
          right: 20,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletViewModel = context.watch<WalletViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Withdraw',
          style: Theme.of(
            context,
          ).appBarTheme.titleTextStyle?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).appBarTheme.iconTheme?.color,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actionsIconTheme: Theme.of(context).appBarTheme.actionsIconTheme,
      ),
      body:
          _isLoading || walletViewModel.isLoading
              ? Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  await _loadData();
                  await walletViewModel.refreshWalletData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceHeader(theme, walletViewModel),
                      const SizedBox(height: 30),

                      if (_bankDetails == null ||
                              _bankDetails!['account_number']?.isEmpty ??
                          true)
                        _buildNoBankDetailsView(theme)
                      else
                        _buildWithdrawForm(theme),

                      const SizedBox(height: 25),

                      // Withdrawal limits info
                      _buildWithdrawalLimitsInfo(),

                      const SizedBox(height: 25),

                      // Withdrawal History Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WalletHistoryPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: theme.dividerColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'WITHDRAWAL HISTORY',
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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

  Widget _buildWithdrawalLimitsInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Withdrawal Limits: Maximum $_maxWithdrawalsPerDay per day, $_withdrawalCooldownHours hour cooldown between withdrawals.',
              style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader(ThemeData theme, WalletViewModel walletViewModel) {
    final currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦');
    final balance = walletViewModel.wallet?.currentBalance ?? 0.0;
    final availableBalance = walletViewModel.wallet?.availableBalance ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wallet Balance',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Available Balance',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(balance),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currencyFormat.format(availableBalance),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoBankDetailsView(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          const Text(
            "Missing Bank Details",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "You cannot withdraw funds until you have added a verified bank account to your profile.",
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.hintColor, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BankAccountScreen()),
              );
              _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Add Bank Details"),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "BANK DETAILS",
          style: TextStyle(
            color: theme.primaryColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (_bankDetails!['account_name'] ?? '').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_bankDetails!['account_number'] ?? ''} • ${_bankDetails!['bank_name'] ?? ''}",
                      style: TextStyle(fontSize: 13, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: theme.primaryColor,
                  size: 20,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BankAccountScreen(),
                    ),
                  );
                  _loadData();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          "Amount (₦)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          style: theme.textTheme.bodyLarge,
          decoration: _buildInputDecoration(
            "Enter Amount",
            Icons.account_balance_wallet_outlined,
            theme,
          ),
          onChanged: (_) => setState(() {}),
        ),
        _buildHelperText(
          "Minimum withdrawal amount: ₦100. A transfer fee will be deducted.",
          theme,
        ),

        const SizedBox(height: 20),
        const Text(
          "Password",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: theme.textTheme.bodyLarge,
          decoration: _buildInputDecoration(
            "Enter your password",
            Icons.lock_outline,
            theme,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: theme.hintColor,
              ),
              onPressed:
                  () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        _buildHelperText(
          "Enter your login password to authorize this withdrawal.",
          theme,
        ),

        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed:
                _isProcessing ||
                        _amountController.text.isEmpty ||
                        _passwordController.text.isEmpty
                    ? null
                    : _handleWithdraw,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isProcessing ||
                          _amountController.text.isEmpty ||
                          _passwordController.text.isEmpty
                      ? theme.disabledColor
                      : theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child:
                _isProcessing
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      "WITHDRAW",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelperText(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(text, style: TextStyle(fontSize: 11, color: theme.hintColor)),
    );
  }

  InputDecoration _buildInputDecoration(
    String hint,
    IconData icon,
    ThemeData theme,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
      prefixIcon: Icon(icon, color: theme.hintColor, size: 20),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      filled: true,
      fillColor: theme.cardColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
      ),
    );
  }
}
