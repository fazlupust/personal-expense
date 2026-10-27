import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense/app/data/models/category_model.dart';
import 'package:personal_expense/app/data/models/entry_type.dart';
import 'package:personal_expense/app/data/models/note_model.dart';
import 'package:personal_expense/app/data/models/user_model.dart';
import 'package:personal_expense/app/data/services/app_update_service.dart';
import 'package:personal_expense/app/features/categories/controllers/categories_controller.dart';
import 'package:personal_expense/app/features/notes/controllers/notes_controller.dart';
import 'package:personal_expense/app/features/settings/controllers/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    test('identifies 01744309649 as developer role', () {
      expect(UserModel.isDevPhone('01744309649'), isTrue);
      expect(UserModel.isDevPhone('+8801744309649'), isTrue);
      expect(UserModel.isDevPhone('01712345678'), isFalse);

      const devUser = UserModel(
        uid: 'dev123',
        nameBn: 'ডেভেলপার',
        nameEn: 'Developer',
        designationBn: 'ডেভেলপার',
        designationEn: 'Developer',
        phone: '01744309649',
      );
      expect(devUser.isDeveloper, isTrue);

      const normalUser = UserModel(
        uid: 'usr123',
        nameBn: 'ইউজার',
        nameEn: 'User',
        designationBn: 'ইউজার',
        designationEn: 'User',
        phone: '01712345678',
      );
      expect(normalUser.isDeveloper, isFalse);
    });

    test('normal user cannot delete default category', () async {
      final initialCount = controller.categories.length;
      final defaultCat = controller.categories.firstWhere((c) => c.isDefault);

      // Attempt to delete default category as normal user (no dev auth registered)
      await controller.delete(defaultCat);

      // Verify category was NOT deleted
      expect(controller.categories.length, equals(initialCount));
      expect(controller.categories.contains(defaultCat), isTrue);
    });

    test('normal user can delete user-added category', () async {
      final userCat = CategoryModel(
        id: 'user_cat_1',
        nameEn: 'Custom Special Gym',
        nameBn: 'বিশেষ জিম',
        type: EntryType.expense,
        isDefault: false,
      );
      controller.categories.add(userCat);
      final countWithCustom = controller.categories.length;

      // Delete custom category
      await controller.delete(userCat);

      // Verify category was deleted
      expect(controller.categories.length, equals(countWithCustom - 1));
      expect(controller.categories.contains(userCat), isFalse);
    });
  });

  group('SettingsController privacy and theme tests', () {
    late SettingsController settings;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
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

    test('toggleIncomeVisibility toggles isIncomeHidden independently', () {
      expect(settings.isIncomeHidden, isFalse);

      settings.toggleIncomeVisibility();
      expect(settings.isIncomeHidden, isTrue);

      settings.toggleIncomeVisibility();
      expect(settings.isIncomeHidden, isFalse);
    });

    test('setShowExpense toggles showExpense and isExpenseHidden', () {
      expect(settings.showExpense, isTrue);
      expect(settings.isExpenseHidden, isFalse);

      settings.setShowExpense(false);
      expect(settings.showExpense, isFalse);
      expect(settings.isExpenseHidden, isTrue);

      settings.setShowExpense(true);
      expect(settings.showExpense, isTrue);
      expect(settings.isExpenseHidden, isFalse);
    });

    test('toggleExpenseVisibility toggles isExpenseHidden independently', () {
      expect(settings.isExpenseHidden, isFalse);

      settings.toggleExpenseVisibility();
      expect(settings.isExpenseHidden, isTrue);

      settings.toggleExpenseVisibility();
      expect(settings.isExpenseHidden, isFalse);
    });

    test('visibility states persist to SharedPreferences across app reload', () async {
      settings.toggleBalanceVisibility(); // isBalanceHidden = true
      settings.toggleIncomeVisibility();  // isIncomeHidden = true
      settings.toggleExpenseVisibility(); // isExpenseHidden = true

      // Verify that re-initializing with the same SharedPreferences preserves all 3 hidden states
      final restored = SettingsController(prefs);
      restored.onInit();

      expect(restored.isBalanceHidden, isTrue);
      expect(restored.isIncomeHidden, isTrue);
      expect(restored.isExpenseHidden, isTrue);
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

  group('NoteModel serialization and properties tests', () {
    test('NoteModel toMap and fromMap round-trip', () {
      final now = DateTime(2026, 10, 26, 12, 0, 0);
      final note = NoteModel(
        id: 'note-123',
        userId: 'user-abc',
        title: 'Loan to Rahim',
        date: now,
        notes: 'Promised to return next Friday',
        amount: 5000.0,
        personName: 'Rahim',
        latitude: 23.8103,
        longitude: 90.4125,
        deviceInfo: 'iPhone 15 Pro',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(note.hasAmount, isTrue);
      expect(note.hasPerson, isTrue);
      expect(note.hasLocation, isTrue);

      final map = note.toMap();
      expect(map['title'], 'Loan to Rahim');
      expect(map['amount'], 5000.0);
      expect(map['person_name'], 'Rahim');
      expect(map['latitude'], 23.8103);
      expect(map['longitude'], 90.4125);
      expect(map['device_info'], 'iPhone 15 Pro');

      final reconstructed = NoteModel.fromMap(map, 'note-123');
      expect(reconstructed.id, 'note-123');
      expect(reconstructed.title, 'Loan to Rahim');
      expect(reconstructed.amount, 5000.0);
      expect(reconstructed.personName, 'Rahim');
      expect(reconstructed.latitude, 23.8103);
      expect(reconstructed.longitude, 90.4125);
    });

    test('NoteModel toJson and fromJson round-trip for local caching', () {
      final now = DateTime(2026, 10, 26, 12, 0, 0);
      final note = NoteModel(
        id: 'json-1',
        userId: 'user-abc',
        title: 'Office Loan',
        date: now,
        notes: 'Monthly lunch contribution',
        amount: 2500.0,
        personName: 'Shakil',
        latitude: 23.81,
        longitude: 90.41,
        deviceInfo: 'Pixel 9 Pro',
        createdAt: now,
      );

      final json = note.toJson();
      expect(json['id'], 'json-1');
      expect(json['user_id'], 'user-abc');
      expect(json['title'], 'Office Loan');
      expect(json['amount'], 2500.0);
      expect(json['date'], now.toIso8601String());

      final restored = NoteModel.fromJson(json);
      expect(restored.id, 'json-1');
      expect(restored.userId, 'user-abc');
      expect(restored.title, 'Office Loan');
      expect(restored.amount, 2500.0);
      expect(restored.personName, 'Shakil');
    });

    test('NoteModel copyWith updates fields properly', () {
      final now = DateTime(2026, 10, 26);
      final note = NoteModel(
        id: '1',
        title: 'Borrow money',
        date: now,
        amount: 1000,
        personName: 'Karim',
      );

      final updated = note.copyWith(
        amount: 1500,
        notes: 'Updated note description',
      );

      expect(updated.id, '1');
      expect(updated.title, 'Borrow money');
      expect(updated.amount, 1500);
      expect(updated.notes, 'Updated note description');
      expect(updated.personName, 'Karim');
    });
  });

  group('NotesController filtering and total calculation tests', () {
    late NotesController controller;

    setUp(() {
      controller = NotesController();
      controller.notes = [
        NoteModel(
          id: '1',
          title: 'Loan to Rahim',
          date: DateTime(2026, 10, 20),
          personName: 'Rahim',
          amount: 5000.0,
          notes: 'Emergency medical loan',
        ),
        NoteModel(
          id: '2',
          title: 'Borrowed from Karim',
          date: DateTime(2026, 10, 21),
          personName: 'Karim',
          amount: 2000.0,
          notes: 'For travel tickets',
        ),
        NoteModel(
          id: '3',
          title: 'Office due from Rahim',
          date: DateTime(2026, 10, 22),
          personName: 'Rahim',
          amount: 1500.0,
          notes: 'Shared lunch bill',
        ),
        NoteModel(
          id: '4',
          title: 'General reminder',
          date: DateTime(2026, 10, 23),
          personName: '',
          amount: 0.0,
          notes: 'Call lawyer next Monday',
        ),
      ];
    });

    tearDown(() {
      controller.dispose();
    });

    test('uniquePersons extracts sorted non-empty person names', () {
      final persons = controller.uniquePersons;
      expect(persons, ['Karim', 'Rahim']);
    });

    test('totalAmount calculates sum of all notes by default', () {
      expect(controller.totalAmount, 8500.0);
      expect(controller.notesWithAmountCount, 3);
    });

    test('person filtering filters notes and re-calculates totalAmount', () {
      controller.selectPerson('Rahim');
      expect(controller.filteredNotes.length, 2);
      expect(controller.totalAmount, 6500.0); // 5000 + 1500
      expect(controller.notesWithAmountCount, 2);

      controller.selectPerson('Karim');
      expect(controller.filteredNotes.length, 1);
      expect(controller.totalAmount, 2000.0);

      controller.selectPerson('All');
      expect(controller.filteredNotes.length, 4);
      expect(controller.totalAmount, 8500.0);
    });

    test('search query filters notes across title, person, and notes', () {
      controller.setSearchQuery('lunch');
      expect(controller.filteredNotes.length, 1);
      expect(controller.filteredNotes.first.id, '3');
      expect(controller.totalAmount, 1500.0);

      controller.setSearchQuery('lawyer');
      expect(controller.filteredNotes.length, 1);
      expect(controller.filteredNotes.first.id, '4');
      expect(controller.totalAmount, 0.0);

      controller.setSearchQuery('');
      expect(controller.filteredNotes.length, 4);
    });

    test('save() validates title and inserts new note', () async {
      controller.openCreate();
      expect(controller.titleCtrl.text, isEmpty);

      // Attempt save with empty title
      final failed = await controller.save();
      expect(failed, isFalse);
      expect(controller.titleError, isNotNull);

      // Fill in fields and save
      controller.titleCtrl.text = 'New Test Note';
      controller.personCtrl.text = 'Bablu';
      controller.amountCtrl.text = '3500';
      controller.notesCtrl.text = 'Test description';

      final success = await controller.save();
      expect(success, isTrue);
      expect(controller.notes.first.title, 'New Test Note');
      expect(controller.notes.first.amount, 3500.0);
      expect(controller.notes.first.personName, 'Bablu');
    });

    test('stopAllVoice() resets all listening flags', () {
      controller.isListeningTitle = true;
      controller.isListeningPerson = true;
      controller.isListeningAmount = true;
      controller.isListeningNote = true;

      controller.stopAllVoice();
      expect(controller.isListeningTitle, isFalse);
      expect(controller.isListeningPerson, isFalse);
      expect(controller.isListeningAmount, isFalse);
      expect(controller.isListeningNote, isFalse);
    });

    test('refreshNotes() does not throw and maintains state', () async {
      await controller.refreshNotes();
      expect(controller.isLoading, isFalse);
    });
  });

  group('Budget and Profile Management tests', () {
    test('SettingsController sets, gets, and persists category budgets and total budget', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = SettingsController(prefs);
      controller.onInit();

      expect(controller.budget, 0.0);
      expect(controller.categoryBudgets, isEmpty);

      // Set total budget
      controller.setTotalBudget(15000);
      expect(controller.budget, 15000.0);
      expect(controller.budgetCtrl.text, '15000');

      // Set category budgets
      controller.setCategoryBudget('Food', 5000);
      controller.setCategoryBudget('Groceries', 3000);
      controller.setCategoryBudget('Transport', 2000);

      expect(controller.getCategoryBudget('Food'), 5000.0);
      expect(controller.getCategoryBudget('Groceries'), 3000.0);
      expect(controller.getCategoryBudget('Transport'), 2000.0);
      expect(controller.getCategoryBudget('NonExistent'), 0.0);
      expect(controller.categoryBudgets.length, 3);

      // Remove category budget by setting 0
      controller.setCategoryBudget('Transport', 0);
      expect(controller.getCategoryBudget('Transport'), 0.0);
      expect(controller.categoryBudgets.length, 2);

      // Reload controller from prefs to verify persistence
      final reloaded = SettingsController(prefs);
      reloaded.onInit();
      expect(reloaded.budget, 15000.0);
      expect(reloaded.getCategoryBudget('Food'), 5000.0);
      expect(reloaded.getCategoryBudget('Groceries'), 3000.0);
      expect(reloaded.getCategoryBudget('Transport'), 0.0);

      controller.dispose();
      reloaded.dispose();
    });

    test('UserModel supports profile editing with designation, email, and address', () {
      const user = UserModel(
        uid: 'user_123',
        nameBn: 'ফজলু',
        nameEn: 'Fazlu',
        phone: '01700000000',
        designationEn: 'Software Engineer',
        designationBn: 'সফটওয়্যার ইঞ্জিনিয়ার',
        email: 'fazlu@example.com',
        addressEn: 'Dhaka, Bangladesh',
        addressBn: 'ঢাকা, বাংলাদেশ',
      );

      expect(user.displayName(false), 'Fazlu');
      expect(user.displayName(true), 'ফজলু');
      expect(user.displayDesignation(false), 'Software Engineer');
      expect(user.displayDesignation(true), 'সফটওয়্যার ইঞ্জিনিয়ার');
      expect(user.email, 'fazlu@example.com');
      expect(user.addressEn, 'Dhaka, Bangladesh');

      final updated = user.copyWith(
        nameEn: 'Fazlu Rahman',
        designationEn: 'Lead Engineer',
      );
      expect(updated.nameEn, 'Fazlu Rahman');
      expect(updated.designationEn, 'Lead Engineer');
      expect(updated.nameBn, 'ফজলু'); // Preserved
      expect(updated.email, 'fazlu@example.com'); // Preserved
    });

    test('Developer App Users model verification: name, designation, phone', () {
      const devUser = UserModel(
        uid: 'dev_1',
        userNo: 1,
        nameBn: 'ডেভেলপার ইউজার',
        nameEn: 'Developer User',
        phone: '01744309649',
        designationEn: 'Lead Architect',
        designationBn: 'লিড আর্কিটেক্ট',
      );

      const normalUser = UserModel(
        uid: 'user_2',
        userNo: 2,
        nameBn: 'সাধারণ ইউজার',
        nameEn: 'Normal User',
        phone: '01811111111',
        designationEn: 'Accountant',
        designationBn: 'হিসাবরক্ষক',
      );

      expect(devUser.isDeveloper, isTrue);
      expect(normalUser.isDeveloper, isFalse);

      expect(devUser.displayName(false), 'Developer User');
      expect(devUser.displayDesignation(false), 'Lead Architect');
      expect(devUser.phone, '01744309649');

      expect(normalUser.displayName(true), 'সাধারণ ইউজার');
      expect(normalUser.displayDesignation(true), 'হিসাবরক্ষক');
      expect(normalUser.phone, '01811111111');
    });
  });
}

