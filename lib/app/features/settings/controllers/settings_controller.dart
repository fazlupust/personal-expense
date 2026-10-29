import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/services/auth_service.dart';

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
  bool isIncomeHidden = false;
  bool showExpense = true;
  bool isExpenseHidden = false;
  bool showPrayerCard = false;
  bool showWeatherCard = false;

  bool get isBalanceHidden => isIncomeHidden || isExpenseHidden;

  Locale get locale => Locale(langCode);

  bool get isDarkMode {
    if (themeMode == ThemeMode.dark) return true;
    if (themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  String? _overrideUid;

  String get _currentUid =>
      _overrideUid ?? (Get.isRegistered<AuthService>() ? (Get.find<AuthService>().currentUid ?? '') : '');

  String _userPrefsKey(String uid) =>
      uid.isNotEmpty ? '${AppConstants.prefsSettings}_$uid' : AppConstants.prefsSettings;

  String get _prefsKey => _userPrefsKey(_currentUid);

  void loadForUserForTesting(String uid) {
    _overrideUid = uid;
    _load(uid);
    budgetCtrl.text = budget > 0 ? _plain(budget) : '';
    nameCtrl.text = name;
  }

  @override
  void onInit() {
    super.onInit();
    _load();
    nameCtrl.text = name;
    budgetCtrl.text = budget > 0 ? _plain(budget) : '';
    _bindAuth();
  }

  void _bindAuth() {
    if (Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      ever(auth.firebaseUser, (user) {
        if (user != null) {
          _load(user.uid);
          _syncFromFirestore(user.uid);
          _syncProfileName();
        } else {
          _resetUserScopedData();
        }
        nameCtrl.text = name;
        budgetCtrl.text = budget > 0 ? _plain(budget) : '';
        update();
      });
      ever(auth.userProfile, (u) {
        if (u != null) {
          _syncProfileName(u);
        }
      });
      if (auth.currentUid != null && auth.currentUid!.isNotEmpty) {
        _syncFromFirestore(auth.currentUid!);
        _syncProfileName();
      }
    }
  }

  void _syncProfileName([dynamic uOverride]) {
    if (!Get.isRegistered<AuthService>()) return;
    final auth = Get.find<AuthService>();
    final u = uOverride ?? auth.userProfile.value;
    if (u != null) {
      final isBn = langCode == 'bn';
      final pName = u.displayName(isBn);
      if (pName.isNotEmpty && (name.isEmpty || nameCtrl.text.isEmpty)) {
        name = pName;
        nameCtrl.text = pName;
        update();
      }
    }
  }

  void _resetUserScopedData() {
    name = '';
    budget = 0;
    categoryBudgets = {};
    nameCtrl.clear();
    budgetCtrl.clear();
    showIncome = true;
    showExpense = true;
    isIncomeHidden = false;
    isExpenseHidden = false;
    showPrayerCard = false;
    showWeatherCard = false;
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    budgetCtrl.dispose();
    super.onClose();
  }

  String _plain(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  void _load([String? uidOverride]) {
    final uid = uidOverride ?? _currentUid;
    final key = _userPrefsKey(uid);
    var raw = _prefs.getString(key);
    if (raw == null && uid.isEmpty) {
      raw = _prefs.getString(AppConstants.prefsSettings);
    }
    if (raw == null) {
      final sys = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      langCode = sys == 'bn' ? 'bn' : 'en';
      showIncome = true;
      isIncomeHidden = false;
      showExpense = true;
      isExpenseHidden = false;
      showPrayerCard = false;
      showWeatherCard = false;
      budget = 0;
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
      showPrayerCard = (m['show_prayer_card'] as bool?) ?? false;
      showWeatherCard = (m['show_weather_card'] as bool?) ?? false;
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

  Future<void> _syncFromFirestore(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        bool changed = false;
        if (data['budget'] is num) {
          final b = (data['budget'] as num).toDouble();
          if (b != budget) {
            budget = b;
            budgetCtrl.text = budget > 0 ? _plain(budget) : '';
            changed = true;
          }
        }
        if (data['category_budgets'] is Map) {
          final bMap = data['category_budgets'] as Map<String, dynamic>;
          categoryBudgets = bMap.map((k, v) => MapEntry(k, (v as num).toDouble()));
          changed = true;
        }
        if (data['is_income_hidden'] is bool) {
          isIncomeHidden = data['is_income_hidden'] as bool;
          changed = true;
        }
        if (data['is_expense_hidden'] is bool) {
          isExpenseHidden = data['is_expense_hidden'] as bool;
          changed = true;
        }
        if (data['show_prayer_card'] is bool) {
          showPrayerCard = data['show_prayer_card'] as bool;
          changed = true;
        }
        if (data['show_weather_card'] is bool) {
          showWeatherCard = data['show_weather_card'] as bool;
          changed = true;
        }
        if (changed) {
          await _prefs.setString(
            _userPrefsKey(uid),
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
              'show_prayer_card': showPrayerCard,
              'show_weather_card': showWeatherCard,
              'category_budgets': categoryBudgets,
            }),
          );
          update();
        }
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final payload = jsonEncode({
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
      'show_prayer_card': showPrayerCard,
      'show_weather_card': showWeatherCard,
      'category_budgets': categoryBudgets,
    });
    await _prefs.setString(_prefsKey, payload);

    final uid = _currentUid;
    if (uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'budget': budget,
          'category_budgets': categoryBudgets,
          'is_balance_hidden': isBalanceHidden,
          'is_income_hidden': isIncomeHidden,
          'is_expense_hidden': isExpenseHidden,
          'show_prayer_card': showPrayerCard,
          'show_weather_card': showWeatherCard,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

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
    isIncomeHidden = !val;
    _persist();
    update();
  }

  void toggleBalanceVisibility() {
    final shouldHide = !(isIncomeHidden && isExpenseHidden);
    isIncomeHidden = shouldHide;
    isExpenseHidden = shouldHide;
    showIncome = !shouldHide;
    showExpense = !shouldHide;
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

  void setShowPrayerCard(bool val) {
    showPrayerCard = val;
    _persist();
    update();
  }

  void togglePrayerCardVisibility() {
    setShowPrayerCard(!showPrayerCard);
  }

  void setShowWeatherCard(bool val) {
    showWeatherCard = val;
    _persist();
    update();
  }

  void toggleWeatherCardVisibility() {
    setShowWeatherCard(!showWeatherCard);
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
    final newName = nameCtrl.text.trim();
    name = newName;
    budget = b;
    _persist();

    if (Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      final u = auth.userProfile.value;
      if (auth.isLoggedIn && u != null && newName.isNotEmpty) {
        final isBn = langCode == 'bn';
        final updated = u.copyWith(
          nameBn: isBn ? newName : (u.nameBn.isEmpty ? newName : u.nameBn),
          nameEn: !isBn ? newName : (u.nameEn.isEmpty ? newName : u.nameEn),
        );
        auth.updateProfile(updated);
      }
    }

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
