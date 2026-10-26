import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../categories/controllers/categories_controller.dart';
import '../../reports/controllers/reports_controller.dart';
import '../../transactions/controllers/transactions_controller.dart';
import '../controllers/shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    final prefs = Get.find<SharedPreferences>();
    Get.put(ShellController());
    Get.put(CategoriesController(prefs));
    Get.put(TransactionsController(prefs));
    Get.put(ReportsController());
  }
}
