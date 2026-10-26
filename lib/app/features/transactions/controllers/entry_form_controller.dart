import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/models/transaction_model.dart';
import '../../categories/controllers/categories_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import 'transactions_controller.dart';

class EntryFormController extends GetxController {
  EntryFormController(this.existing);
  final TransactionModel? existing;

  late final TextEditingController amountCtrl;
  late final TextEditingController noteCtrl;
  late EntryType type;
  late String account;
  late DateTime date;
  String? category;
  String? amountError;

  bool get isEdit => existing != null;

  List<CategoryModel> get _categories => Get.find<CategoriesController>().byType(type);

  /// Category names for the dropdown (keeps a deleted category selectable when editing).
  List<String> get categoryNames {
    final names = _categories.map((c) => c.name).toList();
    if (category != null && !names.contains(category)) names.add(category!);
    return names;
  }

  List<String> get accountNames {
    final names = List<String>.of(AppConstants.accounts);
    if (!names.contains(account)) names.add(account);
    return names;
  }

  String emojiOf(String name) => Get.find<CategoriesController>().emojiOf(type, name);

  @override
  void onInit() {
    super.onInit();
    final e = existing;
    type = e?.type ?? EntryType.expense;
    amountCtrl = TextEditingController(text: e == null ? '' : _plain(e.amount));
    noteCtrl = TextEditingController(text: e?.note ?? '');
    account = e?.account ?? Get.find<SettingsController>().defaultAccount;
    final now = DateTime.now();
    date = e?.date ?? DateTime(now.year, now.month, now.day);
    final names = _categories;
    category = e?.category ?? (names.isEmpty ? null : names.first.name);
  }

  @override
  void onClose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.onClose();
  }

  String _plain(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  void setType(EntryType t) {
    type = t;
    final names = _categories.map((c) => c.name).toList();
    if (category == null || !names.contains(category)) {
      category = names.isEmpty ? null : names.first;
    }
    update();
  }

  void setCategory(String v) {
    category = v;
    update();
  }

  void setAccount(String v) {
    account = v;
    update();
  }

  void setDate(DateTime d) {
    date = DateTime(d.year, d.month, d.day);
    update();
  }

  /// Returns true when the entry was saved.
  bool save() {
    final a = double.tryParse(amountCtrl.text.trim());
    if (a == null || a <= 0) {
      amountError = 'Enter a valid amount.';
      update();
      return false;
    }
    amountError = null;

    final selCategory = _categories.firstWhereOrNull((c) => c.name == category);
    final catNameBn = selCategory?.nameBn ?? (category ?? 'Other');
    final catNameEn = selCategory?.nameEn ?? (category ?? 'Other');
    final catId = selCategory?.id ?? 'other';

    Get.find<TransactionsController>().save(
      TransactionModel(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: existing?.userId ?? '',
        categoryId: catId,
        categoryNameBn: catNameBn,
        categoryNameEn: catNameEn,
        type: type,
        amount: a,
        noteBn: noteCtrl.text.trim(),
        noteEn: noteCtrl.text.trim(),
        account: account,
        date: date,
        latitude: existing?.latitude,
        longitude: existing?.longitude,
        deviceInfo: existing?.deviceInfo,
      ),
    );
    return true;
  }

  void delete() {
    final e = existing;
    if (e != null) Get.find<TransactionsController>().remove(e.id);
  }
}
