import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class NetworkManager extends GetxController {
  static NetworkManager get instance => Get.find();

  final Connectivity _connectivity = Connectivity();
  final Rx<ConnectivityResult> _connectionStatus = ConnectivityResult.none.obs;

  /// Get current connection status (observable)
  ConnectivityResult get connectionStatus => _connectionStatus.value;

  @override
  void onInit() {
    super.onInit();
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    // Initialize current connection status
    initConnectivity();
  }

  /// Check connectivity on app start
  Future<void> initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } on PlatformException catch (e) {
      print('Couldn\'t check connectivity: $e');
    }
  }

  /// Update the connection status observable
  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionStatus.value = result;
  }

  /// Returns true if the device is connected to any network (Wi‑Fi or mobile)
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
}