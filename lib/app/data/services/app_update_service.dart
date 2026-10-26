import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/widgets/app_update_dialog.dart';
import '../models/app_update_model.dart';

enum AppUpdateStatus { none, optional, forced }

class AppUpdateService extends GetxService {
  static AppUpdateService get to => Get.find<AppUpdateService>();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  AppUpdateModel? _pendingOptionalConfig;
  String _cachedCurrentVersion = '1.0.0';

  String get currentVersion => _cachedCurrentVersion;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadLocalVersion();
  }

  Future<void> _loadLocalVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _cachedCurrentVersion = info.version;
    } catch (e) {
      debugPrint('[AppUpdateService] Error getting PackageInfo: $e');
      _cachedCurrentVersion = '1.0.0';
    }
  }

  /// Compares semantic versions (e.g. 1.1.0 vs 1.0.0)
  /// Returns true if [remote] is strictly higher than [local].
  static bool isVersionHigher(String remote, String local) {
    try {
      List<int> parse(String v) {
        // Strip everything except numbers and dots
        final clean = v.replaceAll(RegExp(r'[^0-9.]'), '');
        if (clean.isEmpty) return [0];
        return clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      }

      final rParts = parse(remote);
      final lParts = parse(local);
      final maxLen = rParts.length > lParts.length ? rParts.length : lParts.length;

      for (int i = 0; i < maxLen; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final l = i < lParts.length ? lParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the update config document from Firestore: collection `app_config`, doc `version`.
  /// Automatically seeds default values if document does not exist yet.
  Future<AppUpdateModel?> fetchUpdateConfig() async {
    try {
      final docRef = _db.collection('app_config').doc('version');
      final snap = await docRef.get().timeout(const Duration(seconds: 4));

      if (!snap.exists || snap.data() == null) {
        // Seed initial config for convenience
        final initialModel = AppUpdateModel(
          isActive: true,
          isForceUpdate: false,
          latestVersion: _cachedCurrentVersion,
          minVersion: _cachedCurrentVersion,
          title: 'Update Available',
          message:
              'A new version of Personal Expense is available with new features and improvements. Please update now to continue enjoying the best experience.',
          playStoreUrl: 'https://play.google.com/store/apps/details?id=com.fazlu.personalexpense',
        );

        // Attempt write if permitted
        try {
          await docRef.set(initialModel.toMap());
        } catch (_) {}

        return initialModel;
      }

      return AppUpdateModel.fromMap(snap.data()!);
    } catch (e) {
      debugPrint('[AppUpdateService] fetchUpdateConfig error: $e');
      return null;
    }
  }

  /// Checks for updates during app startup (e.g. from SplashController)
  Future<AppUpdateStatus> checkStartupUpdate() async {
    await _loadLocalVersion();

    final config = await fetchUpdateConfig();
    if (config == null || !config.isActive) {
      return AppUpdateStatus.none;
    }

    final hasUpdate = isVersionHigher(config.latestVersion, _cachedCurrentVersion);
    if (!hasUpdate) {
      return AppUpdateStatus.none;
    }

    final isForce = config.isForceUpdate ||
        isVersionHigher(config.minVersion, _cachedCurrentVersion);

    if (isForce) {
      // Show immediately on splash screen, blocks proceeding
      _showDialog(config);
      return AppUpdateStatus.forced;
    } else {
      // Hold config for display after page transition
      _pendingOptionalConfig = config;
      return AppUpdateStatus.optional;
    }
  }

  /// Shows the pending optional dialog after the landing screen finishes mounting
  void showPendingOptionalDialog() {
    if (_pendingOptionalConfig != null) {
      final cfg = _pendingOptionalConfig!;
      _pendingOptionalConfig = null;
      _showDialog(cfg);
    }
  }

  /// Manual check triggered by user from Settings
  Future<void> checkManually() async {
    Get.snackbar(
      'Check for Updates'.tr,
      'Checking for updates...'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );

    await _loadLocalVersion();
    final config = await fetchUpdateConfig();

    if (config == null) {
      Get.snackbar(
        'Check for Updates'.tr,
        'Unable to check for updates right now.'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!config.isActive || !isVersionHigher(config.latestVersion, _cachedCurrentVersion)) {
      Get.snackbar(
        'Check for Updates'.tr,
        '${'You are using the latest version.'.tr} (v$_cachedCurrentVersion)',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _showDialog(config);
  }

  void _showDialog(AppUpdateModel config) {
    if (Get.isDialogOpen == true) {
      Get.back();
    }

    Get.dialog(
      AppUpdateDialog(
        updateModel: config,
        currentVersion: _cachedCurrentVersion,
      ),
      barrierDismissible: !config.isForceUpdate,
    );
  }
}
