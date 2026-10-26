import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense/app/data/models/entry_type.dart';
import 'package:personal_expense/app/data/services/app_update_service.dart';
import 'package:personal_expense/app/features/categories/controllers/categories_controller.dart';
import 'package:personal_expense/app/features/settings/controllers/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('AppUpdateService version comparison test', () {
    expect(AppUpdateService.isVersionHigher('1.1.0', '1.0.0'), isTrue);
    expect(AppUpdateService.isVersionHigher('2.0.0', '1.9.9'), isTrue);
    expect(AppUpdateService.isVersionHigher('1.0.1', '1.0.0'), isTrue);
    expect(AppUpdateService.isVersionHigher('1.0.0', '1.0.0'), isFalse);
    expect(AppUpdateService.isVersionHigher('1.0.0', '1.1.0'), isFalse);
    expect(AppUpdateService.isVersionHigher('v1.2.0', '1.1.0'), isTrue);
  });

  group('Categories duplicate check tests', () {
    late CategoriesController controller;

    setUp(() {
      controller = CategoriesController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('detects duplicate English category name case-insensitively and with trimmed spaces', () {
      expect(controller.isDuplicate('Food', EntryType.expense), isTrue);
      expect(controller.isDuplicate('food', EntryType.expense), isTrue);
      expect(controller.isDuplicate('  FOOD  ', EntryType.expense), isTrue);
      expect(controller.isDuplicate('  food  ', EntryType.expense), isTrue);
    });

    test('detects duplicate Bengali category name', () {
      expect(controller.isDuplicate('খাবার', EntryType.expense), isTrue);
      expect(controller.isDuplicate('  খাবার  ', EntryType.expense), isTrue);
    });

    test('differentiates category by EntryType', () {
      // Salary is an income category
      expect(controller.isDuplicate('Salary', EntryType.income), isTrue);
      expect(controller.isDuplicate('Salary', EntryType.expense), isFalse);
    });

    test('allows non-duplicate new category name', () {
      expect(controller.isDuplicate('Unique New Gadget', EntryType.expense), isFalse);
      expect(controller.isDuplicate('নতুন আয় খাত', EntryType.income), isFalse);
    });

    test('onNameChanged updates nameError accurately', () {
      controller.onNameChanged('Food');
      expect(controller.nameError, isNotNull);
      expect(controller.nameError, 'That category already exists.');

      controller.onNameChanged('Completely New Category');
      expect(controller.nameError, isNull);

      controller.onNameChanged('');
      expect(controller.nameError, isNull);
    });

    test('setType re-evaluates duplicate check with current text', () {
      controller.nameCtrl.text = 'Salary';
      // Form starts as expense, where 'Salary' is not a duplicate
      controller.setType(EntryType.expense);
      expect(controller.nameError, isNull);

      // Switching to income where 'Salary' exists
      controller.setType(EntryType.income);
      expect(controller.nameError, 'That category already exists.');
    });
  });

  group('SettingsController privacy and theme tests', () {
    late SettingsController settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      settings = SettingsController(prefs);
    });

    tearDown(() {
      settings.dispose();
    });

    test('setShowIncome toggles showIncome and isBalanceHidden', () {
      expect(settings.showIncome, isTrue);
      expect(settings.isBalanceHidden, isFalse);

      settings.setShowIncome(false);
      expect(settings.showIncome, isFalse);
      expect(settings.isBalanceHidden, isTrue);

      settings.setShowIncome(true);
      expect(settings.showIncome, isTrue);
      expect(settings.isBalanceHidden, isFalse);
    });

    test('toggleBalanceVisibility toggles isBalanceHidden independently', () {
      expect(settings.isBalanceHidden, isFalse);

      settings.toggleBalanceVisibility();
      expect(settings.isBalanceHidden, isTrue);

      settings.toggleBalanceVisibility();
      expect(settings.isBalanceHidden, isFalse);
    });

    test('toggleTheme alternates between light and dark modes', () {
      settings.setTheme(ThemeMode.light);
      expect(settings.isDarkMode, isFalse);

      settings.toggleTheme();
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.isDarkMode, isTrue);

      settings.toggleTheme();
      expect(settings.themeMode, ThemeMode.light);
      expect(settings.isDarkMode, isFalse);
    });
  });
}

