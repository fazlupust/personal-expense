import 'package:get/get.dart';

import '../../categories/controllers/categories_controller.dart';
import '../../reports/controllers/reports_controller.dart';
import '../../transactions/controllers/transactions_controller.dart';
import '../controllers/navigation_controller.dart';

class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NavigationController());
    Get.put(TransactionsController(Get.find()));
    Get.put(CategoriesController(Get.find()));
    Get.put(ReportsController());
  }
}
