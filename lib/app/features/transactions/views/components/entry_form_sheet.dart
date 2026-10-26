import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/entry_type.dart';
import '../../../../data/models/transaction_model.dart';
import '../../controllers/entry_form_controller.dart';

/// Opens the add / edit entry bottom sheet (centered, max 520px on wide screens).
Future<void> showEntrySheet(BuildContext context, {TransactionModel? entry}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => EntryFormSheet(entry: entry),
  );
}

class EntryFormSheet extends StatelessWidget {
  const EntryFormSheet({super.key, this.entry});
  final TransactionModel? entry;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GetBuilder<EntryFormController>(
      init: EntryFormController(entry),
      builder: (f) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Material(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      (f.isEdit ? 'Edit entry' : 'New entry').tr,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink),
                    ),
                  ),
                  SegmentBar<EntryType>(
                    options: {
                      EntryType.expense: 'Expense'.tr,
                      EntryType.income: 'Income'.tr,
                    },
                    value: f.type,
                    onChanged: f.setType,
                    colorOf: (t) => t == EntryType.income ? p.income : p.expense,
                  ),
                  TextField(
                    controller: f.amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: InputDecoration(hintText: 'Amount'.tr, errorText: f.amountError?.tr),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: f.noteCtrl,
                    decoration: InputDecoration(hintText: 'Note (e.g. lunch, salary)'.tr),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: f.category,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: 'Category'.tr),
                          items: [
                            for (final n in f.categoryNames)
                              DropdownMenuItem(
                                value: n,
                                child: Text('${f.emojiOf(n)} ${n.tr}', overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) f.setCategory(v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: f.account,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: 'Account'.tr),
                          items: [
                            for (final a in f.accountNames)
                              DropdownMenuItem(
                                value: a,
                                child: Text(a.tr, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) f.setAccount(v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: f.date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) f.setDate(d);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date'.tr,
                        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                      ),
                      child: Text(Fmt.date(f.date, 'd MMMM yyyy'), style: TextStyle(color: p.ink)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppButton('Save entry', onPressed: () {
                    if (f.save()) Navigator.of(context).pop();
                  }),
                  if (f.isEdit)
                    AppButton('Delete entry', style: AppButtonStyle.danger, onPressed: () {
                      f.delete();
                      Navigator.of(context).pop();
                    }),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'.tr, style: TextStyle(color: p.mute, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
