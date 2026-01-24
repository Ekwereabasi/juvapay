// services/cache_service.dart
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task_models.dart';
import '../adapters/task_model_adapter.dart'; // Import adapter

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

  // Future<void> init() async {
  //   final appDocumentDir = await getApplicationDocumentsDirectory();
  //   Hive.init(appDocumentDir.path);
    
  //   // Open boxes with correct types
  //   _tasksBox = await Hive.openBox<TaskModelAdapter>(tasksBox);
  //   _walletBox = await Hive.openBox<Map<String, dynamic>>(walletBox);
  //   _profileBox = await Hive.openBox<Map<String, dynamic>>(profileBox);
  //   _transactionsBox = await Hive.openBox<List<Map<String, dynamic>>>(transactionsBox);
  //   _cacheTimestampBox = await Hive.openBox<String>(cacheTimestampBox);
  // }

    Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDir.path);

    // Register adapter here
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(
        TaskModelAdapterAdapter(),
      ); // Use generated adapter name
    }

    // Open boxes with correct types
    _tasksBox = await Hive.openBox<TaskModelAdapter>('tasks_box');
    _walletBox = await Hive.openBox<Map<String, dynamic>>('wallet_box');
    _profileBox = await Hive.openBox<Map<String, dynamic>>('profile_box');
    _transactionsBox = await Hive.openBox<List<Map<String, dynamic>>>(
      'transactions_box',
    );
    _cacheTimestampBox = await Hive.openBox<String>('cache_timestamp_box');
  }

  // Tasks caching - Convert TaskModel to TaskModelAdapter for storage
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    await _tasksBox.clear();
    for (var task in tasks) {
      final adapter = TaskModelAdapter.fromTaskModel(task);
      await _tasksBox.put(task.id, adapter);
    }
    await _cacheTimestampBox.put('tasks_last_updated', DateTime.now().toIso8601String());
  }

  Future<List<TaskModel>> getCachedTasks() async {
    try {
      final adapters = _tasksBox.values.toList();
      return adapters.map((adapter) => adapter.toTaskModel()).toList();
    } catch (e) {
      print('Error getting cached tasks: $e');
      return [];
    }
  }

  Future<void> cacheWallet(Map<String, dynamic> wallet) async {
    await _walletBox.put('wallet_data', wallet);
    await _cacheTimestampBox.put('wallet_last_updated', DateTime.now().toIso8601String());
  }

  Future<Map<String, dynamic>> getCachedWallet() async {
    final walletData = _walletBox.get('wallet_data');

    if (walletData == null) {
      // Return default values if no cached data exists
      final defaultWallet = {
        'balance': 0.0,
        'totalEarned': 0.0,
        'amountSpent': 0.0,
        'pendingBalance': 0.0,
      };
      // Optionally cache the default values
      await _walletBox.put('wallet_data', defaultWallet);
      return defaultWallet;
    }

    return walletData;
  }

  
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    await _profileBox.put('profile_data', profile);
    await _cacheTimestampBox.put('profile_last_updated', DateTime.now().toIso8601String());
  }

 Future<Map<String, dynamic>> getCachedProfile() async {
    final profileData = _profileBox.get('profile_data');

    if (profileData == null) {
      // Return default values if no cached data exists
      final defaultProfile = {'full_name': 'User', 'profile_picture_url': null};
      // Optionally cache the default values
      await _profileBox.put('profile_data', defaultProfile);
      return defaultProfile;
    }

    return profileData;
  }


  Future<void> cacheTransactions(List<Map<String, dynamic>> transactions) async {
    await _transactionsBox.put('transactions_data', transactions);
    await _cacheTimestampBox.put('transactions_last_updated', DateTime.now().toIso8601String());
  }

  Future<List<Map<String, dynamic>>> getCachedTransactions() async {
    final transactionsData = _transactionsBox.get('transactions_data');

    if (transactionsData == null) {
      // Return empty list if no cached data exists
      await _transactionsBox.put('transactions_data', []);
      return [];
    }

    return transactionsData;
  }


  Future<DateTime?> getLastUpdateTime(String key) async {
    final timestamp = _cacheTimestampBox.get('${key}_last_updated');
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  Future<bool> isCacheExpired(String key, {Duration maxAge = const Duration(minutes: 5)}) async {
    final lastUpdate = await getLastUpdateTime(key);
    if (lastUpdate == null) return true;
    
    final age = DateTime.now().difference(lastUpdate);
    return age > maxAge;
  }

  Future<void> clearCache() async {
    await _tasksBox.clear();
    await _walletBox.clear();
    await _profileBox.clear();
    await _transactionsBox.clear();
    await _cacheTimestampBox.clear();
  }

  Future<int> getCacheSize() async {
    return _tasksBox.length + _walletBox.length + _profileBox.length + _transactionsBox.length;
  }

  // NEW: Cache individual task
  Future<void> cacheTask(TaskModel task) async {
    try {
      final adapter = TaskModelAdapter.fromTaskModel(task);
      await _tasksBox.put(task.id, adapter);
    } catch (e) {
      print('Error caching individual task: $e');
    }
  }

  // NEW: Get specific task from cache by ID
  Future<TaskModel?> getCachedTaskById(String taskId) async {
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
    try {
      await _tasksBox.delete(taskId);
    } catch (e) {
      print('Error removing cached task: $e');
    }
  }

  // NEW: Get cache info
  Map<String, dynamic> getCacheInfo() {
    return {
      'tasks_count': _tasksBox.length,
      'wallet_cached': _walletBox.containsKey('wallet_data'),
      'profile_cached': _profileBox.containsKey('profile_data'),
      'transactions_count': (_transactionsBox.get('transactions_data', defaultValue: []) as List).length,
      'cache_size': getCacheSize(),
    };
  }

  // NEW: Check if cache has been initialized
  bool isInitialized() {
    return _tasksBox.isOpen && 
           _walletBox.isOpen && 
           _profileBox.isOpen && 
           _transactionsBox.isOpen;
  }

  // NEW: Close all boxes (call on app exit)
  Future<void> close() async {
    await _tasksBox.close();
    await _walletBox.close();
    await _profileBox.close();
    await _transactionsBox.close();
    await _cacheTimestampBox.close();
  }
}