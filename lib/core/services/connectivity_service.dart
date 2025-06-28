
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  ConnectivityService() {
    _checkInitialConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) => _updateConnectionStatus(result));
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final hasConnection = result == ConnectivityResult.mobile ||
                           result == ConnectivityResult.wifi;
    if (isConnected.value != hasConnection) {
      isConnected.value = hasConnection;
      notifyListeners();
    }
  }

  void dispose() {
    _connectivitySubscription.cancel();
    isConnected.dispose();
  }
}
