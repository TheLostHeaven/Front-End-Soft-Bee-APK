
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  ConnectivityService() {
    _checkInitialConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) => _updateConnectionStatus(results));
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.first == ConnectivityResult.mobile ||
    results.first == ConnectivityResult.wifi;
    if (isConnected.value != hasConnection) {
      isConnected.value = hasConnection;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    isConnected.dispose();
    super.dispose();
  }
}
