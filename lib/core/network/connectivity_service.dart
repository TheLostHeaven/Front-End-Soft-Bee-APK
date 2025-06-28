import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<ConnectivityResult> get connectivityStream => _connectivity.onConnectivityChanged;

  Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void listenToConnectivityChanges(Function(bool) onConnectivityChanged) {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      onConnectivityChanged(result != ConnectivityResult.none);
    });
  }
}
