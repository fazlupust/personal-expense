import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../data/services/app_update_service.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  final RxString appVersion = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
    _startTransition();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        appVersion.value = 'v${info.version}';
        return;
      }
    } catch (_) {}
    if (Get.isRegistered<AppUpdateService>() &&
        AppUpdateService.to.currentVersion.isNotEmpty) {
      appVersion.value = 'v${AppUpdateService.to.currentVersion}';
    }
  }

  Future<void> _startTransition() async {
    // Wait for splash animation and auth state resolution
    final waitFuture = Future.delayed(const Duration(milliseconds: 1800));

    // Check Firebase app update config in parallel
    AppUpdateStatus updateStatus = AppUpdateStatus.none;
    try {
      updateStatus = await AppUpdateService.to.checkStartupUpdate();
    } catch (_) {}

    await waitFuture;

    // If mandatory force update is required, stay on splash screen with dialog blocking
    if (updateStatus == AppUpdateStatus.forced) {
      return;
    }

    // Normal navigation
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Get.offAllNamed(AppRoutes.navigation);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }

    // If optional update was detected, present the dialog smoothly after navigation
    if (updateStatus == AppUpdateStatus.optional) {
      Future.delayed(const Duration(milliseconds: 600), () {
        AppUpdateService.to.showPendingOptionalDialog();
      });
    }
  }
}
