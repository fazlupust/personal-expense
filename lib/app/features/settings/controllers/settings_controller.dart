import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

class SettingsController extends GetxController {
  static SettingsController get to => Get.find<SettingsController>();
  SettingsController(this._prefs);
  final SharedPreferences _prefs;

  final nameCtrl = TextEditingController();
  final budgetCtrl = TextEditingController();

  ThemeMode themeMode = ThemeMode.system;
  String langCode = 'en';
  String name = '';
  double budget = 0;
  String defaultAccount = AppConstants.accounts.first;
  String? budgetError;
  bool showIncome = true;
  bool isBalanceHidden = false;
  bool showExpense = true;
  bool isExpenseHidden = false;

  Locale get locale => Locale(langCode);

  bool get isDarkMode {
    if (themeMode == ThemeMode.dark) return true;
    if (themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  @override
  void onInit() {
    super.onInit();
    _load();
    nameCtrl.text = name;
    budgetCtrl.text = budget > 0 ? _plain(budget) : '';
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    budgetCtrl.dispose();
    super.onClose();
  }

  String _plain(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  void _load() {
    final raw = _prefs.getString(AppConstants.prefsSettings);
    if (raw == null) {
      final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      langCode = sys == 'bn' ? 'bn' : 'en';
      showIncome = true;
      isBalanceHidden = false;
      showExpense = true;
      isExpenseHidden = false;
      return;
    }
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      themeMode = ThemeMode.values.byName((m['theme'] as String?) ?? 'system');
      langCode = (m['lang'] as String?) ?? 'en';
      name = (m['name'] as String?) ?? '';
      budget = (m['budget'] as num?)?.toDouble() ?? 0;
      defaultAccount = (m['account'] as String?) ?? defaultAccount;
      showIncome = (m['show_income'] as bool?) ?? true;
      isBalanceHidden = !showIncome;
      showExpense = (m['show_expense'] as bool?) ?? true;
      isExpenseHidden = !showExpense;
    } catch (_) {
      // Corrupt data: fall back to defaults.
    }
  }

  Future<void> _persist() => _prefs.setString(
        AppConstants.prefsSettings,
        jsonEncode({
          'theme': themeMode.name,
          'lang': langCode,
          'name': name,
          'budget': budget,
          'account': defaultAccount,
          'show_income': showIncome,
          'show_expense': showExpense,
        }),
      );

  void setTheme(ThemeMode mode) {
    themeMode = mode;
    Get.changeThemeMode(mode);
    _persist();
    update();
  }

  void toggleTheme() {
    setTheme(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  void setLanguage(String code) {
    langCode = code;
    Get.updateLocale(Locale(code));
    _persist();
    update();
  }

  void setDefaultAccount(String account) {
    defaultAccount = account;
    _persist();
    update();
  }

  void setShowIncome(bool val) {
    showIncome = val;
    isBalanceHidden = !val;
    _persist();
    update();
  }

  void toggleBalanceVisibility() {
    isBalanceHidden = !isBalanceHidden;
    update();
  }

  void setShowExpense(bool val) {
    showExpense = val;
    isExpenseHidden = !val;
    _persist();
    update();
  }

  void toggleExpenseVisibility() {
    isExpenseHidden = !isExpenseHidden;
    update();
  }

  void saveProfile() {
    final text = budgetCtrl.text.trim();
    final b = text.isEmpty ? 0.0 : double.tryParse(text);
    if (b == null || b < 0) {
      budgetError = 'Enter a valid budget.';
      update();
      return;
    }
    budgetError = null;
    name = nameCtrl.text.trim();
    budget = b;
    _persist();
    update();
    Get.snackbar(
      AppConstants.appName.tr,
      'Settings saved.'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      maxWidth: 400,
      margin: const EdgeInsets.all(12),
    );
  }
}
