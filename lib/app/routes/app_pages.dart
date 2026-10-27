import 'package:get/get.dart';

import '../features/auth/bindings/auth_binding.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/register_view.dart';
import '../features/categories/bindings/categories_binding.dart';
import '../features/categories/views/categories_view.dart';
import '../features/navigation/bindings/navigation_binding.dart';
import '../features/navigation/views/navigation_view.dart';
import '../features/notes/bindings/notes_binding.dart';
import '../features/notes/views/notes_view.dart';
import '../features/prayer_tasbih/bindings/prayer_tasbih_binding.dart';
import '../features/prayer_tasbih/views/prayer_tasbih_view.dart';
import '../features/prayer_tasbih/views/tasbih_counter_view.dart';
import '../features/prayer_tasbih/views/tasbih_history_view.dart';
import '../features/reports/views/generate_report_view.dart';
import '../features/settings/views/registered_users_view.dart';
import '../features/splash/views/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(name: AppRoutes.navigation, page: () => const NavigationView(), binding: NavigationBinding()),
    GetPage(name: AppRoutes.categories, page: () => const CategoriesView(), binding: CategoriesBinding()),
    GetPage(name: AppRoutes.notes, page: () => const NotesView(), binding: NotesBinding()),
    GetPage(name: AppRoutes.generateReport, page: () => const GenerateReportView()),
    GetPage(name: AppRoutes.login, page: () => const LoginView(), binding: AuthBinding()),
    GetPage(name: AppRoutes.register, page: () => const RegisterView(), binding: AuthBinding()),
    GetPage(name: AppRoutes.registeredUsers, page: () => const RegisteredUsersView()),
    GetPage(
      name: AppRoutes.prayerAndTasbih,
      page: () => const PrayerTasbihView(),
      binding: PrayerTasbihBinding(),
    ),
    GetPage(
      name: AppRoutes.tasbihCounter,
      page: () => const TasbihCounterView(),
      binding: PrayerTasbihBinding(),
    ),
    GetPage(
      name: AppRoutes.tasbihHistory,
      page: () => const TasbihHistoryView(),
      binding: PrayerTasbihBinding(),
    ),
  ];
}

