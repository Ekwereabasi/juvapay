// view_models/home_view_model.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/supabase_auth_service.dart';
import '../services/wallet_service.dart';
import '../services/task_service.dart';
import '../services/cache_service.dart';
import '../services/network_service.dart';
import '../models/task_models.dart';
import '../utils/platform_helper.dart';
import '../utils/task_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import


class HomeViewModel extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final WalletService _walletService = WalletService();
  final TaskService _taskService = TaskService();
  final CacheService _cacheService;
  final NetworkService _networkService;

  bool _isLoading = true;
  bool _isOffline = false;
  bool _cacheLoaded = false;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  bool get cacheLoaded => _cacheLoaded;

  // Data Holders
  Wallet? _wallet;
  List<TaskModel> _tasks = [];
  List<Transaction> _recentTransactions = [];
  String _fullName = 'User';
  String? _profilePictureUrl;

  // Cache timestamps
  DateTime? _tasksLastUpdated;
  DateTime? _walletLastUpdated;
  DateTime? _profileLastUpdated;
  DateTime? _transactionsLastUpdated;

  // Stream subscriptions
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Wallet>? _walletSubscription;
  StreamSubscription<List<Transaction>>? _transactionsSubscription;

  // Getters
  Wallet? get wallet => _wallet;
  List<TaskModel> get tasks => _tasks;
  List<Transaction> get recentTransactions => _recentTransactions;
  String get fullName => _fullName;
  String? get profilePictureUrl => _profilePictureUrl;

  // Helper getter for backward compatibility
  Map<String, dynamic> get walletAsMap {
    if (_wallet == null) {
      return {
        'balance': 0.0,
        'totalEarned': 0.0,
        'amountSpent': 0.0,
        'pendingBalance': 0.0,
        'current_balance': 0.0,
        'available_balance': 0.0,
        'locked_balance': 0.0,
        'total_earned': 0.0,
        'total_deposited': 0.0,
        'total_withdrawn': 0.0,
        'total_spent': 0.0,
        'status': 'inactive',
        'formattedBalance': '₦0.00',
        'formattedAvailableBalance': '₦0.00',
      };
    }

    return {
      'balance': _wallet!.currentBalance,
      'totalEarned': _wallet!.totalEarned,
      'amountSpent': _wallet!.totalSpent,
      'pendingBalance': _wallet!.lockedBalance,
      'current_balance': _wallet!.currentBalance,
      'available_balance': _wallet!.availableBalance,
      'locked_balance': _wallet!.lockedBalance,
      'total_earned': _wallet!.totalEarned,
      'total_deposited': _wallet!.totalDeposited,
      'total_withdrawn': _wallet!.totalWithdrawn,
      'total_spent': _wallet!.totalSpent,
      'status': _wallet!.status,
      'formattedBalance': _wallet!.formattedBalance,
      'formattedAvailableBalance': _wallet!.formattedAvailableBalance,
    };
  }

  HomeViewModel({
    required CacheService cacheService,
    required NetworkService networkService,
  }) : _cacheService = cacheService,
       _networkService = networkService {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Listen to auth state changes
      _authSubscription = _authService.authStateChanges.listen((authState) {
        final session = authState.session;
        if (session == null) {
          clearData();
        } else {
          _refreshNetworkData();
        }
        notifyListeners();
      });

      // Listen to network connectivity changes
      _networkService.connectivityStream.listen((isConnected) {
        if (_isOffline != !isConnected) {
          _isOffline = !isConnected;
          notifyListeners();

          if (isConnected && _cacheLoaded) {
            _refreshNetworkData();
          }
        }
      });

      // Set up real-time subscriptions
      _setupRealtimeSubscriptions();

      await loadDashboardData();
    } catch (e) {
      debugPrint("Error initializing HomeViewModel: $e");
    }
  }

  void _setupRealtimeSubscriptions() {
    try {
      // Wallet real-time updates
      _walletSubscription = _walletService.watchWallet().listen((wallet) {
        _wallet = wallet;
        _walletLastUpdated = DateTime.now();
        _cacheWalletData();
        notifyListeners();
      });

      // Recent transactions real-time updates
      _transactionsSubscription = _walletService
          .watchRecentTransactions(limit: 5)
          .listen((transactions) {
            _recentTransactions = transactions;
            _transactionsLastUpdated = DateTime.now();
            _cacheTransactionData();
            notifyListeners();
          });
    } catch (e) {
      debugPrint("Error setting up real-time subscriptions: $e");
    }
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isConnected = await _networkService.isConnected();
      _isOffline = !isConnected;

      if (isConnected) {
        await _fetchFromNetwork();
      } else {
        await _loadFromCache();
      }
    } catch (e) {
      debugPrint("Error loading dashboard: $e");

      if (!_cacheLoaded) {
        await _loadFromCache();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchFromNetwork() async {
    try {
      // 1. Fetch Profile
      final user =
          _authService.isAuthenticated() ? _authService.getCurrentUser() : null;
      if (user != null) {
        final userData = await _authService.getUserProfile();
        if (userData != null) {
          _fullName = userData['full_name'] ?? 'User';
          _profilePictureUrl = userData['avatar_url'];
          _profileLastUpdated = DateTime.now();
        }
      }

      // 2. Fetch Wallet
      try {
        _wallet = await _walletService.getWallet();
        _walletLastUpdated = DateTime.now();
      } catch (e) {
        debugPrint("Error fetching wallet: $e");
        // Create a default wallet if none exists
        _wallet = Wallet(
          userId: user?.id ?? '',
          currentBalance: 0.0,
          availableBalance: 0.0,
          lockedBalance: 0.0,
          totalEarned: 0.0,
          totalDeposited: 0.0,
          totalWithdrawn: 0.0,
          totalSpent: 0.0,
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // 3. Fetch Tasks
      try {
        final allTasks = await _taskService.getAvailableTasks(
          forceRefresh: true,
        );
        _tasks =
            allTasks
                .where(
                  (task) =>
                      task.category.toLowerCase() == 'advert' ||
                      task.category.toLowerCase() == 'engagement',
                )
                .toList();
        _tasksLastUpdated = DateTime.now();
      } catch (e) {
        debugPrint("Error fetching tasks: $e");
      }

      // 4. Fetch Recent Transactions
      try {
        _recentTransactions = await _walletService.getRecentTransactions(
          limit: 5,
        );
        _transactionsLastUpdated = DateTime.now();
      } catch (e) {
        debugPrint("Error fetching transactions: $e");
      }

      // 5. Update cache
      await _cacheAllData();
      _cacheLoaded = true;
    } catch (e) {
      debugPrint("Error fetching from network: $e");

      if (!_cacheLoaded) {
        await _loadFromCache();
      }
    }
  }

  Future<void> _cacheAllData() async {
    try {
      // Cache wallet data
      if (_wallet != null) {
        final walletMap = {
          'current_balance': _wallet!.currentBalance,
          'available_balance': _wallet!.availableBalance,
          'locked_balance': _wallet!.lockedBalance,
          'total_earned': _wallet!.totalEarned,
          'total_deposited': _wallet!.totalDeposited,
          'total_withdrawn': _wallet!.totalWithdrawn,
          'total_spent': _wallet!.totalSpent,
          'status': _wallet!.status,
          'formattedBalance': _wallet!.formattedBalance,
        };
        await _cacheService.cacheWallet(walletMap);
      }

      // Cache profile
      await _cacheService.cacheProfile({
        'full_name': _fullName,
        'profile_picture_url': _profilePictureUrl,
      });

      // Cache tasks
      await _cacheService.cacheTasks(_tasks);

      // Cache transactions
      final transactionMaps =
          _recentTransactions.map((t) {
            return {
              'id': t.id,
              'amount': t.amount,
              'transaction_type': t.type,
              'status': t.status,
              'description': t.description,
              'reference_id': t.referenceId,
              'created_at': t.createdAt.toIso8601String(),
              'formattedDate': t.formattedDate,
              'formattedTime': t.formattedTime,
              'formattedAmount': t.formattedAmount,
              'isCredit': t.isCredit,
            };
          }).toList();
      await _cacheService.cacheTransactions(transactionMaps);
    } catch (e) {
      debugPrint("Error caching data: $e");
    }
  }

  Future<void> _cacheWalletData() async {
    if (_wallet != null) {
      final walletMap = {
        'current_balance': _wallet!.currentBalance,
        'available_balance': _wallet!.availableBalance,
        'locked_balance': _wallet!.lockedBalance,
        'total_earned': _wallet!.totalEarned,
        'total_deposited': _wallet!.totalDeposited,
        'total_withdrawn': _wallet!.totalWithdrawn,
        'total_spent': _wallet!.totalSpent,
        'status': _wallet!.status,
        'formattedBalance': _wallet!.formattedBalance,
      };
      await _cacheService.cacheWallet(walletMap);
    }
  }

  Future<void> _cacheTransactionData() async {
    final transactionMaps =
        _recentTransactions.map((t) {
          return {
            'id': t.id,
            'amount': t.amount,
            'transaction_type': t.type,
            'status': t.status,
            'description': t.description,
            'reference_id': t.referenceId,
            'created_at': t.createdAt.toIso8601String(),
            'formattedDate': t.formattedDate,
            'formattedTime': t.formattedTime,
            'formattedAmount': t.formattedAmount,
            'isCredit': t.isCredit,
          };
        }).toList();
    await _cacheService.cacheTransactions(transactionMaps);
  }

  Future<void> _loadFromCache() async {
    try {
      // 1. Load Profile from cache
      final cachedProfile = await _cacheService.getCachedProfile();
      _fullName = cachedProfile['full_name'] ?? 'User';
      _profilePictureUrl = cachedProfile['profile_picture_url'];

      // 2. Load Wallet from cache
      final cachedWallet = await _cacheService.getCachedWallet();
      if (cachedWallet.isNotEmpty) {
        final user =
            _authService.isAuthenticated()
                ? _authService.getCurrentUser()
                : null;
        _wallet = Wallet(
          userId: user?.id ?? '',
          currentBalance:
              (cachedWallet['current_balance'] as num?)?.toDouble() ?? 0.0,
          availableBalance:
              (cachedWallet['available_balance'] as num?)?.toDouble() ?? 0.0,
          lockedBalance:
              (cachedWallet['locked_balance'] as num?)?.toDouble() ?? 0.0,
          totalEarned:
              (cachedWallet['total_earned'] as num?)?.toDouble() ?? 0.0,
          totalDeposited:
              (cachedWallet['total_deposited'] as num?)?.toDouble() ?? 0.0,
          totalWithdrawn:
              (cachedWallet['total_withdrawn'] as num?)?.toDouble() ?? 0.0,
          totalSpent: (cachedWallet['total_spent'] as num?)?.toDouble() ?? 0.0,
          status: cachedWallet['status']?.toString() ?? 'inactive',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // 3. Load Tasks from cache
      _tasks = await _cacheService.getCachedTasks();

      // 4. Load Transactions from cache
      final cachedTransactionMaps = await _cacheService.getCachedTransactions();
      _recentTransactions =
          cachedTransactionMaps.map((map) {
            try {
              return Transaction(
                id: map['id'] ?? 0,
                userId: '', // Will be filled when we have user data
                amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
                type: map['transaction_type']?.toString() ?? 'UNKNOWN',
                status: map['status']?.toString() ?? 'PENDING',
                description: map['description']?.toString() ?? '',
                referenceId: map['reference_id']?.toString() ?? '',
                createdAt:
                    DateTime.tryParse(map['created_at']?.toString() ?? '') ??
                    DateTime.now(),
                updatedAt: DateTime.now(),
                netAmount: (map['amount'] as num?)?.toDouble() ?? 0.0,
              );
            } catch (e) {
              debugPrint("Error converting cached transaction: $e");
              return Transaction(
                id: 0,
                userId: '',
                amount: 0.0,
                type: 'UNKNOWN',
                status: 'PENDING',
                description: '',
                referenceId: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                netAmount: 0.0,
              );
            }
          }).toList();

      _cacheLoaded = true;

      // Update timestamps
      _profileLastUpdated = await _cacheService.getLastUpdateTime('profile');
      _walletLastUpdated = await _cacheService.getLastUpdateTime('wallet');
      _tasksLastUpdated = await _cacheService.getLastUpdateTime('tasks');
      _transactionsLastUpdated = await _cacheService.getLastUpdateTime(
        'transactions',
      );
    } catch (e) {
      debugPrint("Error loading from cache: $e");
      _cacheLoaded = false;
    }
  }

  Future<void> _refreshNetworkData() async {
    final isTasksStale =
        _tasksLastUpdated == null ||
        DateTime.now().difference(_tasksLastUpdated!) >
            const Duration(minutes: 5);

    if (isTasksStale) {
      try {
        await _fetchFromNetwork();
        notifyListeners();
      } catch (e) {
        debugPrint("Error refreshing network data: $e");
      }
    }
  }

  Future<void> refreshAll({bool force = false}) async {
    final isConnected = await _networkService.isConnected();

    if (isConnected) {
      _isLoading = true;
      notifyListeners();

      try {
        if (force) {
          await _fetchFromNetwork();
        } else {
          await _refreshNetworkData();
        }
      } catch (e) {
        debugPrint("Error in refreshAll: $e");
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      await _loadFromCache();
    }
  }

  Future<void> refreshWallet() async {
    if (!_isOffline) {
      try {
        _wallet = await _walletService.getWallet();
        await _cacheWalletData();
        _walletLastUpdated = DateTime.now();
        notifyListeners();
      } catch (e) {
        debugPrint("Error refreshing wallet: $e");
      }
    }
  }

  Future<void> refreshTransactions() async {
    if (!_isOffline) {
      try {
        _recentTransactions = await _walletService.getRecentTransactions(
          limit: 5,
        );
        await _cacheTransactionData();
        _transactionsLastUpdated = DateTime.now();
        notifyListeners();
      } catch (e) {
        debugPrint("Error refreshing transactions: $e");
      }
    }
  }

  Map<String, dynamic> getCacheStatus() {
    return {
      'is_offline': _isOffline,
      'cache_loaded': _cacheLoaded,
      'tasks_count': _tasks.length,
      'wallet_balance': _wallet?.currentBalance ?? 0.0,
      'transactions_count': _recentTransactions.length,
      'tasks_last_updated': _tasksLastUpdated?.toIso8601String(),
      'wallet_last_updated': _walletLastUpdated?.toIso8601String(),
      'profile_last_updated': _profileLastUpdated?.toIso8601String(),
      'transactions_last_updated': _transactionsLastUpdated?.toIso8601String(),
    };
  }

  Future<void> clearCache() async {
    await _cacheService.clearCache();
    _cacheLoaded = false;
    _tasks.clear();
    _recentTransactions.clear();
    _wallet = null;
    _fullName = 'User';
    _profilePictureUrl = null;
    notifyListeners();
  }

  // Navigation methods
  void navigateToTaskDetails(BuildContext context, TaskModel task) {
    Navigator.pushNamed(context, '/task-details', arguments: task.toMap());
  }

  void navigateToFundWallet(BuildContext context) {
    Navigator.pushNamed(context, '/fund-wallet');
  }

  void navigateToWithdraw(BuildContext context) {
    Navigator.pushNamed(context, '/withdraw');
  }

  void navigateToAllTasks(BuildContext context) {
    Navigator.pushNamed(context, '/tasks');
  }

  void navigateToAdvertUpload(BuildContext context) {
    Navigator.pushNamed(context, '/advert-upload');
  }

  void navigateToEarnSelection(BuildContext context) {
    Navigator.pushNamed(context, '/earn-selection');
  }

  // ============ HELPER METHODS ============

  IconData getPlatformIcon(String platform) =>
      PlatformHelper.getPlatformIcon(platform);
  Color getPlatformColor(String platform) =>
      PlatformHelper.getPlatformColor(platform);
  String getPlatformDisplayName(String platform) =>
      PlatformHelper.getPlatformDisplayName(platform);
  IconData getTaskCategoryIcon(String category) =>
      TaskHelper.getTaskCategoryIcon(category);
  Color getTaskCategoryColor(String category) =>
      TaskHelper.getTaskCategoryColor(category);
  String getTaskCategoryDisplayName(String category) =>
      TaskHelper.getTaskCategoryDisplayName(category);

  IconData getTaskIcon(TaskModel task) {
    return TaskHelper.getTaskCategoryIcon(task.category);
  }

  List<String> getSupportedPlatformsForCategory(String taskCategory) {
    return TaskHelper.getSupportedPlatforms(taskCategory);
  }

  bool validatePlatformForTask(String taskType, String platform) {
    return TaskHelper.validateTaskForPlatform(taskType, platform);
  }

  IconData getTransactionIcon(String transactionType) {
    return WalletService.getTransactionIcon(transactionType);
  }

  Color getTransactionColor(String transactionType) {
    switch (transactionType.toUpperCase()) {
      case 'DEPOSIT':
      case 'TASK_EARNING':
      case 'REFUND':
      case 'TRANSFER_IN':
      case 'BONUS':
        return Colors.green;
      case 'WITHDRAWAL':
      case 'ORDER_PAYMENT':
      case 'ADVERT_FEE':
      case 'MEMBERSHIP_PAYMENT':
      case 'TRANSFER_OUT':
      case 'FEE':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String formatCurrency(double amount) => '₦${amount.toStringAsFixed(2)}';

  String formatTransactionType(String type) {
    return WalletService.formatTransactionType(type);
  }

  String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 365)
      return '${(difference.inDays / 365).floor()}y ago';
    if (difference.inDays > 30)
      return '${(difference.inDays / 30).floor()}mo ago';
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  Future<Map<String, dynamic>> checkBalanceForPurchase(double amount) async {
    try {
      return await _walletService.checkBalance(amount);
    } catch (e) {
      return {
        'success': false,
        'has_sufficient': false,
        'current_balance': _wallet?.currentBalance ?? 0.0,
        'available_balance': _wallet?.availableBalance ?? 0.0,
        'required_amount': amount,
        'deficit': amount,
        'isWalletLocked': _wallet?.isLocked ?? false,
      };
    }
  }

  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final dashboardStats = await _walletService.getDashboardStats();
      return {
        'wallet': dashboardStats.wallet.toJson(),
        'stats': {
          'today_income': dashboardStats.today.totalIncome,
          'today_expenses': dashboardStats.today.totalExpenses,
          'week_income': dashboardStats.week.totalIncome,
          'week_expenses': dashboardStats.week.totalExpenses,
          'month_income': dashboardStats.month.totalIncome,
          'month_expenses': dashboardStats.month.totalExpenses,
          'transaction_count': dashboardStats.month.transactionCount,
        },
      };
    } catch (e) {
      debugPrint("Error getting user statistics: $e");
      return {
        'wallet': _wallet?.toJson() ?? {},
        'stats': {
          'today_income': 0.0,
          'today_expenses': 0.0,
          'week_income': 0.0,
          'week_expenses': 0.0,
          'month_income': 0.0,
          'month_expenses': 0.0,
          'transaction_count': 0,
        },
      };
    }
  }

  void clearData() {
    _wallet = null;
    _tasks.clear();
    _recentTransactions.clear();
    _fullName = 'User';
    _profilePictureUrl = null;
    notifyListeners();
  }

  // ============ TASK MANAGEMENT METHODS ============

  List<TaskModel> getFeaturedTasks() =>
      _tasks.where((task) => task.isFeatured).toList();

  List<TaskModel> getTasksByCategory(String category) {
    return _tasks
        .where((task) => task.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  List<TaskModel> getTasksByPlatform(String platform) {
    return _tasks.where((task) => task.platforms.contains(platform)).toList();
  }

  List<TaskModel> searchTasks(String query) {
    if (query.isEmpty) return _tasks;
    final queryLower = query.toLowerCase();
    return _tasks.where((task) {
      return task.title.toLowerCase().contains(queryLower) ||
          task.description.toLowerCase().contains(queryLower) ||
          task.tags.any((tag) => tag.toLowerCase().contains(queryLower));
    }).toList();
  }

  TaskModel? getTaskById(String taskId) {
    try {
      return _tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> getTaskPricingInfo(TaskModel task) {
    final pricing = TaskHelper.getTaskPricingSuggestions(task.category);
    return {
      'unit_price': task.price,
      'pricing_range': {
        'min': pricing['min_price'] as double,
        'max': pricing['max_price'] as double,
        'suggested': pricing['suggested_price'] as double,
        'unit': pricing['price_unit'] as String,
      },
    };
  }

  Map<String, dynamic> getTaskRequirements(TaskModel task) =>
      TaskHelper.getTaskRequirements(task.category);

  String getTaskCompletionTime(TaskModel task, int quantity) =>
      TaskHelper.getTaskCompletionTime(task.category, quantity);

  String getTaskDescriptionTemplate(TaskModel task, String platform) =>
      TaskHelper.getTaskDescriptionTemplate(task.category, platform);

  dynamic getTaskMetadata(TaskModel task, String key, [dynamic defaultValue]) =>
      task.metadata[key] ?? defaultValue;

  bool hasTaskMetadata(TaskModel task, String key) =>
      task.metadata.containsKey(key);

  // ============ PLATFORM METHODS ============

  Widget getPlatformWidget({
    required String platform,
    double iconSize = 24.0,
    bool showLabel = false,
    TextStyle? labelStyle,
    bool circleBackground = false,
  }) {
    return PlatformHelper.getPlatformWidget(
      platform: platform,
      iconSize: iconSize,
      showLabel: showLabel,
      labelStyle: labelStyle,
      circleBackground: circleBackground,
    );
  }

  Widget getPlatformChip({
    required String platform,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    return PlatformHelper.getPlatformChip(
      platform: platform,
      onTap: onTap,
      selected: selected,
    );
  }

  List<String> getAllPlatforms() => PlatformHelper.getAllPlatforms();
  List<String> getPlatformsByCategory(String category) =>
      PlatformHelper.getPlatformsByCategory(category);
  Map<String, dynamic> getPlatformMetadata(String platform) =>
      PlatformHelper.getPlatformMetadata(platform);

  // ============ UTILITY METHODS ============

  Map<String, dynamic> taskToMap(TaskModel task) => task.toMap();
  List<Map<String, dynamic>> tasksToMaps(List<TaskModel> tasks) =>
      tasks.map((task) => task.toMap()).toList();

  Map<String, int> getTaskCountByCategory() {
    final Map<String, int> counts = {};
    for (final task in _tasks) {
      counts[task.category] = (counts[task.category] ?? 0) + 1;
    }
    return counts;
  }

  double getTotalTasksValue() =>
      _tasks.fold(0.0, (sum, task) => sum + task.price);

  List<TaskModel> getTasksSortedByPrice({bool descending = true}) {
    final List<TaskModel> sorted = List.from(_tasks);
    sorted.sort(
      (a, b) =>
          descending ? b.price.compareTo(a.price) : a.price.compareTo(b.price),
    );
    return sorted;
  }

  List<TaskModel> getTasksSortedByDate({bool descending = true}) {
    final List<TaskModel> sorted = List.from(_tasks);
    sorted.sort(
      (a, b) =>
          descending
              ? b.createdAt.compareTo(a.createdAt)
              : a.createdAt.compareTo(b.createdAt),
    );
    return sorted;
  }

  List<TaskModel> filterTasks({
    String? category,
    List<String>? categories,
    String? platform,
    double? minPrice,
    double? maxPrice,
    bool? featuredOnly,
    List<String>? tags,
    String? searchQuery,
  }) {
    return _tasks.where((task) {
      if (category != null && task.category != category) return false;
      if (categories != null && !categories.contains(task.category)) {
        return false;
      }
      if (platform != null && !task.platforms.contains(platform)) return false;
      if (minPrice != null && task.price < minPrice) return false;
      if (maxPrice != null && task.price > maxPrice) return false;
      if (featuredOnly == true && !task.isFeatured) return false;
      if (tags != null && !tags.any((tag) => task.tags.contains(tag))) {
        return false;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query) ||
            task.tags.any((tag) => tag.toLowerCase().contains(query));
      }
      return true;
    }).toList();
  }

  List<String> getAllUniqueTags() {
    final Set<String> uniqueTags = {};
    for (final task in _tasks) {
      uniqueTags.addAll(task.tags);
    }
    return uniqueTags.toList()..sort();
  }

  List<TaskModel> getTasksWithMetadata(String metadataKey) {
    return _tasks
        .where((task) => task.metadata.containsKey(metadataKey))
        .toList();
  }

  double getAverageTaskPrice() {
    if (_tasks.isEmpty) return 0.0;
    return getTotalTasksValue() / _tasks.length;
  }

  List<TaskModel> getNewestTasks({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _tasks.where((task) => task.createdAt.isAfter(cutoffDate)).toList();
  }

  Map<String, List<TaskModel>> getTasksGroupedByCategory() {
    final Map<String, List<TaskModel>> grouped = {};
    for (final task in _tasks) {
      grouped.putIfAbsent(task.category, () => []).add(task);
    }
    return grouped;
  }

  Map<String, List<TaskModel>> getTasksGroupedByPlatform() {
    final Map<String, List<TaskModel>> grouped = {};
    for (final task in _tasks) {
      for (final platform in task.platforms) {
        grouped.putIfAbsent(platform, () => []).add(task);
      }
    }
    return grouped;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _networkService.dispose();
    super.dispose();
  }
}
