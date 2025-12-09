import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Network Status Monitor
class NetworkStatus {
  static final _connectivity = Connectivity();
  static StreamSubscription? _subscription;
  static bool _isOnline = true;

  static bool get isOnline => _isOnline;

  static Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = !result.contains(ConnectivityResult.none);
    });
  }

  static Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  static void dispose() {
    _subscription?.cancel();
  }
}
