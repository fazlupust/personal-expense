import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/entry_type.dart';
import '../../../categories/controllers/categories_controller.dart';
import '../../../transactions/controllers/transactions_controller.dart';
import '../../controllers/settings_controller.dart';

Future<void> showBudgetManagementSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 540),
    builder: (_) => const BudgetManagementSheet(),
  );
}

class BudgetManagementSheet extends StatefulWidget {
  const BudgetManagementSheet({super.key});

  @override
  State<BudgetManagementSheet> createState() => _BudgetManagementSheetState();
}

class _BudgetManagementSheetState extends State<BudgetManagementSheet> {
  final _totalBudgetCtrl = TextEditingController();
  final Map<String, TextEditingController> _catControllers = {};

  @override
  void initState() {
    super.initState();
    final s = SettingsController.to;
    _totalBudgetCtrl.text = s.budget > 0 ? _plain(s.budget) : '';

    final categories = Get.isRegistered<CategoriesController>()
        ? Get.find<CategoriesController>().byType(EntryType.expense)
        : AppConstants.defaultCategories.where((c) => c.type == EntryType.expense).toList();

    for (final cat in categories) {
      final b = s.getCategoryBudget(cat.name);
      _catControllers[cat.name] = TextEditingController(text: b > 0 ? _plain(b) : '');
    }
  }

  @override
  void dispose() {
    _totalBudgetCtrl.dispose();
    for (final ctrl in _catControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  String _plain(double v) => v % 1 == 0 ? v.toInt().toString() : v.toString();

  void _save() {
    final s = SettingsController.to;

    // Save Total Budget
    final totalText = _totalBudgetCtrl.text.trim();
    final total = totalText.isEmpty ? 0.0 : (double.tryParse(totalText) ?? 0.0);
    s.setTotalBudget(total);

    // Save Category Budgets
    final Map<String, double> newCatBudgets = {};
    for (final entry in _catControllers.entries) {
      final text = entry.value.text.trim();
      final val = text.isEmpty ? 0.0 : (double.tryParse(text) ?? 0.0);
      if (val > 0) {
        newCatBudgets[entry.key] = val;
      }
    }
    s.setCategoryBudgets(newCatBudgets);

    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (Get.context != null) {
        Get.snackbar(
          AppConstants.appName.tr,
          'Budgets saved successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';
    final categories = Get.isRegistered<CategoriesController>()
        ? Get.find<CategoriesController>().byType(EntryType.expense)
        : AppConstants.defaultCategories.where((c) => c.type == EntryType.expense).toList();

    final tc = Get.isRegistered<TransactionsController>() ? Get.find<TransactionsController>() : null;
    final currentRows = tc?.currentMonthRows ?? [];
    final catSpending = tc != null ? tc.group(currentRows, EntryType.expense) : <String, double>{};
    final totalExpense = tc != null ? tc.sum(currentRows, EntryType.expense) : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Primary Color Header Bar with Close Button (Frozen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: p.income,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Manage Budgets'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Total Monthly Budget Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Total Monthly Budget'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.ink),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${'Current Spent:'.tr} ${Fmt.money(totalExpense)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.mute),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _totalBudgetCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Text(
                                AppConstants.currency,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: p.income),
                              ),
                            ),
                            hintText: '0 (No budget limit)'.tr,
                            filled: true,
                            fillColor: p.card,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: p.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: p.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: p.income, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Category Budgets Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Category Budgets'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Set budget per category'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: p.mute),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Category Budget List
                  for (final cat in categories)
                    _buildCategoryRow(
                      cat: cat,
                      isBn: isBn,
                      p: p,
                      spent: catSpending[cat.name] ?? 0.0,
                    ),
                ],
              ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.income,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Budgets'.tr,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow({
    required dynamic cat,
    required bool isBn,
    required AppPalette p,
    required double spent,
  }) {
    final catName = cat.name as String;
    final ctrl = _catControllers[catName]!;
    final budgetVal = double.tryParse(ctrl.text.trim()) ?? 0.0;
    final hasBudget = budgetVal > 0;
    final isExceeded = hasBudget && spent > budgetVal;
    final progress = hasBudget ? (spent / budgetVal).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExceeded ? const Color(0xFFE74C3C).withOpacity(0.5) : p.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.card, shape: BoxShape.circle),
                child: Text(cat.emoji as String, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.displayName(isBn) as String,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.ink),
                    ),
                    Text(
                      '${'Spent:'.tr} ${Fmt.money(spent)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isExceeded ? const Color(0xFFE74C3C) : p.mute,
                        fontWeight: isExceeded ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.ink),
                  decoration: InputDecoration(
                    prefixText: '${AppConstants.currency} ',
                    prefixStyle: TextStyle(fontSize: 13, color: p.income, fontWeight: FontWeight.w700),
                    hintText: '0',
                    isDense: true,
                    filled: true,
                    fillColor: p.card,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: p.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: p.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: p.income),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasBudget) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: p.line,
                      valueColor: AlwaysStoppedAnimation(
                        isExceeded ? const Color(0xFFE74C3C) : p.income,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isExceeded
                      ? '+${Fmt.money(spent - budgetVal)} ${'over'.tr}'
                      : '${((spent / budgetVal) * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isExceeded ? const Color(0xFFE74C3C) : p.mute,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
