import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/categories_controller.dart';

class CategoriesBinding extends Bindings {
  @override
  void dependencies() {
    // Already registered by NavigationBinding; this is a safety net for deep links.
    if (!Get.isRegistered<CategoriesController>()) {
      Get.lazyPut(() => CategoriesController(Get.find<SharedPreferences>()));
    }
  }
}
