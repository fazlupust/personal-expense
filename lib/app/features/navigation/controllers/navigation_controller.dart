import 'package:get/get.dart';

class NavigationController extends GetxController {
  int index = 0;

  void select(int i) {
    if (i == index) return;
    index = i;
    update();
  }
}
