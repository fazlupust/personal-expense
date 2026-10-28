import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../data/models/entry_type.dart';
import '../../controllers/categories_controller.dart';

class CategoryFormCard extends StatelessWidget {
  const CategoryFormCard({super.key, required this.controller});
  final CategoriesController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final c = controller;
    return AppCard(
      title: 'New category',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentBar<EntryType>(
            options: {EntryType.expense: 'Expense'.tr, EntryType.income: 'Income'.tr},
            value: c.formType,
            onChanged: c.setType,
            colorOf: (t) => t == EntryType.income ? p.income : p.expense,
          ),
          const SizedBox(height: 12),
          const FieldLabel('Category name (English)'),
          TextField(
            controller: c.nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
            onChanged: c.onNameChanged,
            decoration: InputDecoration(
              hintText: 'e.g. Deposit, Savings, etc.'.tr,
              errorText: c.nameError != null && (c.nameCtrl.text.isNotEmpty || c.nameBnCtrl.text.isEmpty)
                  ? c.nameError!.tr
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          const FieldLabel('Category name (Bangla)'),
          TextField(
            controller: c.nameBnCtrl,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
            onChanged: c.onNameBnChanged,
            onSubmitted: (_) => c.create(),
            decoration: InputDecoration(
              hintText: 'e.g. ডিপোজিট, সঞ্চয়, ইত্যাদি'.tr,
              errorText: c.nameError != null && c.nameCtrl.text.isEmpty && c.nameBnCtrl.text.isNotEmpty
                  ? c.nameError!.tr
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          const FieldLabel('Pick an icon'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in AppConstants.categoryEmojis)
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => c.setEmoji(e),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: e == c.formEmoji ? p.income : p.line,
                        width: e == c.formEmoji ? 2 : 1,
                      ),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AppButton('Create category', onPressed: c.create),
        ],
      ),
    );
  }
}
