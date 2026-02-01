// services/cache_service.dart
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task_models.dart';
import '../adapters/task_model_adapter.dart'; // Import adapter
import 'package:flutter/foundation.dart';

class CacheService {
  static const String tasksBox = 'tasks_box';
  static const String walletBox = 'wallet_box';
  static const String profileBox = 'profile_box';
  static const String transactionsBox = 'transactions_box';
  static const String cacheTimestampBox = 'cache_timestamp_box';

  late Box<TaskModelAdapter> _tasksBox; // Updated type
  late Box<Map<String, dynamic>> _walletBox;
  late Box<Map<String, dynamic>> _profileBox;
  late Box<List<Map<String, dynamic>>> _transactionsBox;
  late Box<String> _cacheTimestampBox;

  bool _isInitialized = false;

  Future<void> init() async {
    try {
      print("🔄 CacheService: Starting initialization...");
      
      // Register adapter here
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TaskModelAdapterAdapter());
        print("✅ CacheService: Adapter registered");
      }

      // Open boxes with correct types
      _tasksBox = await Hive.openBox<TaskModelAdapter>('tasks_box');
      print("✅ CacheService: Tasks box opened");
      
      _walletBox = await Hive.openBox<Map<String, dynamic>>('wallet_box');
      print("✅ CacheService: Wallet box opened");
      
      _profileBox = await Hive.openBox<Map<String, dynamic>>('profile_box');
      print("✅ CacheService: Profile box opened");
      
      _transactionsBox = await Hive.openBox<List<Map<String, dynamic>>>('transactions_box');
      print("✅ CacheService: Transactions box opened");
      
      _cacheTimestampBox = await Hive.openBox<String>('cache_timestamp_box');
      print("✅ CacheService: Cache timestamp box opened");
      
