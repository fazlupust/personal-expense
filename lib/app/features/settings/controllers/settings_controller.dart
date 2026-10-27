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
  Map<String, double> categoryBudgets = {};
  String defaultAccount = AppConstants.accounts.first;
  String? budgetError;
  bool showIncome = true;
  bool isBalanceHidden = false;
  bool isIncomeHidden = false;
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
      isIncomeHidden = false;
      showExpense = true;
      isExpenseHidden = false;
      categoryBudgets = {};
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
      showExpense = (m['show_expense'] as bool?) ?? true;
      isBalanceHidden = (m['is_balance_hidden'] as bool?) ?? !showIncome;
      isIncomeHidden = (m['is_income_hidden'] as bool?) ?? !showIncome;
      isExpenseHidden = (m['is_expense_hidden'] as bool?) ?? !showExpense;

      if (m['category_budgets'] is Map) {
        final bMap = m['category_budgets'] as Map<String, dynamic>;
        categoryBudgets = bMap.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } else {
        categoryBudgets = {};
      }
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
          'is_balance_hidden': isBalanceHidden,
          'is_income_hidden': isIncomeHidden,
          'is_expense_hidden': isExpenseHidden,
          'category_budgets': categoryBudgets,
        }),
      );

  double getCategoryBudget(String category) => categoryBudgets[category] ?? 0.0;

  void setTotalBudget(double val) {
    budget = val >= 0 ? val : 0;
    budgetCtrl.text = budget > 0 ? _plain(budget) : '';
    _persist();
    update();
  }

  void setCategoryBudget(String category, double amount) {
    if (amount <= 0) {
      categoryBudgets.remove(category);
    } else {
      categoryBudgets[category] = amount;
    }
    _persist();
    update();
  }

  void setCategoryBudgets(Map<String, double> map) {
    categoryBudgets = Map.from(map);
    _persist();
    update();
  }

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
    isIncomeHidden = !val;
    _persist();
    update();
  }

  void toggleBalanceVisibility() {
    isBalanceHidden = !isBalanceHidden;
    showIncome = !isBalanceHidden;
    _persist();
    update();
  }

  void toggleIncomeVisibility() {
    isIncomeHidden = !isIncomeHidden;
    _persist();
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
    showExpense = !isExpenseHidden;
    _persist();
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
