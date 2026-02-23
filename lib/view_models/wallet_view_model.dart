import 'dart:async';
import 'package:flutter/material.dart';
import '../services/wallet_service.dart'; // Import WalletService
import '../utils/transaction_context.dart';

// ==========================================
// --- WALLET DATA MODEL ---
// ==========================================

class WalletData {
  final double currentBalance;
  final double availableBalance;
  final double lockedBalance;
  final double totalEarned;
  final double totalDeposited;
  final double totalWithdrawn;
  final double totalSpent;
  final String status;
  final bool isLocked;

  WalletData({
    required this.currentBalance,
    required this.availableBalance,
    required this.lockedBalance,
    required this.totalEarned,
    required this.totalDeposited,
    required this.totalWithdrawn,
    required this.totalSpent,
    required this.status,
    required this.isLocked,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      currentBalance: (json['current_balance'] as num).toDouble(),
      availableBalance: (json['available_balance'] as num).toDouble(),
      lockedBalance: (json['locked_balance'] as num).toDouble(),
      totalEarned: (json['total_earned'] as num).toDouble(),
      totalDeposited: (json['total_deposited'] as num).toDouble(),
      totalWithdrawn: (json['total_withdrawn'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      status: json['status'] as String,
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  // Factory from Wallet object
  factory WalletData.fromWallet(Wallet wallet) {
    return WalletData(
      currentBalance: wallet.currentBalance,
      availableBalance: wallet.availableBalance,
      lockedBalance: wallet.lockedBalance,
      totalEarned: wallet.totalEarned,
      totalDeposited: wallet.totalDeposited,
      totalWithdrawn: wallet.totalWithdrawn,
      totalSpent: wallet.totalSpent,
      status: wallet.status,
      isLocked: wallet.isLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_balance': currentBalance,
      'available_balance': availableBalance,
      'locked_balance': lockedBalance,
      'total_earned': totalEarned,
      'total_deposited': totalDeposited,
      'total_withdrawn': totalWithdrawn,
      'total_spent': totalSpent,
      'status': status,
      'is_locked': isLocked,
    };
  }

  // Legacy properties for backward compatibility
  double get balance => currentBalance;
  double get pendingBalance => lockedBalance;
  double get amountSpent => totalSpent;
}

// ==========================================
// --- WALLET VIEW MODEL ---
// ==========================================

class WalletViewModel extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  WalletData? _walletData;
  Wallet? _wallet;
  List<Transaction> _recentTransactions = [];
  TransactionSummary? _monthlyStats;
  DashboardStats? _dashboardStats;
  bool _isLoading = false;
  String? _errorMessage;

  WalletData? get walletData => _walletData;
  Wallet? get wallet => _wallet;
  List<Transaction> get recentTransactions => _recentTransactions;
  TransactionSummary? get monthlyStats => _monthlyStats;
  DashboardStats? get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Stream subscriptions
  StreamSubscription<Wallet>? _walletSubscription;
  StreamSubscription<List<Transaction>>? _transactionsSubscription;

  // Initialize data fetching when the ViewModel is created
  WalletViewModel() {
    fetchWalletData();
    _setupRealtimeSubscriptions();
  }

  void _setupRealtimeSubscriptions() {
    try {
      // Wallet real-time updates
      _walletSubscription = _walletService.watchWallet().listen((wallet) {
        _wallet = wallet;
        _walletData = WalletData.fromWallet(wallet);
        notifyListeners();
      });

      // Recent transactions real-time updates
      _transactionsSubscription = _walletService
          .watchRecentTransactions(limit: 10)
          .listen((transactions) {
            _recentTransactions = transactions;
            notifyListeners();
          });
    } catch (e) {
      debugPrint("Error setting up real-time subscriptions: $e");
    }
  }

  Future<void> fetchWalletData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get wallet using the correct method name
      final wallet = await _walletService.getWallet();
      _wallet = wallet;
      _walletData = WalletData.fromWallet(wallet);

      // Get recent transactions
      _recentTransactions = await _walletService.getRecentTransactions(
        limit: 10,
      );

      // Get dashboard stats
      try {
        _dashboardStats = await _walletService.getDashboardStats();
      } catch (e) {
        debugPrint("Error getting dashboard stats: $e");
        // Create default dashboard stats
        _dashboardStats = DashboardStats(
          wallet: wallet,
          today: TransactionSummary(
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
          ),
          week: TransactionSummary(
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
          ),
          month: TransactionSummary(
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
          ),
          recentTransactions: _recentTransactions,
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to load wallet data: ${e.toString()}';
      debugPrint('Error in fetchWalletData: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Additional methods for updating wallet data
  Future<void> refreshWalletData() async {
    await fetchWalletData();
  }

  // Check wallet balance (matches your service method)
  Future<Map<String, dynamic>> checkBalance(double requiredAmount) async {
    try {
      return await _walletService.checkBalance(requiredAmount);
    } catch (e) {
      debugPrint('Error checking balance: $e');
      return {
        'success': false,
        'error': 'Failed to check balance: $e',
        'hasSufficientBalance': false,
        'isWalletLocked': _wallet?.isLocked ?? false,
        'currentBalance': _wallet?.currentBalance ?? 0.0,
        'availableBalance': _wallet?.availableBalance ?? 0.0,
        'requiredAmount': requiredAmount,
        'deficit': requiredAmount,
      };
    }
  }

  // Process deposit (matches your service method)
  Future<Map<String, dynamic>> processDeposit({
    required double amount,
    required String referenceId,
    Map<String, dynamic>? gatewayResponse,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    Map<String, dynamic>? location,
  }) async {
    try {
      final txContext =
          (ipAddress == null || userAgent == null || deviceId == null)
              ? await TransactionContext.fetch()
              : null;
      final result = await _walletService.processDeposit(
        amount: amount,
        referenceId: referenceId,
        gatewayResponse: gatewayResponse,
        ipAddress: ipAddress ?? txContext?.ipAddress,
        userAgent: userAgent ?? txContext?.userAgent,
        deviceId: deviceId ?? txContext?.deviceId,
        location: location ?? txContext?.location,
      );

      // Refresh wallet data after successful deposit
      if (result['success'] == true) {
        await fetchWalletData();
      }

      return result;
    } catch (e) {
      debugPrint('Error processing deposit: $e');
      return {
        'success': false,
        'error': 'DEPOSIT_FAILED',
        'message': 'Failed to process deposit: $e',
      };
    }
  }

  // Process withdrawal (matches your service method)
  Future<Map<String, dynamic>> processWithdrawal({
    required double amount,
    required Map<String, dynamic> bankDetails,
    String description = 'Withdrawal request',
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final txContext =
          (ipAddress == null || userAgent == null)
              ? await TransactionContext.fetch()
              : null;
      final result = await _walletService.processWithdrawal(
        amount: amount,
        bankDetails: bankDetails,
        description: description,
        ipAddress: ipAddress ?? txContext?.ipAddress,
        userAgent: userAgent ?? txContext?.userAgent,
      );

      // Refresh wallet data after successful withdrawal
      if (result['success'] == true) {
        await fetchWalletData();
      }

      return result;
    } catch (e) {
      debugPrint('Error processing withdrawal: $e');
      return {
        'success': false,
        'error': 'WITHDRAWAL_FAILED',
        'message': 'Failed to process withdrawal: $e',
      };
    }
  }

  // Process payment (matches your service method)
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String transactionType,
    required String description,
    String? referenceId,
    Map<String, dynamic>? metadata,
    String? orderId,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
  }) async {
    try {
      final txContext =
          (ipAddress == null || userAgent == null || deviceId == null)
              ? await TransactionContext.fetch()
              : null;
      final enrichedMetadata = {
        if (metadata != null) ...metadata,
        if (txContext?.location != null) 'client_location': txContext!.location,
      };
      final result = await _walletService.processPayment(
        amount: amount,
        transactionType: transactionType,
        description: description,
        referenceId: referenceId,
        metadata: enrichedMetadata.isEmpty ? null : enrichedMetadata,
        orderId: orderId,
        ipAddress: ipAddress ?? txContext?.ipAddress,
        userAgent: userAgent ?? txContext?.userAgent,
        deviceId: deviceId ?? txContext?.deviceId,
      );

      // Refresh wallet data after successful payment
      if (result['success'] == true) {
        await fetchWalletData();
      }

      return result;
    } catch (e) {
      debugPrint('Error processing payment: $e');
      return {
        'success': false,
        'error': 'PAYMENT_FAILED',
        'message': 'Failed to process payment: $e',
      };
    }
  }

  // Transfer between wallets (matches your service method)
  Future<Map<String, dynamic>> transferBetweenWallets({
    required String destinationUserId,
    required double amount,
    String description = 'Wallet transfer',
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? location,
  }) async {
    try {
      final txContext =
          (ipAddress == null || userAgent == null)
              ? await TransactionContext.fetch()
              : null;
      final result = await _walletService.transferBetweenWallets(
        destinationUserId: destinationUserId,
        amount: amount,
        description: description,
        ipAddress: ipAddress ?? txContext?.ipAddress,
        userAgent: userAgent ?? txContext?.userAgent,
        location: location ?? txContext?.location,
      );

      // Refresh wallet data after successful transfer
      if (result['success'] == true) {
        await fetchWalletData();
      }

      return result;
    } catch (e) {
      debugPrint('Error transferring between wallets: $e');
      return {
        'success': false,
        'error': 'TRANSFER_FAILED',
        'message': 'Failed to process transfer: $e',
      };
    }
  }

  // Get transaction history (fixed to match your service method)
  Future<List<Transaction>> getTransactionHistory({
    List<String>? types,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      return await _walletService.getTransactionHistory(
        types: types,
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error getting transaction history: $e');
      return [];
    }
  }

  // Alternative transaction history method - REMOVED since it doesn't exist in updated service
  // You can use getTransactionHistory instead

  // Get monthly statistics
  Future<TransactionSummary> getMonthlyStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _monthlyStats = await _walletService.getMonthlyStatistics(
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
      return _monthlyStats!;
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

  // Get wallet statement
  Future<Map<String, dynamic>> getWalletStatement({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000,
    int offset = 0,
  }) async {
    try {
      return await _walletService.getWalletStatement(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      debugPrint('Error getting wallet statement: $e');
      return {
        'user_id': '',
        'current_balance': 0.0,
        'total_transactions': 0,
        'transactions': [],
      };
    }
  }

  // Verify Flutterwave transaction
  Future<Map<String, dynamic>> verifyFlutterwaveTransaction(
    String transactionId,
  ) async {
    try {
      return await _walletService.verifyFlutterwaveTransaction(transactionId);
    } catch (e) {
      debugPrint('Error verifying Flutterwave transaction: $e');
      return {
        'success': false,
        'verified': false,
        'message': 'Failed to verify transaction: $e',
      };
    }
  }

  // Verify transaction
  Future<Map<String, dynamic>> verifyTransaction({
    required String referenceId,
    required String newStatus,
    Map<String, dynamic>? updatedGatewayResponse,
  }) async {
    try {
      return await _walletService.verifyTransaction(
        referenceId: referenceId,
        newStatus: newStatus,
        updatedGatewayResponse: updatedGatewayResponse,
      );
    } catch (e) {
      debugPrint('Error verifying transaction: $e');
      return {'success': false, 'message': 'Failed to verify transaction: $e'};
    }
  }

  // Process refund
  Future<Map<String, dynamic>> processRefund({
    required int originalTransactionId,
    required double refundAmount,
    String reason = 'Refund',
    String? processedBy,
  }) async {
    try {
      return await _walletService.processRefund(
        originalTransactionId: originalTransactionId,
        refundAmount: refundAmount,
        reason: reason,
        processedBy: processedBy,
      );
    } catch (e) {
      debugPrint('Error processing refund: $e');
      return {
        'success': false,
        'error': 'REFUND_FAILED',
        'message': 'Failed to process refund: $e',
      };
    }
  }

  // Lock wallet
  Future<Map<String, dynamic>> lockWallet({
    required String userId,
    required String reason,
    String? description,
    String? lockedBy,
    DateTime? expiresAt,
  }) async {
    try {
      return await _walletService.lockWallet(
        userId: userId,
        reason: reason,
        description: description,
        lockedBy: lockedBy,
        expiresAt: expiresAt,
      );
    } catch (e) {
      debugPrint('Error locking wallet: $e');
      return {
        'success': false,
        'error': 'LOCK_FAILED',
        'message': 'Failed to lock wallet: $e',
      };
    }
  }

  // Unlock wallet
  Future<Map<String, dynamic>> unlockWallet({
    required String userId,
    String unlockReason = 'Manual unlock',
    String? unlockedBy,
  }) async {
    try {
      return await _walletService.unlockWallet(
        userId: userId,
        unlockReason: unlockReason,
        unlockedBy: unlockedBy,
      );
    } catch (e) {
      debugPrint('Error unlocking wallet: $e');
      return {
        'success': false,
        'error': 'UNLOCK_FAILED',
        'message': 'Failed to unlock wallet: $e',
      };
    }
  }

  // Get system health
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      return await _walletService.getSystemHealth();
    } catch (e) {
      debugPrint('Error getting system health: $e');
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

  // Cancel transaction
  Future<void> cancelTransaction({
    required String referenceId,
    String reason = 'User cancelled',
    String? cancelledBy,
  }) async {
    try {
      await _walletService.cancelTransaction(
        referenceId: referenceId,
        reason: reason,
        cancelledBy: cancelledBy,
      );
    } catch (e) {
      debugPrint('Error cancelling transaction: $e');
      rethrow;
    }
  }

  // Legacy methods for backward compatibility
  double get balance => _wallet?.currentBalance ?? 0.0;
  double get availableBalance => _wallet?.availableBalance ?? 0.0;
  double get lockedBalance => _wallet?.lockedBalance ?? 0.0;
  double get totalEarned => _wallet?.totalEarned ?? 0.0;
  double get totalSpent => _wallet?.totalSpent ?? 0.0;
  String get formattedBalance => _wallet?.formattedBalance ?? '₦0.00';
  String get formattedAvailableBalance =>
      _wallet?.formattedAvailableBalance ?? '₦0.00';

  @override
  void dispose() {
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
