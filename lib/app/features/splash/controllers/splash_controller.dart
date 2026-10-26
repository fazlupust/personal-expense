import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
      appVersion.value = 'v${info.version}';
    } catch (_) {
      appVersion.value = 'v1.0.0';
    }
  }

  Future<void> _startTransition() async {
    // Wait for splash animation and auth state resolution
    await Future.delayed(const Duration(milliseconds: 1800));

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Get.offAllNamed(AppRoutes.navigation);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
