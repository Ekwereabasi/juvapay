import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  
  NetworkService() {
    // Initialize the stream
    _initStream();
  }
  
  Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  Stream<bool> get connectivityStream => _connectionController.stream;
  
  void _initStream() async {
    // Emit initial connectivity status
    _connectionController.add(await isConnected());
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      _connectionController.add(result != ConnectivityResult.none);
    });
  }
  
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
  }
}