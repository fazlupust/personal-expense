import 'package:get/get.dart';

import '../features/categories/bindings/categories_binding.dart';
import '../features/categories/views/categories_view.dart';
import '../features/shell/bindings/shell_binding.dart';
import '../features/shell/views/shell_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> pages = [
    GetPage(name: AppRoutes.shell, page: () => const ShellView(), binding: ShellBinding()),
    GetPage(name: AppRoutes.categories, page: () => const CategoriesView(), binding: CategoriesBinding()),
  ];
}
