import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  void listenToConnectivityChanges(Function(bool) onConnectivityChanged) {
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      onConnectivityChanged(!result.contains(ConnectivityResult.none));
    });
  }
}
