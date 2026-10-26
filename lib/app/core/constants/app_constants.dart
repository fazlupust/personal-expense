import '../../data/models/category_model.dart';
import '../../data/models/entry_type.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Personal Expense';
  static const String currency = '৳';

  static const String prefsSettings = 'pe.settings.v1';
  static const String prefsEntries = 'pe.entries.v1';
  static const String prefsCategories = 'pe.categories.v1';

  static const List<String> accounts = ['Cash', 'Bank', 'Mobile wallet', 'Card'];

  static const List<CategoryModel> defaultCategories = [
    CategoryModel(name: 'Food', emoji: '🍜', type: EntryType.expense, isDefault: true),
    CategoryModel(name: 'Transport', emoji: '🚌', type: EntryType.expense, isDefault: true),
    CategoryModel(name: 'Bills', emoji: '💡', type: EntryType.expense, isDefault: true),
    CategoryModel(name: 'Rent', emoji: '🏠', type: EntryType.expense, isDefault: true),
    CategoryModel(name: 'Shopping', emoji: '🛍', type: EntryType.expense, isDefault: true),
    CategoryModel(name: 'Health', emoji: '💊', type: EntryType.expense, isDefault: true),
    CategoryModel(name: 'Education', emoji: '📚', type: EntryType.expense, isDefault: true),
    CategoryModel(name: 'Fun', emoji: '🎬', type: EntryType.expense, isDefault: true),
    CategoryModel(name: 'Other', emoji: '📦', type: EntryType.expense, isDefault: true),
    CategoryModel(name: 'Salary', emoji: '💼', type: EntryType.income, isDefault: true),
    CategoryModel(name: 'Business', emoji: '🏪', type: EntryType.income, isDefault: true),
    CategoryModel(name: 'Freelance', emoji: '💻', type: EntryType.income, isDefault: true),
    CategoryModel(name: 'Gift', emoji: '🎁', type: EntryType.income, isDefault: true),
    CategoryModel(name: 'Other', emoji: '💰', type: EntryType.income, isDefault: true),
  ];

  static const List<String> categoryEmojis = [
    '🍜', '🚌', '💡', '🏠', '🛍', '💊', '📚', '🎬', '📦', '💼', '🏪', '💻',
    '🎁', '💰', '☕', '🎮', '✈️', '🐶', '👕', '📱', '🏋️', '🧾', '🚗', '🎓',
  ];
}
