import 'package:get/get.dart';

import '../../transactions/controllers/transactions_controller.dart';

class NavigationController extends GetxController {
  int index = 0;

  void select(int i) {
    // When returning to Dashboard (index 0), default to current month's data
    if (i == 0 && Get.isRegistered<TransactionsController>()) {
      Get.find<TransactionsController>().resetToCurrentMonth();
    }
    if (i == index) return;
    index = i;
    update();
  }
}
