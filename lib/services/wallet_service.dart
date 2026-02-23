// wallet_service.dart - COMPLETE VERSION
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ==========================================
// DATA MODELS
// ==========================================

class Wallet {
  final String userId;
  final double currentBalance;
  final double availableBalance;
  final double lockedBalance;
  final double totalEarned;
  final double totalDeposited;
  final double totalWithdrawn;
  final double totalSpent;
  final String status;
  final DateTime? lastTransactionAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocked;
  final String? lockReason;
  final String? lockDescription;
  final DateTime? lockExpiresAt;

  Wallet({
    required this.userId,
    required this.currentBalance,
    required this.availableBalance,
    required this.lockedBalance,
    required this.totalEarned,
    required this.totalDeposited,
    required this.totalWithdrawn,
    required this.totalSpent,
    required this.status,
    this.lastTransactionAt,
    required this.createdAt,
    required this.updatedAt,
    this.isLocked = false,
    this.lockReason,
    this.lockDescription,
    this.lockExpiresAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    // Handle timestamp conversion
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else if (timestamp is String) {
        return DateTime.tryParse(timestamp);
      }
      return null;
    }

    return Wallet(
      userId: json['user_id'] as String,
      currentBalance: (json['current_balance'] as num).toDouble(),
      availableBalance: (json['available_balance'] as num).toDouble(),
      lockedBalance: (json['locked_balance'] as num).toDouble(),
      totalEarned: (json['total_earned'] as num).toDouble(),
      totalDeposited: (json['total_deposited'] as num).toDouble(),
      totalWithdrawn: (json['total_withdrawn'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      status: json['status'] as String,
      lastTransactionAt: parseTimestamp(json['last_transaction_at']),
      createdAt: parseTimestamp(json['created_at']) ?? DateTime.now(),
      updatedAt: parseTimestamp(json['updated_at']) ?? DateTime.now(),
      isLocked: json['is_locked'] as bool? ?? false,
      lockReason: json['lock_reason'] as String?,
      lockDescription: json['lock_description'] as String?,
      lockExpiresAt: parseTimestamp(json['lock_expires_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'current_balance': currentBalance,
      'available_balance': availableBalance,
      'locked_balance': lockedBalance,
      'total_earned': totalEarned,
      'total_deposited': totalDeposited,
      'total_withdrawn': totalWithdrawn,
      'total_spent': totalSpent,
      'status': status,
      'last_transaction_at': lastTransactionAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_locked': isLocked,
      'lock_reason': lockReason,
      'lock_description': lockDescription,
      'lock_expires_at': lockExpiresAt?.millisecondsSinceEpoch,
    };
  }

  String get formattedBalance => '₦${currentBalance.toStringAsFixed(2)}';
  String get formattedAvailableBalance =>
      '₦${availableBalance.toStringAsFixed(2)}';
}

class Transaction {
  final int id;
  final String userId;
  final double amount;
  final String type;
  final String status;
  final String description;
  final String referenceId;
  final String? externalReferenceId;
  final String? sourceWalletId;
  final String? destinationWalletId;
  final String? orderId;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? gatewayResponse;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final Map<String, dynamic>? location;
  final double riskScore;
  final double fee;
  final double netAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? failedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    required this.referenceId,
    this.externalReferenceId,
    this.sourceWalletId,
    this.destinationWalletId,
    this.orderId,
    this.metadata,
    this.gatewayResponse,
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    this.location,
    this.riskScore = 0.0,
    this.fee = 0.0,
    required this.netAmount,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.failedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Parse JSON fields
    Map<String, dynamic>? parseJsonField(dynamic data) {
      if (data == null) return null;
      if (data is String) {
        try {
          return jsonDecode(data);
        } catch (e) {
          return {'raw': data};
        }
      } else if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    }

    // Parse timestamp - handle both int (seconds) and string
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      } else if (timestamp is String) {
        return DateTime.tryParse(timestamp) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Transaction(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['transaction_type'] as String,
      status: json['status'] as String,
      description: json['description'] as String,
      referenceId: json['reference_id'] as String,
      externalReferenceId: json['external_reference_id'] as String?,
      sourceWalletId: json['source_wallet_id'] as String?,
      destinationWalletId: json['destination_wallet_id'] as String?,
      orderId: json['order_id'] as String?,
      metadata: parseJsonField(json['metadata']),
      gatewayResponse: parseJsonField(json['gateway_response']),
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      deviceId: json['device_id'] as String?,
      location: parseJsonField(json['location']),
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['net_amount'] as num).toDouble(),
      createdAt: parseTimestamp(json['created_at']),
      updatedAt: parseTimestamp(json['updated_at']),
      completedAt:
          json['completed_at'] != null
              ? parseTimestamp(json['completed_at'])
              : null,
      failedAt:
          json['failed_at'] != null ? parseTimestamp(json['failed_at']) : null,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDay = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    if (transactionDay == today) {
      return 'Today';
    } else if (transactionDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(createdAt);
  }

  String get formattedTime => DateFormat('h:mm a').format(createdAt);

  bool get isCredit => [
    'DEPOSIT',
    'TASK_EARNING',
    'REFUND',
    'TRANSFER_IN',
    'BONUS',
  ].contains(type);
  bool get isDebit => [
    'WITHDRAWAL',
    'ORDER_PAYMENT',
    'ADVERT_FEE',
    'MEMBERSHIP_PAYMENT',
    'TRANSFER_OUT',
    'FEE',
  ].contains(type);

  String get formattedAmount {
    final prefix = isCredit ? '+' : '-';
    return '$prefix₦${amount.toStringAsFixed(2)}';
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      case 'PROCESSING':
        return Colors.blue;
      case 'REVERSED':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  String get statusText {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return 'Completed';
      case 'PENDING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'PROCESSING':
        return 'Processing';
      case 'REVERSED':
        return 'Reversed';
      default:
        return status;
    }
  }
}

class TransactionSummary {
  final double totalIncome;
  final double totalExpenses;
  final double netChange;
  final double totalDeposits;
  final double totalWithdrawals;
  final double totalEarnings;
  final double totalSpent;
  final double totalTransfersIn;
  final double totalTransfersOut;
  final double totalRefunds;
  final int transactionCount;
  final double averageTransactionAmount;

  TransactionSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netChange,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.totalEarnings,
    required this.totalSpent,
    required this.totalTransfersIn,
    required this.totalTransfersOut,
    required this.totalRefunds,
    required this.transactionCount,
    required this.averageTransactionAmount,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      netChange: (json['net_change'] as num?)?.toDouble() ?? 0.0,
      totalDeposits: (json['total_deposits'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawals: (json['total_withdrawals'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      totalTransfersIn: (json['total_transfers_in'] as num?)?.toDouble() ?? 0.0,
      totalTransfersOut:
          (json['total_transfers_out'] as num?)?.toDouble() ?? 0.0,
      totalRefunds: (json['total_refunds'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
      averageTransactionAmount:
          (json['average_transaction_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardStats {
  final Wallet wallet;
  final TransactionSummary today;
  final TransactionSummary week;
  final TransactionSummary month;
  final List<Transaction> recentTransactions;

  DashboardStats({
    required this.wallet,
    required this.today,
    required this.week,
    required this.month,
    required this.recentTransactions,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      wallet: Wallet.fromJson(json['wallet']),
      today: TransactionSummary.fromJson(json['today']),
      week: TransactionSummary.fromJson(json['week']),
      month: TransactionSummary.fromJson(json['month']),
      recentTransactions:
          (json['recent_transactions'] as List<dynamic>)
              .map((e) => Transaction.fromJson(e))
              .toList(),
    );
  }
}

// ==========================================
// WALLET SERVICE
// ==========================================

class WalletService {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _walletSubscription;

  // Flutterwave Configuration
  static const String _flutterwaveBaseUrl = 'https://api.flutterwave.com/v3';
  static const String _flutterwaveSecretKey = 'YOUR_FLUTTERWAVE_SECRET_KEY';

  // ==========================================
  // 1. REAL-TIME WALLET STREAMS
  // ==========================================

  // Stream for real-time wallet updates (returns simple map)
  Stream<Map<String, dynamic>> getWalletStream() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    return _supabase
        .from('wallets')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', user.id)
        .map((snapshot) {
          if (snapshot.isEmpty)
            return {
              'current_balance': 0.0,
              'available_balance': 0.0,
              'locked_balance': 0.0,
            };
          final data = snapshot.first;
          return {
            'current_balance': (data['current_balance'] as num).toDouble(),
            'available_balance': (data['available_balance'] as num).toDouble(),
            'locked_balance': (data['locked_balance'] as num).toDouble(),
          };
        });
  }

  // Alternative method that returns Stream<Wallet>
  Stream<Wallet> watchWallet() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _supabase
        .from('wallets')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', user.id)
        .asyncMap((snapshot) async {
          if (snapshot.isEmpty) {
            return await getWallet();
          }
          return Wallet.fromJson(snapshot.first);
        });
  }

  Stream<List<Transaction>> watchRecentTransactions({int limit = 10}) {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _supabase
        .from('financial_transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((snapshot) {
          return snapshot.map((data) => Transaction.fromJson(data)).toList();
        });
  }

  // ==========================================
  // 2. WALLET OPERATIONS
  // ==========================================

  Future<Wallet> getWallet() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final result = await _supabase
          .rpc('get_user_wallet', params: {'p_user_id': user.id})
          .single()
          .timeout(const Duration(seconds: 10));

      return Wallet.fromJson(result);
    } on TimeoutException {
      throw Exception('Wallet request timed out');
    } on PostgrestException catch (e) {
      throw Exception('Failed to get wallet: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get wallet: $e');
    }
  }

  Future<Map<String, dynamic>> checkBalance(double requiredAmount) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final result = await _supabase
          .rpc(
            'check_wallet_balance',
            params: {'p_user_id': user.id, 'p_required_amount': requiredAmount},
          )
          .single()
          .timeout(const Duration(seconds: 10));

      return {
        'success': true,
        'hasSufficientBalance': result['has_sufficient_balance'] == true,
        'isWalletLocked': result['is_wallet_locked'] == true,
        'currentBalance': (result['current_balance'] as num).toDouble(),
        'availableBalance': (result['available_balance'] as num).toDouble(),
        'requiredAmount': requiredAmount,
        'deficit': (result['deficit'] as num).toDouble(),
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out',
        'hasSufficientBalance': false,
        'isWalletLocked': false,
        'currentBalance': 0.0,
        'availableBalance': 0.0,
        'deficit': requiredAmount,
      };
    } catch (e) {
      debugPrint('Error checking balance: $e');
      return {
        'success': false,
        'error': 'Failed to check balance: $e',
        'hasSufficientBalance': false,
        'isWalletLocked': false,
        'currentBalance': 0.0,
        'availableBalance': 0.0,
        'deficit': requiredAmount,
      };
    }
  }
  // ==========================================
  // 3. ADVERT SUBSCRIPTION METHODS
  // ==========================================

  // Check advert subscription status
  Future<Map<String, dynamic>> checkAdvertSubscription() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response =
          await _supabase
              .from('active_advert_subscriptions')
              .select()
              .eq('user_id', user.id)
              .maybeSingle();

      if (response == null) {
        return {'has_subscription': false, 'is_active': false};
      }

      return {
        'has_subscription': true,
        'is_active': response['is_active'] == true,
        'latest_expiry': response['latest_expiry'],
      };
    } catch (e) {
      debugPrint('Error checking advert subscription: $e');
      return {'has_subscription': false, 'is_active': false};
    }
  }

  // Process advert payment
  Future<Map<String, dynamic>> processAdvertPayment({
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    Map<String, dynamic>? location,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Process advert fee payment
      final result = await processPayment(
        amount: 1000.0,
        transactionType: 'ADVERT_FEE',
        description: 'Advert subscription for 30 days',
        metadata: {
          'advert_type': 'monthly_subscription',
          'duration_days': 30,
          'auto_renew': true,
          if (location != null) 'client_location': location,
        },
        ipAddress: ipAddress,
        userAgent: userAgent,
        deviceId: deviceId,
      );

      if (result['success'] == true) {
        // Create advert subscription record
        final subscriptionResult =
            await _supabase
                .from('advert_subscriptions')
                .insert({
                  'user_id': user.id,
                  'start_date': DateTime.now().toIso8601String(),
                  'end_date':
                      DateTime.now()
                          .add(const Duration(days: 30))
                          .toIso8601String(),
                  'amount_paid': 1000.0,
                  'payment_ref': result['referenceId'],
                })
                .select()
                .single();

        return {
          'success': true,
          'message': 'Advert subscription activated successfully!',
          'subscription_id': subscriptionResult['id'],
          'current_balance': result['currentBalance'],
          'available_balance': result['availableBalance'],
        };
      }

      return {
        'success': false,
        'message': result['message'] ?? 'Payment failed',
      };
    } catch (e) {
      debugPrint('Error processing advert payment: $e');
      return {'success': false, 'message': 'Payment failed: $e'};
    }
  }

  // ==========================================
  // 4. DEPOSIT OPERATIONS
  // ==========================================

  Future<Map<String, dynamic>> processDeposit({
    required double amount,
    required String referenceId,
    Map<String, dynamic>? gatewayResponse,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    Map<String, dynamic>? location,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final normalizedAmount = double.parse(amount.toStringAsFixed(2));

    try {
      final result = await _supabase
          .rpc(
            'process_deposit',
            params: {
              'p_user_id': user.id,
              'p_amount': normalizedAmount,
              'p_reference_id': referenceId,
              'p_gateway_response': gatewayResponse,
              'p_ip_address': ipAddress,
              'p_user_agent': userAgent,
              'p_device_id': deviceId,
              'p_location': location,
            },
          )
          .single()
          .timeout(const Duration(seconds: 30));

      return {
        'success': result['success'] ?? false,
        'transactionId': result['transaction_id'],
        'status': result['status'],
        'currentBalance': (result['current_balance'] as num?)?.toDouble(),
        'availableBalance': (result['available_balance'] as num?)?.toDouble(),
        'message': result['message'],
        'error': result['error'],
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'DEPOSIT_TIMEOUT',
        'message': 'Deposit request timed out',
      };
    } on PostgrestException catch (e) {
      return {
        'success': false,
        'error': 'DATABASE_ERROR',
        'message': e.message,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'UNKNOWN_ERROR',
        'message': 'Failed to process deposit: $e',
      };
    }
  }

  Future<Map<String, dynamic>> verifyFlutterwaveTransaction(
    String transactionId,
  ) async {
    try {
      // Verify with Flutterwave API
      final url = Uri.parse(
        '$_flutterwaveBaseUrl/transactions/$transactionId/verify',
      );
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_flutterwaveSecretKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final flutterwaveStatus =
            data['data']['status']?.toString().toLowerCase();
        final reference = data['data']['tx_ref'];

        // Determine status based on Flutterwave response
        String status;
        if (flutterwaveStatus == 'successful') {
          status = 'COMPLETED';
        } else if (flutterwaveStatus == 'pending') {
          status = 'PENDING';
        } else {
          status = 'FAILED';
        }

        // Update transaction status in our database
        final verifyResult = await verifyTransaction(
          referenceId: reference,
          newStatus: status,
          updatedGatewayResponse: data['data'],
        );

        return {
          'success': verifyResult['success'] ?? false,
          'verified': flutterwaveStatus == 'successful',
          'status': status,
          'amount': data['data']['amount'],
          'currency': data['data']['currency'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'verified': false,
          'message': 'Failed to verify transaction with Flutterwave',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'verified': false,
        'message': 'Error verifying transaction: $e',
      };
    }
  }

  Future<Map<String, dynamic>> verifyTransaction({
    required String referenceId,
    required String newStatus,
    Map<String, dynamic>? updatedGatewayResponse,
  }) async {
    try {
      final result = await _supabase
          .rpc(
            'verify_transaction',
            params: {
              'p_reference_id': referenceId,
              'p_new_status': newStatus,
              'p_updated_gateway_response': updatedGatewayResponse,
            },
          )
          .single()
          .timeout(const Duration(seconds: 10));

      return {
        'success': result['success'] ?? false,
        'message': result['message'],
        'transactionId': result['transaction_id'],
        'oldStatus': result['old_status'],
        'newStatus': result['new_status'],
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Verification request timed out'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to verify transaction: $e'};
    }
  }

  // ==========================================
  // 5. WITHDRAWAL OPERATIONS
  // ==========================================

  Future<Map<String, dynamic>> processWithdrawal({
    required double amount,
    required Map<String, dynamic> bankDetails,
    String description = 'Withdrawal request',
    String? ipAddress,
    String? userAgent,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final result = await _supabase
          .rpc(
            'process_withdrawal',
            params: {
              'p_user_id': user.id,
              'p_amount': amount,
              'p_bank_details': bankDetails,
              'p_description': description,
              'p_ip_address': ipAddress,
              'p_user_agent': userAgent,
            },
          )
          .single()
          .timeout(const Duration(seconds: 30));

      return {
        'success': result['success'] ?? false,
        'transactionId': result['transaction_id'],
        'referenceId': result['reference_id'],
        'currentBalance': (result['current_balance'] as num?)?.toDouble(),
        'availableBalance': (result['available_balance'] as num?)?.toDouble(),
        'message': result['message'],
        'error': result['error'],
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'WITHDRAWAL_TIMEOUT',
        'message': 'Withdrawal request timed out',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'WITHDRAWAL_FAILED',
        'message': 'Failed to process withdrawal: $e',
      };
    }
  }

  // ==========================================
  // 6. PAYMENT OPERATIONS
  // ==========================================

  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String
    transactionType, // 'ORDER_PAYMENT', 'ADVERT_FEE', 'MEMBERSHIP_PAYMENT', 'FEE'
    required String description,
    String? referenceId,
    Map<String, dynamic>? metadata,
    String? orderId,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final params = {
        'p_user_id': user.id,
        'p_amount': amount,
        'p_transaction_type': transactionType,
        'p_description': description,
        if (referenceId != null) 'p_reference_id': referenceId,
        if (metadata != null) 'p_metadata': metadata,
        if (orderId != null) 'p_order_id': orderId,
        if (ipAddress != null) 'p_ip_address': ipAddress,
        if (userAgent != null) 'p_user_agent': userAgent,
        if (deviceId != null) 'p_device_id': deviceId,
      };

      final result = await _supabase
          .rpc('process_payment', params: params)
          .single()
          .timeout(const Duration(seconds: 30));

      return {
        'success': result['success'] ?? false,
        'transactionId': result['transaction_id'],
        'referenceId': result['reference_id'],
        'currentBalance': (result['current_balance'] as num?)?.toDouble(),
        'availableBalance': (result['available_balance'] as num?)?.toDouble(),
        'feeCharged': (result['fee_charged'] as num?)?.toDouble(),
        'netAmount': (result['net_amount'] as num?)?.toDouble(),
        'message': result['message'],
        'error': result['error'],
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'PAYMENT_TIMEOUT',
        'message': 'Payment request timed out',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'PAYMENT_FAILED',
        'message': 'Failed to process payment: $e',
      };
    }
  }

  // ==========================================
  // 7. TRANSFER OPERATIONS
  // ==========================================

  Future<Map<String, dynamic>> transferBetweenWallets({
    required String destinationUserId,
    required double amount,
    String description = 'Wallet transfer',
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? location,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final normalizedAmount = double.parse(amount.toStringAsFixed(2));

    try {
      final result = await _supabase
          .rpc(
            'transfer_between_wallets',
            params: {
              'p_source_user_id': user.id,
              'p_destination_user_id': destinationUserId,
              'p_amount': normalizedAmount,
              'p_description': description,
              'p_ip_address': ipAddress,
              'p_user_agent': userAgent,
              'p_location': location,
            },
          )
          .single()
          .timeout(const Duration(seconds: 30));

      return {
        'success': result['success'] ?? false,
        'transferReference': result['transfer_reference'],
        'outgoingTransactionId': result['outgoing_transaction_id'],
        'incomingTransactionId': result['incoming_transaction_id'],
        'amountSent': (result['amount_sent'] as num?)?.toDouble(),
        'amountReceived': (result['amount_received'] as num?)?.toDouble(),
        'transferFee': (result['transfer_fee'] as num?)?.toDouble(),
        'sourceNewBalance': (result['source_new_balance'] as num?)?.toDouble(),
        'sourceAvailableBalance':
            (result['source_available_balance'] as num?)?.toDouble(),
        'destNewBalance': (result['dest_new_balance'] as num?)?.toDouble(),
        'destAvailableBalance':
            (result['dest_available_balance'] as num?)?.toDouble(),
        'message': result['message'],
        'error': result['error'],
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'TRANSFER_TIMEOUT',
        'message': 'Transfer request timed out',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'TRANSFER_FAILED',
        'message': 'Failed to process transfer: $e',
      };
    }
  }

  Future<Map<String, dynamic>?> resolveTransferRecipient(
    String recipientInput,
  ) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final raw = recipientInput.trim();
    if (raw.isEmpty) return null;

    final normalized = raw.startsWith('@') ? raw.substring(1) : raw;

    try {
      if (_isUuidFormat(normalized)) {
        if (normalized == currentUser.id) {
          return {'userId': normalized, 'isSelf': true};
        }

        try {
          final profile =
              await _supabase
                  .from('profiles')
                  .select('id, username, full_name')
                  .eq('id', normalized)
                  .maybeSingle();

          if (profile != null) {
            return {
              'userId': normalized,
              'username': profile['username']?.toString(),
              'fullName': profile['full_name']?.toString(),
              'isSelf': false,
            };
          }
        } catch (_) {
          // If profile lookup is blocked by RLS, we can still transfer by UUID.
        }

        return {'userId': normalized, 'isSelf': false};
      }

      final response =
          await _supabase
              .from('profiles')
              .select('id, username, full_name')
              .ilike('username', normalized)
              .maybeSingle();

      if (response == null) return null;

      final userId = response['id']?.toString();
      if (userId == null || userId.isEmpty) return null;
      if (userId == currentUser.id) {
        return {
          'userId': userId,
          'username': response['username']?.toString(),
          'fullName': response['full_name']?.toString(),
          'isSelf': true,
        };
      }

      return {
        'userId': userId,
        'username': response['username']?.toString(),
        'fullName': response['full_name']?.toString(),
        'isSelf': false,
      };
    } catch (e) {
      debugPrint('Error resolving transfer recipient: $e');
      return null;
    }
  }

  bool _isUuidFormat(String value) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(value);
  }

  // ==========================================
  // 8. REFUND OPERATIONS
  // ==========================================

  Future<Map<String, dynamic>> processRefund({
    required int originalTransactionId,
    required double refundAmount,
    String reason = 'Refund',
    String? processedBy,
  }) async {
    try {
      final result = await _supabase
          .rpc(
            'process_refund',
            params: {
              'p_original_transaction_id': originalTransactionId,
              'p_refund_amount': refundAmount,
              'p_reason': reason,
              'p_processed_by': processedBy,
            },
          )
          .single()
          .timeout(const Duration(seconds: 30));

      return {
        'success': result['success'] ?? false,
        'refundTransactionId': result['refund_transaction_id'],
        'refundReference': result['refund_reference'],
        'refundAmount': (result['refund_amount'] as num?)?.toDouble(),
        'originalTransactionId': result['original_transaction_id'],
        'message': result['message'],
        'error': result['error'],
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'REFUND_TIMEOUT',
        'message': 'Refund request timed out',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'REFUND_FAILED',
        'message': 'Failed to process refund: $e',
      };
    }
  }

  // ==========================================
  // 9. TRANSACTION HISTORY
  // ==========================================

  Future<List<Transaction>> getTransactionHistory({
    List<String>? types,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // Start with basic query
      var query = _supabase
          .from('financial_transactions')
          .select('*')
          .eq('user_id', user.id);

      // Apply filters using the filter() method (universal method)
      if (types != null && types.isNotEmpty) {
        // Build OR conditions for multiple types
        final orConditions = types
            .map((type) => 'transaction_type.eq.$type')
            .join(',');
        query = query.or(orConditions);
      }

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.filter('created_at', 'gte', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.filter('created_at', 'lte', endDate.toIso8601String());
      }

      // Apply ordering, limit, and range
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1)
          .timeout(const Duration(seconds: 10));

      // Convert response to Transaction objects
      final transactions =
          (response as List).map((item) => Transaction.fromJson(item)).toList();

      return transactions;
    } catch (e) {
      debugPrint('Error getting transaction history: $e');
      return [];
    }
  }

  // Simple method for common use cases
  Future<List<Transaction>> getRecentTransactions({
    int limit = 20,
    String? type,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      var query = _supabase
          .from('financial_transactions')
          .select('*')
          .eq('user_id', user.id);

      if (type != null) {
        query = query.eq('transaction_type', type);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(const Duration(seconds: 10));

      return (response as List)
          .map((item) => Transaction.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting recent transactions: $e');
      return [];
    }
  }

  Future<TransactionSummary> getMonthlyStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final result = await _supabase
          .rpc(
            'get_monthly_statistics',
            params: {
              'p_user_id': user.id,
              'p_start_date': startDate.toIso8601String(),
              'p_end_date': endDate.toIso8601String(),
            },
          )
          .single()
          .timeout(const Duration(seconds: 10));

      return TransactionSummary.fromJson(result);
    } catch (e) {
      debugPrint('Error getting monthly statistics: $e');
      return TransactionSummary(
        totalIncome: 0,
        totalExpenses: 0,
        netChange: 0,
        totalDeposits: 0,
        totalWithdrawals: 0,
        totalEarnings: 0,
        totalSpent: 0,
        totalTransfersIn: 0,
        totalTransfersOut: 0,
        totalRefunds: 0,
        transactionCount: 0,
        averageTransactionAmount: 0,
      );
    }
  }

  Future<DashboardStats> getDashboardStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final result = await _supabase
          .rpc('get_dashboard_stats', params: {'p_user_id': user.id})
          .single()
          .timeout(const Duration(seconds: 10));

      return DashboardStats.fromJson(result);
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWalletStatement({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000,
    int offset = 0,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final result = await _supabase
          .rpc(
            'get_wallet_statement',
            params: {
              'p_user_id': user.id,
              'p_start_date': startDate?.toIso8601String(),
              'p_end_date': endDate?.toIso8601String(),
              'p_limit': limit,
              'p_offset': offset,
            },
          )
          .single()
          .timeout(const Duration(seconds: 15));

      return result;
    } catch (e) {
      debugPrint('Error getting wallet statement: $e');
      return {
        'user_id': user.id,
        'current_balance': 0.0,
        'total_transactions': 0,
        'transactions': [],
      };
    }
  }

  // ==========================================
  // 10. WALLET SECURITY
  // ==========================================

  Future<Map<String, dynamic>> lockWallet({
    required String userId,
    required String reason,
    String? description,
    String? lockedBy,
    DateTime? expiresAt,
  }) async {
    try {
      final result = await _supabase
          .rpc(
            'lock_wallet',
            params: {
              'p_user_id': userId,
              'p_reason': reason,
              'p_description': description,
              'p_locked_by': lockedBy,
              'p_expires_at': expiresAt?.toIso8601String(),
            },
          )
          .single()
          .timeout(const Duration(seconds: 10));

      return {
        'success': result['success'] ?? false,
        'lockId': result['lock_id'],
        'message': result['message'],
        'error': result['error'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'LOCK_FAILED',
        'message': 'Failed to lock wallet: $e',
      };
    }
  }

  Future<Map<String, dynamic>> unlockWallet({
    required String userId,
    String unlockReason = 'Manual unlock',
    String? unlockedBy,
  }) async {
    try {
      final result = await _supabase
          .rpc(
            'unlock_wallet',
            params: {
              'p_user_id': userId,
              'p_unlock_reason': unlockReason,
              'p_unlocked_by': unlockedBy,
            },
          )
          .single()
          .timeout(const Duration(seconds: 10));

      return {
        'success': result['success'] ?? false,
        'message': result['message'],
        'error': result['error'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'UNLOCK_FAILED',
        'message': 'Failed to unlock wallet: $e',
      };
    }
  }

  // ==========================================
  // 11. SYSTEM HEALTH
  // ==========================================

  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final result = await _supabase
          .rpc('get_system_health')
          .single()
          .timeout(const Duration(seconds: 10));

      return result;
    } catch (e) {
      return {
        'status': 'UNKNOWN',
        'timestamp': DateTime.now().toIso8601String(),
        'metrics': {
          'total_wallets': 0,
          'total_transactions': 0,
          'pending_transactions': 0,
          'failed_transactions_24h': 0,
          'total_balance': 0,
          'active_users_24h': 0,
          'critical_alerts': 0,
        },
      };
    }
  }

  // ==========================================
  // 12. UTILITY METHODS
  // ==========================================

  Future<void> cancelTransaction({
    required String referenceId,
    String reason = 'User cancelled',
    String? cancelledBy,
  }) async {
    try {
      await _supabase
          .rpc(
            'cancel_transaction',
            params: {
              'p_reference_id': referenceId,
              'p_reason': reason,
              'p_cancelled_by': cancelledBy,
            },
          )
          .single()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error cancelling transaction: $e');
      rethrow;
    }
  }

  // Helper method to format transaction type for display
  static String formatTransactionType(String type) {
    switch (type) {
      case 'DEPOSIT':
        return 'Deposit';
      case 'WITHDRAWAL':
        return 'Withdrawal';
      case 'TASK_EARNING':
        return 'Task Earnings';
      case 'ORDER_PAYMENT':
        return 'Order Payment';
      case 'ADVERT_FEE':
        return 'Advert Fee';
      case 'MEMBERSHIP_PAYMENT':
        return 'Membership';
      case 'REFUND':
        return 'Refund';
      case 'TRANSFER_IN':
        return 'Transfer Received';
      case 'TRANSFER_OUT':
        return 'Transfer Sent';
      case 'CHARGEBACK':
        return 'Chargeback';
      case 'FEE':
        return 'Service Fee';
      case 'BONUS':
        return 'Bonus';
      case 'CORRECTION':
        return 'Balance Correction';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  // Helper method to get transaction icon
  static IconData getTransactionIcon(String type) {
    switch (type) {
      case 'DEPOSIT':
      case 'TASK_EARNING':
      case 'REFUND':
      case 'TRANSFER_IN':
      case 'BONUS':
        return Icons.add_circle_outline;
      case 'WITHDRAWAL':
      case 'ORDER_PAYMENT':
      case 'ADVERT_FEE':
      case 'MEMBERSHIP_PAYMENT':
      case 'TRANSFER_OUT':
      case 'FEE':
      case 'CHARGEBACK':
        return Icons.remove_circle_outline;
      case 'CORRECTION':
        return Icons.edit_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  // Clean up subscription
  void dispose() {
    _walletSubscription?.cancel();
  }
}
