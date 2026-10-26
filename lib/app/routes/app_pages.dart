import 'package:get/get.dart';

import '../features/auth/bindings/auth_binding.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/register_view.dart';
import '../features/categories/bindings/categories_binding.dart';
import '../features/categories/views/categories_view.dart';
import '../features/navigation/bindings/navigation_binding.dart';
import '../features/navigation/views/navigation_view.dart';
import '../features/reports/views/generate_report_view.dart';
import '../features/splash/views/splash_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> pages = [
    GetPage(name: AppRoutes.splash, page: () => const SplashView()),
    GetPage(name: AppRoutes.navigation, page: () => const NavigationView(), binding: NavigationBinding()),
    GetPage(name: AppRoutes.categories, page: () => const CategoriesView(), binding: CategoriesBinding()),
    GetPage(name: AppRoutes.generateReport, page: () => const GenerateReportView()),
    GetPage(name: AppRoutes.login, page: () => const LoginView(), binding: AuthBinding()),
    GetPage(name: AppRoutes.register, page: () => const RegisterView(), binding: AuthBinding()),
  ];
}
