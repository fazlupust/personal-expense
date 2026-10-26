import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/core/constants/app_constants.dart';
import 'app/core/localization/app_translations.dart';
import 'app/core/theme/app_theme.dart';
import 'app/features/settings/controllers/settings_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs, permanent: true);
  // Settings (theme + language) must exist before the first frame.
  final settings = Get.put(SettingsController(prefs), permanent: true);
  runApp(PersonalExpenseApp(settings: settings));
}

class PersonalExpenseApp extends StatelessWidget {
  const PersonalExpenseApp({super.key, required this.settings});
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      translations: AppTranslations(),
      locale: settings.locale,
      fallbackLocale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('bn')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.shell,
      getPages: AppPages.pages,
    );
  }
}
