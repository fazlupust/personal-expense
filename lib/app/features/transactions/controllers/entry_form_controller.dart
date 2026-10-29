import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/voice_service.dart';
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

  bool isListeningAmount = false;
  bool isListeningNote = false;
  bool isSaving = false;
  bool isDeleting = false;

  bool get isEdit => existing != null;

  List<CategoryModel> get _categories => Get.find<CategoriesController>().byType(type);

  /// Category names for the dropdown (keeps a deleted category selectable when editing).
  List<String> get categoryNames {
    final names = _categories.map((c) => c.name).toList();
    if (category != null && !names.contains(category)) names.add(category!);
    return names;
  }

  List<CategoryModel> get currentCategories => _categories;

  List<String> get accountNames {
    final names = List<String>.of(AppConstants.accounts);
    if (!names.contains(account)) names.add(account);
    return names;
  }

  String emojiOf(String name) => Get.find<CategoriesController>().emojiOf(type, name);

  String displayCategoryName(bool isBn) {
    if (category == null || category!.isEmpty) return 'Select Category'.tr;
    final cat = _categories.firstWhereOrNull((c) => c.name == category);
    if (cat != null) return cat.displayName(isBn);
    return category!.tr;
  }

  @override
  void onInit() {
    super.onInit();
    final e = existing;
    type = e?.type ?? EntryType.expense;
    amountCtrl = TextEditingController(text: e == null ? '' : _plain(e.amount));
    noteCtrl = TextEditingController(text: e?.note ?? '');
    account = e?.account ?? Get.find<SettingsController>().defaultAccount;
    final now = DateTime.now();
    date = e?.date ?? now;
    final names = _categories;
    category = e?.category ?? (names.isEmpty ? null : names.first.name);
  }

  @override
  void onClose() {
    if (isListeningAmount || isListeningNote) {
      VoiceService.stop();
    }
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.onClose();
  }

  String _plain(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  void toggleVoiceAmount() {
    if (isListeningAmount) {
      VoiceService.stop();
      isListeningAmount = false;
      update();
      return;
    }

    if (isListeningNote) {
      VoiceService.stop();
      isListeningNote = false;
    }

    VoiceService.startListening(
      onResult: (words) {
        final parsed = VoiceService.parseSpokenAmount(words);
        if (parsed.isNotEmpty) {
          amountCtrl.text = parsed;
          amountError = null;
          update();
        }
      },
      onListeningChange: (listening) {
        isListeningAmount = listening;
        update();
      },
    );
  }

  void toggleVoiceNote() {
    if (isListeningNote) {
      VoiceService.stop();
      isListeningNote = false;
      update();
      return;
    }

    if (isListeningAmount) {
      VoiceService.stop();
      isListeningAmount = false;
    }

    // Capture text before and after cursor so we append/insert from cursor without clearing existing text
    final currentText = noteCtrl.text;
    final selection = noteCtrl.selection;
    final int cursorPos = (selection.isValid && selection.baseOffset >= 0)
        ? selection.baseOffset
        : currentText.length;

    final prefix = currentText.substring(0, cursorPos);
    final suffix = currentText.substring(cursorPos);
    final spacing = (prefix.isNotEmpty && !prefix.endsWith(' ') && !prefix.endsWith('\n'))
        ? ' '
        : '';

    VoiceService.startListening(
      onResult: (words) {
        if (words.isNotEmpty) {
          final inserted = spacing + words;
          noteCtrl.value = TextEditingValue(
            text: prefix + inserted + suffix,
            selection: TextSelection.collapsed(offset: prefix.length + inserted.length),
          );
          update();
        }
      },
      onListeningChange: (listening) {
        isListeningNote = listening;
        update();
      },
    );
  }

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
    final now = DateTime.now();
    date = DateTime(d.year, d.month, d.day, now.hour, now.minute);
    update();
  }

  /// Returns true when the entry was saved.
  Future<bool> save() async {
    final a = double.tryParse(amountCtrl.text.trim());
    if (a == null || a <= 0) {
      amountError = 'Enter a valid amount.';
      update();
      return false;
    }
    amountError = null;
    isSaving = true;
    update();

    try {
      final selCategory = _categories.firstWhereOrNull((c) => c.name == category);
      final catNameBn = selCategory?.nameBn ?? (category ?? 'Other');
      final catNameEn = selCategory?.nameEn ?? (category ?? 'Other');
      final catId = selCategory?.id ?? 'other';
      final txCtrl = Get.find<TransactionsController>();

      // Budget exceeded notification check
      if (type == EntryType.expense && Get.isRegistered<SettingsController>()) {
        final s = SettingsController.to;
        final txDate = date;
        final monthExpenseEntries = txCtrl.entries.where((e) =>
            e.date.year == txDate.year &&
            e.date.month == txDate.month &&
            e.type == EntryType.expense &&
            e.id != existing?.id);

        final catName = category ?? 'Other';
        final currentCatSpent = monthExpenseEntries
                .where((e) => e.category == catName)
                .fold(0.0, (acc, e) => acc + e.amount) +
            a;
        final currentTotalSpent =
            monthExpenseEntries.fold(0.0, (acc, e) => acc + e.amount) + a;

        final catBudget = s.getCategoryBudget(catName);
        final totalBudget = s.budget;

        final catExceeded = catBudget > 0 && currentCatSpent > catBudget;
        final totalExceeded = totalBudget > 0 && currentTotalSpent > totalBudget;

        if (catExceeded && totalExceeded) {
          final alertTitle = '⚠️ Budget Limits Exceeded!'.tr;
          final alertMessage =
              '${'Category'.tr} "${catName.tr}" & ${'Total monthly budget'.tr} ${'have both been exceeded!'.tr} (${'Spent'.tr}: ${AppConstants.currency}${Fmt.money(currentCatSpent)} / ${'Budget'.tr}: ${AppConstants.currency}${Fmt.money(catBudget)})';
          Future.delayed(const Duration(milliseconds: 350), () {
            _notifyBudgetAlert(title: alertTitle, message: alertMessage);
          });
        } else if (catExceeded) {
          final over = currentCatSpent - catBudget;
          final alertTitle = '⚠️ Category Budget Exceeded!'.tr;
          final alertMessage =
              '${'Budget for'.tr} "${catName.tr}" ${'exceeded by'.tr} ${AppConstants.currency}${Fmt.money(over)} (${'Spent'.tr}: ${AppConstants.currency}${Fmt.money(currentCatSpent)} / ${'Budget'.tr}: ${AppConstants.currency}${Fmt.money(catBudget)})';
          Future.delayed(const Duration(milliseconds: 350), () {
            _notifyBudgetAlert(title: alertTitle, message: alertMessage);
          });
        } else if (totalExceeded) {
          final over = currentTotalSpent - totalBudget;
          final alertTitle = '⚠️ Total Monthly Budget Exceeded!'.tr;
          final alertMessage =
              '${'Total monthly budget exceeded by'.tr} ${AppConstants.currency}${Fmt.money(over)} (${'Spent'.tr}: ${AppConstants.currency}${Fmt.money(currentTotalSpent)} / ${'Budget'.tr}: ${AppConstants.currency}${Fmt.money(totalBudget)})';
          Future.delayed(const Duration(milliseconds: 350), () {
            _notifyBudgetAlert(title: alertTitle, message: alertMessage);
          });
        }
      }

      final effectiveUid = (existing != null && existing!.userId.isNotEmpty)
          ? existing!.userId
          : (Get.isRegistered<AuthService>() ? (Get.find<AuthService>().currentUid ?? '') : '');

      final isEdit = existing != null;
      await txCtrl.save(
        TransactionModel(
          id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          userId: effectiveUid,
          categoryId: catId,
          categoryNameBn: catNameBn,
          categoryNameEn: catNameEn,
          type: type,
          amount: a,
          noteBn: noteCtrl.text.trim(),
          noteEn: noteCtrl.text.trim(),
          account: account,
          date: date,
          createdAt: existing?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          latitude: existing?.latitude,
          longitude: existing?.longitude,
          deviceInfo: existing?.deviceInfo,
        ),
      );

      if (Get.context != null) {
        Get.snackbar(
          'Success'.tr,
          (isEdit ? 'Transaction updated successfully.' : 'Transaction added successfully.').tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1B5E20),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 12,
        );
      }
      return true;
    } finally {
      isSaving = false;
      update();
    }
  }

  void _notifyBudgetAlert({required String title, required String message}) {
    if (Get.context != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 14,
        isDismissible: true,
        boxShadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
  }

  Future<bool> delete() async {
    final e = existing;
    if (e == null) return false;
    isDeleting = true;
    update();
    try {
      await Get.find<TransactionsController>().remove(e.id);
      return true;
    } finally {
      isDeleting = false;
      update();
    }
  }
}
