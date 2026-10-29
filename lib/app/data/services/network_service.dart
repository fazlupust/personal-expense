import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkService extends GetxService {
  static NetworkService get to => Get.find();

  final RxBool isOnline = true.obs;
  Timer? _pollingTimer;
  bool _initialized = false;
  DateTime? _lastOfflineSnackbarAt;

  @override
  void onInit() {
    super.onInit();
    _startMonitoring();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  void _startMonitoring() {
    // Initial check after app finishes rendering first screen
    Future.delayed(const Duration(seconds: 2), () async {
      final connected = await checkConnection();
      _initialized = true;
      if (!connected) {
        _handleStatusChange(false);
      }
    });

    // Periodic check every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final connected = await checkConnection();
      if (!_initialized) {
        _initialized = true;
      }
      if (connected != isOnline.value) {
        _handleStatusChange(connected);
      }
    });
  }

  Future<bool> checkConnection() async {
    final first = await _probeNetwork();
    if (first) return true;
    // Retry once after 600ms to avoid transient false positives
    await Future.delayed(const Duration(milliseconds: 600));
    return await _probeNetwork();
  }

  Future<bool> _probeNetwork() async {
    try {
      final res = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (res.isNotEmpty && res[0].rawAddress.isNotEmpty) return true;
    } catch (_) {}

    try {
      final res = await InternetAddress.lookup('cloudflare.com')
          .timeout(const Duration(seconds: 3));
      if (res.isNotEmpty && res[0].rawAddress.isNotEmpty) return true;
    } catch (_) {}

    return false;
  }

  void _handleStatusChange(bool connected) {
    final wasOnline = isOnline.value;
    isOnline.value = connected;

    if (!connected) {
      _showNoInternetSnackbar();
    } else if (!wasOnline) {
      _showBackOnlineSnackbar();
    }
  }

  void _showNoInternetSnackbar() {
    final now = DateTime.now();
    if (_lastOfflineSnackbarAt != null &&
        now.difference(_lastOfflineSnackbarAt!).inSeconds < 10) {
      return;
    }
    _lastOfflineSnackbarAt = now;

    if (Get.context != null) {
      Get.snackbar(
        'No Internet Connection'.tr,
        'Please check your internet settings.'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 26),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 12,
        isDismissible: true,
      );
    }
  }

  void _showBackOnlineSnackbar() {
    if (Get.context != null) {
      Get.snackbar(
        'Back Online'.tr,
        'Internet connection restored.'.tr,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1F8A5B),
        colorText: Colors.white,
        icon: const Icon(Icons.wifi_rounded, color: Colors.white, size: 26),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 12,
        isDismissible: true,
      );
    }
  }

  /// Manually force a check and show snackbar if offline
  Future<bool> ensureConnectedWithSnackbar() async {
    final connected = await checkConnection();
    if (!connected) {
      _showNoInternetSnackbar();
    }
    return connected;
  }
}
