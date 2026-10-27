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
    // Expense Categories
    CategoryModel(nameEn: 'Food', nameBn: 'খাবার', emoji: '🍜', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Groceries', nameBn: 'বাজার ও মুদি', emoji: '🛒', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Transport', nameBn: 'যাতায়াত', emoji: '🚌', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Bills', nameBn: 'বিল ও ইউটিলিটি', emoji: '💡', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Rent', nameBn: 'ভাড়া', emoji: '🏠', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Shopping', nameBn: 'কেনাকাটা', emoji: '🛍️', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Health', nameBn: 'স্বাস্থ্য ও চিকিৎসা', emoji: '💊', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Education', nameBn: 'শিক্ষা ও বই', emoji: '📚', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Family', nameBn: 'পরিবার ও সন্তান', emoji: '👨‍👩‍👧', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Mobile & Internet', nameBn: 'মোবাইল ও রিচার্জ', emoji: '📱', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Vehicle & Fuel', nameBn: 'গাড়ি ও জ্বালানি', emoji: '⛽', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Loan & EMI', nameBn: 'ঋণ ও কিস্তি', emoji: '💳', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Donation', nameBn: 'দান ও সদকা', emoji: '🤲', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Maintenance', nameBn: 'মেরামত ও সার্ভিসিং', emoji: '🔧', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Personal Care', nameBn: 'ব্যক্তিগত যত্ন', emoji: '💇', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Fun', nameBn: 'বিনোদন ও ভ্রমণ', emoji: '🎬', type: EntryType.expense, isDefault: true),
    CategoryModel(nameEn: 'Other', nameBn: 'অন্যান্য ব্যয়', emoji: '📦', type: EntryType.expense, isDefault: true),

    // Income Categories
    CategoryModel(nameEn: 'Salary', nameBn: 'বেতন', emoji: '💼', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Business', nameBn: 'ব্যবসা', emoji: '🏪', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Freelance', nameBn: 'ফ্রিল্যান্স', emoji: '💻', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Investment', nameBn: 'বিনিয়োগ ও মুনাফা', emoji: '📈', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Rental Income', nameBn: 'ভাড়া থেকে আয়', emoji: '🏢', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Bonus', nameBn: 'বোনাস ও ভাতা', emoji: '🎖️', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Gift', nameBn: 'উপহার', emoji: '🎁', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Interest', nameBn: 'লভ্যাংশ ও সুদ', emoji: '🏦', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Sales', nameBn: 'পণ্য বিক্রয়', emoji: '🏷️', type: EntryType.income, isDefault: true),
    CategoryModel(nameEn: 'Other', nameBn: 'অন্যান্য আয়', emoji: '💰', type: EntryType.income, isDefault: true),
  ];

  static const List<String> categoryEmojis = [
    '🍜', '🛒', '🚌', '💡', '🏠', '🛍️', '💊', '📚', '👨‍👩‍👧', '📱', '⛽', '💳', '🤲', '🔧', '💇',
    '🎬', '📦', '💼', '🏪', '💻', '📈', '🏢', '🎖️', '🎁', '🏦', '🏷️', '💰', '☕', '🎮', '✈️', '🐶', '🚗', '🎓',
  ];

  /// Checks if a category name matches any standard default category
  static bool isDefaultCategory(String? nameEn, String? nameBn, [String? name]) {
    String norm(String? s) => (s ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final nEn = norm(nameEn);
    final nBn = norm(nameBn);
    final nLegacy = norm(name);
    for (final d in defaultCategories) {
      final dEn = norm(d.nameEn);
      final dBn = norm(d.nameBn);
      final dLegacy = norm(d.name);
      if ((nEn.isNotEmpty && (nEn == dEn || nEn == dBn || nEn == dLegacy)) ||
          (nBn.isNotEmpty && (nBn == dEn || nBn == dBn || nBn == dLegacy)) ||
          (nLegacy.isNotEmpty && (nLegacy == dEn || nLegacy == dBn || nLegacy == dLegacy))) {
        return true;
      }
    }
    return false;
  }
}
