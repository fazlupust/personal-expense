import 'package:get/get.dart';

import '../../categories/controllers/categories_controller.dart';
import '../../notes/controllers/notes_controller.dart';
import '../../prayer_tasbih/controllers/prayer_tasbih_controller.dart';
import '../../reports/controllers/reports_controller.dart';
import '../../transactions/controllers/transactions_controller.dart';
import '../controllers/navigation_controller.dart';

class NavigationBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NavigationController());
    Get.put(TransactionsController());
    Get.put(CategoriesController());
    Get.put(ReportsController());
    Get.put(NotesController());
    Get.put(PrayerTasbihController());
  }
}
