import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/core/constants/app_constants.dart';
import 'app/core/localization/app_translations.dart';
import 'app/core/theme/app_theme.dart';
import 'app/data/services/app_update_service.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/category_service.dart';
import 'app/data/services/note_service.dart';
import 'app/data/services/transaction_service.dart';
import 'app/data/services/weather_service.dart';
import 'app/features/settings/controllers/settings_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting();
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs, permanent: true);
  Get.put(AppUpdateService(), permanent: true);
  Get.put(WeatherService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(CategoryService(), permanent: true);
  Get.put(TransactionService(), permanent: true);
  Get.put(NoteService(), permanent: true);
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
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
