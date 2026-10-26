import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense/app/data/models/entry_type.dart';
import 'package:personal_expense/app/data/models/note_model.dart';
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
  });
}

