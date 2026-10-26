import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../../notes/controllers/notes_controller.dart';

Future<void> showNoteFormSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 520),
    builder: (_) => const NoteFormSheet(),
  );
}

class NoteFormSheet extends StatelessWidget {
  const NoteFormSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return GetBuilder<NotesController>(
      builder: (c) {
        final isEdit = c.editingNote != null;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Material(
            color: p.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(color: p.income),
                      child: Row(
                        children: [
                          Icon(
                            isEdit ? Icons.edit_note_rounded : Icons.note_add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            (isEdit ? 'Edit Note' : 'New Note').tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Form Fields
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Note Title
                          TextField(
                            controller: c.titleCtrl,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Title'.tr,
                              hintText: 'e.g. Loan given, Borrowed money, Due...'.tr,
                              errorText: c.titleError,
                              prefixIcon: Icon(Icons.title_rounded, color: p.income, size: 20),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 2. Person Name
                          TextField(
                            controller: c.personCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Person Name (Lender/Borrower)'.tr,
                              hintText: 'e.g. Rahim, Uncle, XYZ...'.tr,
                              prefixIcon: Icon(Icons.person_outline_rounded, color: p.income, size: 20),
                            ),
                          ),

                          // Quick suggestion chips for existing person names
                          if (c.uniquePersons.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                for (final name in c.uniquePersons.take(5))
                                  ActionChip(
                                    label: Text(name, style: const TextStyle(fontSize: 11)),
                                    avatar: const Icon(Icons.person, size: 13),
                                    backgroundColor: p.bg,
                                    side: BorderSide(color: p.line),
                                    onPressed: () {
                                      c.personCtrl.text = name;
                                      c.update();
                                    },
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),

                          // 3. Amount & Date Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Amount Field (Optional)
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: c.amountCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                  decoration: InputDecoration(
                                    labelText: 'Amount (Optional)'.tr,
                                    hintText: '0.00',
                                    prefixIcon: Container(
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: Text(
                                        AppConstants.currency,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: p.income,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Date Picker Box
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: c.formDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2035),
                                    );
                                    if (picked != null) {
                                      c.setFormDate(picked);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 52,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: p.bg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: p.line),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 16, color: p.income),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Date'.tr,
                                                style: TextStyle(fontSize: 10, color: p.mute),
                                              ),
                                              Text(
                                                Fmt.date(c.formDate, 'd MMM yyyy'),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: p.ink,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 4. Description / Note Details
                          TextField(
                            controller: c.notesCtrl,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: 'Note description / details'.tr,
                              hintText: 'Add details, repayment promises, or notes...'.tr,
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Location note indicator
                          Row(
                            children: [
                              Icon(Icons.my_location, size: 13, color: p.mute.withOpacity(0.7)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Location & device info will be attached automatically'.tr,
                                  style: TextStyle(fontSize: 11, color: p.mute.withOpacity(0.8)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 5. Action Buttons: Cancel and Save side-by-side
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  'Cancel',
                                  style: AppButtonStyle.outlined,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: AppButton(
                                  'Save Note',
                                  onPressed: () async {
                                    final ok = await c.save();
                                    if (ok && context.mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          if (isEdit) ...[
                            const SizedBox(height: 4),
                            AppButton(
                              'Delete Note',
                              style: AppButtonStyle.danger,
                              onPressed: () {
                                if (c.editingNote != null) {
                                  c.delete(c.editingNote!);
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
