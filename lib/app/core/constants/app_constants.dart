import '../../data/models/category_model.dart';
import '../../data/models/entry_type.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'My Wallet';
  static const String currency = '৳';

  static const String prefsSettings = 'pe.settings.v1';
  static const String prefsEntries = 'pe.entries.v1';
  static const String prefsCategories = 'pe.categories.v1';

  static const List<String> accounts = ['Cash', 'Bank', 'Mobile wallet', 'Card'];

  static const List<CategoryModel> defaultCategories = [
    CategoryModel(nameEn: 'Food', nameBn: 'খাবার', emoji: '🍜', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Transport', nameBn: 'যাতায়াত', emoji: '🚌', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Bills', nameBn: 'বিল', emoji: '💡', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Rent', nameBn: 'ভাড়া', emoji: '🏠', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Shopping', nameBn: 'কেনাকাটা', emoji: '🛍', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Health', nameBn: 'স্বাস্থ্য', emoji: '💊', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Education', nameBn: 'শিক্ষা', emoji: '📚', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Fun', nameBn: 'বিনোদন', emoji: '🎬', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Other', nameBn: 'অন্যান্য', emoji: '📦', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Salary', nameBn: 'বেতন', emoji: '💼', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Business', nameBn: 'ব্যবসা', emoji: '🏪', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Freelance', nameBn: 'ফ্রিল্যান্স', emoji: '💻', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Gift', nameBn: 'উপহার', emoji: '🎁', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Other', nameBn: 'অন্যান্য', emoji: '💰', type: EntryType.income, isDefault: true),
  ];

  static const List<String> categoryEmojis = [
    '🍜', '🚌', '💡', '🏠', '🛍', '💊', '📚', '🎬', '📦', '💼', '🏪', '💻',
    '🎁', '💰', '☕', '🎮', '✈️', '🐶', '👕', '📱', '🏋️', '🧾', '🚗', '🎓',
  ];
}