      _isInitialized = true;
      print("✅ CacheService: Initialization complete");
    } catch (e, stackTrace) {
      print("❌ CacheService: Initialization failed: $e");
      print("Stack trace: $stackTrace");
      throw e; // Re-throw to handle in main
    }
  }

  // Tasks caching - Convert TaskModel to TaskModelAdapter for storage
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    if (!_isInitialized) return;
    
    try {
      await _tasksBox.clear();
      for (var task in tasks) {
        final adapter = TaskModelAdapter.fromTaskModel(task);
        await _tasksBox.put(task.id, adapter);
      }
      await _cacheTimestampBox.put('tasks_last_updated', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching tasks: $e');
    }
  }

  Future<List<TaskModel>> getCachedTasks() async {
    if (!_isInitialized) return [];
    
    try {
      final adapters = _tasksBox.values.toList();
      return adapters.map((adapter) => adapter.toTaskModel()).toList();
    } catch (e) {
      print('Error getting cached tasks: $e');
      return [];
    }
  }

  Future<void> cacheWallet(Map<String, dynamic> wallet) async {
    if (!_isInitialized) return;
    
    try {
      await _walletBox.put('wallet_data', wallet);
      await _cacheTimestampBox.put('wallet_last_updated', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching wallet: $e');
    }
  }

  Future<void> saveAppState() async {
    if (!_isInitialized) return;
    
    try {
      await _tasksBox.flush();
    } catch (e) {
      print('Error saving app state: $e');
    }
  }
  
  void cleanup() {
    // Optional: Clean up any temporary data
  }

  Future<Map<String, dynamic>> getCachedWallet() async {
    if (!_isInitialized) {
      return getDefaultWallet();
    }
    
    try {
      final walletData = _walletBox.get('wallet_data');

      if (walletData == null) {
        return getDefaultWallet();
      }

      return walletData;
    } catch (e) {
      print('Error getting cached wallet: $e');
      return getDefaultWallet();
    }
  }

  Map<String, dynamic> getDefaultWallet() {
    return {
      'balance': 0.0,
      'totalEarned': 0.0,
      'amountSpent': 0.0,
      'pendingBalance': 0.0,
    };
  }
  
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    if (!_isInitialized) return;
    
    try {
      await _profileBox.put('profile_data', profile);
      await _cacheTimestampBox.put('profile_last_updated', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching profile: $e');
    }
  }

  Future<Map<String, dynamic>> getCachedProfile() async {
    if (!_isInitialized) {
      return getDefaultProfile();
    }
    
    try {
      final profileData = _profileBox.get('profile_data');

      if (profileData == null) {
        return getDefaultProfile();
      }

      return profileData;
    } catch (e) {
      print('Error getting cached profile: $e');
      return getDefaultProfile();
    }
  }

  Map<String, dynamic> getDefaultProfile() {
    return {
      'full_name': 'User',
      'profile_picture_url': null,
      'email': '',
      'phone': ''
    };
  }

  Future<void> cacheTransactions(List<Map<String, dynamic>> transactions) async {
    if (!_isInitialized) return;
    
    try {
      await _transactionsBox.put('transactions_data', transactions);
      await _cacheTimestampBox.put('transactions_last_updated', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching transactions: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedTransactions() async {
    if (!_isInitialized) return [];
    
    try {
      final transactionsData = _transactionsBox.get('transactions_data');
      return transactionsData ?? [];
    } catch (e) {
      print('Error getting cached transactions: $e');
      return [];
    }
  }

  // Add these methods to your CacheService class

  Future<void> cacheWorkerTasks(List<Map<String, dynamic>> tasks) async {
    try {
      final box = await Hive.openBox<Map<String, dynamic>>(
        'worker_tasks_cache',
      );
      await box.put('worker_tasks', {
        'tasks': tasks,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await box.close();
    } catch (e) {
      debugPrint('Error caching worker tasks: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedWorkerTasks() async {
    try {
      final box = await Hive.openBox<Map<String, dynamic>>(
        'worker_tasks_cache',
      );
      final data = box.get('worker_tasks');
      await box.close();

      if (data != null && data['tasks'] is List) {
        final List<dynamic> taskList = data['tasks'];
        return taskList.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('Error getting cached worker tasks: $e');
    }
    return [];
  }

  Future<DateTime?> getLastUpdateTime(String key) async {
    if (!_isInitialized) return null;
    
    try {
      final timestamp = _cacheTimestampBox.get('${key}_last_updated');
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      print('Error getting last update time: $e');
      return null;
    }
  }

  Future<bool> isCacheExpired(String key, {Duration maxAge = const Duration(minutes: 5)}) async {
    if (!_isInitialized) return true;
    
    try {
      final lastUpdate = await getLastUpdateTime(key);
      if (lastUpdate == null) return true;
      
      final age = DateTime.now().difference(lastUpdate);
      return age > maxAge;
    } catch (e) {
      print('Error checking cache expiration: $e');
      return true;
    }
  }

  Future<void> clearCache() async {
    if (!_isInitialized) return;
    
    try {
      await _tasksBox.clear();
      await _walletBox.clear();
      await _profileBox.clear();
      await _transactionsBox.clear();
      await _cacheTimestampBox.clear();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<int> getCacheSize() async {
    if (!_isInitialized) return 0;
    
    try {
      return _tasksBox.length + _walletBox.length + _profileBox.length + _transactionsBox.length;
    } catch (e) {
      print('Error getting cache size: $e');
      return 0;
    }
  }

  // NEW: Cache individual task
  Future<void> cacheTask(TaskModel task) async {
    if (!_isInitialized) return;
    
    try {
      final adapter = TaskModelAdapter.fromTaskModel(task);
      await _tasksBox.put(task.id, adapter);
    } catch (e) {
      print('Error caching individual task: $e');
    }
  }

  // NEW: Get specific task from cache by ID
  Future<TaskModel?> getCachedTaskById(String taskId) async {
    if (!_isInitialized) return null;
    
    try {
      final adapter = _tasksBox.get(taskId);
      return adapter?.toTaskModel();
    } catch (e) {
      print('Error getting cached task by ID: $e');
      return null;
    }
  }

  // NEW: Remove specific task from cache
  Future<void> removeCachedTask(String taskId) async {
    if (!_isInitialized) return;
    
    try {
      await _tasksBox.delete(taskId);
    } catch (e) {
      print('Error removing cached task: $e');
    }
  }

  // NEW: Get cache info
  Map<String, dynamic> getCacheInfo() {
    if (!_isInitialized) {
      return {
        'initialized': false,
        'tasks_count': 0,
        'wallet_cached': false,
        'profile_cached': false,
        'transactions_count': 0,
        'cache_size': 0,
      };
    }
    
    try {
      return {
        'initialized': true,
        'tasks_count': _tasksBox.length,
        'wallet_cached': _walletBox.containsKey('wallet_data'),
        'profile_cached': _profileBox.containsKey('profile_data'),
        'transactions_count': (_transactionsBox.get('transactions_data', defaultValue: []) as List).length,
        'cache_size': getCacheSize(),
      };
    } catch (e) {
      print('Error getting cache info: $e');
      return {
        'initialized': false,
        'error': e.toString(),
      };
    }
  }

  // NEW: Check if cache has been initialized
  bool isInitialized() {
    return _isInitialized && 
           _tasksBox.isOpen && 
           _walletBox.isOpen && 
           _profileBox.isOpen && 
           _transactionsBox.isOpen;
  }

  // NEW: Close all boxes (call on app exit)
  Future<void> close() async {
    if (!_isInitialized) return;
    
    try {
      await _tasksBox.close();
      await _walletBox.close();
      await _profileBox.close();
      await _transactionsBox.close();
      await _cacheTimestampBox.close();
      _isInitialized = false;
    } catch (e) {
      print('Error closing cache boxes: $e');
    }
  }
}