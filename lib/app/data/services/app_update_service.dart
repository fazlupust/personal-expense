import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_update_dialog.dart';
import '../models/app_update_model.dart';

enum AppUpdateStatus { none, optional, forced }

class AppUpdateService extends GetxService {
  static AppUpdateService get to => Get.find<AppUpdateService>();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  AppUpdateModel? _pendingOptionalConfig;
  String _cachedCurrentVersion = '';

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _updateSub;
  String? _dismissedVersion;

  String get currentVersion => _cachedCurrentVersion;

  void dismissOptional(String version) {
    _dismissedVersion = version;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadLocalVersion();
    _startRealtimeListener();
  }

  void _startRealtimeListener() {
    _updateSub?.cancel();
    _updateSub = _db.collection('app_config').doc('version').snapshots().listen((snap) {
      if (!snap.exists || snap.data() == null) return;
      try {
        final config = AppUpdateModel.fromMap(snap.data()!);
        if (!config.isActive) return;

        final hasUpdate = isVersionHigher(config.latestVersion, _cachedCurrentVersion);
        if (!hasUpdate) return;

        final isForce = config.isForceUpdate ||
            isVersionHigher(config.minVersion, _cachedCurrentVersion);

        // If user already dismissed this or a higher version during this session, do not re-prompt
        if (!isForce &&
            _dismissedVersion != null &&
            !isVersionHigher(config.latestVersion, _dismissedVersion!)) {
          return;
        }

        // Show dialog automatically on Dashboard / current screen
        if (Get.context != null && Get.isDialogOpen != true) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (Get.context != null && Get.isDialogOpen != true) {
              _showDialog(config);
            }
          });
        }
      } catch (e) {
        debugPrint('[AppUpdateService] realtime listener error: $e');
      }
    });
  }

  @override
  void onClose() {
    _updateSub?.cancel();
    super.onClose();
  }

  Future<void> _loadLocalVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        _cachedCurrentVersion = info.version;
      }
    } catch (_) {}
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
              'A new version of My Wallet is available with new features and improvements. Please update now to continue enjoying the best experience.',
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
      if (_dismissedVersion != null &&
          !isVersionHigher(cfg.latestVersion, _dismissedVersion!)) {
        return;
      }
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

  /// For testing/previewing the optional update dialog directly with Update Later & Update Now
  void showTestOptionalDialog() {
    _showDialog(
      const AppUpdateModel(
        isActive: true,
        isForceUpdate: false,
        latestVersion: '1.0.2',
        minVersion: '1.0.0',
        title: 'Update Available',
        message:
            'A new version of My Wallet is available with new features and improvements. Please update now to continue enjoying the best experience.',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.fazlu.personalexpense',
      ),
    );
  }

  /// For testing/previewing the forced update dialog directly with Update Now (Mandatory)
  void showTestForcedDialog() {
    _showDialog(
      const AppUpdateModel(
        isActive: true,
        isForceUpdate: true,
        latestVersion: '1.0.2',
        minVersion: '1.0.2',
        title: 'Mandatory Update Required',
        message:
            'A critical update for My Wallet is required to continue. Please update now to access your wallet safely.',
        playStoreUrl: 'https://play.google.com/store/apps/details?id=com.fazlu.personalexpense',
      ),
    );
  }

  /// Displays a picker sheet to test all AppUpdateStatus dialogs (Optional, Forced, or Real Firebase check)
  void showUpdateDialogPicker(BuildContext context) {
    final p = context.pal;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.system_update_rounded, size: 20, color: p.income),
                  const SizedBox(width: 8),
                  Text(
                    'App Update Dialogs (Status Test)'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.income.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.rocket_launch_rounded, color: p.income, size: 20),
                ),
                title: Text(
                  'Optional Update (Update Later + Update Now)'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink),
                ),
                subtitle: Text(
                  'AppUpdateStatus.optional — দুটি বাটনসহ ডায়ালগ দেখতে চাপুন'.tr,
                  style: TextStyle(fontSize: 12, color: p.mute),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showTestOptionalDialog();
                },
              ),
              Divider(height: 1, color: p.line.withOpacity(0.5)),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.expense.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: p.expense, size: 20),
                ),
                title: Text(
                  'Forced Update (Mandatory Update)'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink),
                ),
                subtitle: Text(
                  'AppUpdateStatus.forced — বাধ্যতামূলক আপডেট (একটি বাটন) দেখতে চাপুন'.tr,
                  style: TextStyle(fontSize: 12, color: p.mute),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showTestForcedDialog();
                },
              ),
              Divider(height: 1, color: p.line.withOpacity(0.5)),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.line.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.cloud_sync_rounded, color: p.ink, size: 20),
                ),
                title: Text(
                  'Check Real Cloud Update'.tr,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink),
                ),
                subtitle: Text(
                  'Firebase Firestore ডেটাবেজ থেকে সরাসরি আসল চেক'.tr,
                  style: TextStyle(fontSize: 12, color: p.mute),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  checkManually();
                },
              ),
            ],
          ),
        ),
      ),
    );
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
