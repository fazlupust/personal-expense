import 'package:get/get.dart';
import '../controllers/prayer_tasbih_controller.dart';

class PrayerTasbihBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrayerTasbihController>(() => PrayerTasbihController());
  }
}
