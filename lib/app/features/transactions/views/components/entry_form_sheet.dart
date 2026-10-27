import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
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
    final isBn = Get.locale?.languageCode == 'bn';

    return GetBuilder<EntryFormController>(
      init: EntryFormController(entry),
      builder: (f) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Material(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
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
                      Icon(
                        f.isEdit ? Icons.edit_note : Icons.add_circle_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        (f.isEdit ? 'Edit entry' : 'New entry').tr,
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
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Form Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Type Segment Bar (Expense / Income)
                        SegmentBar<EntryType>(
                          options: {
                            EntryType.expense: 'Expense'.tr,
                            EntryType.income: 'Income'.tr,
                          },
                          value: f.type,
                          onChanged: f.setType,
                          colorOf: (t) => t == EntryType.income ? p.income : p.expense,
                        ),
                        const SizedBox(height: 12),

                        // Amount Field with Voice Input and Taka (৳) Symbol
                        TextField(
                          controller: f.amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                          decoration: InputDecoration(
                            labelText: 'Amount'.tr,
                            hintText: '0.00',
                            errorText: f.amountError?.tr,
                            prefixIcon: Container(
                              width: 44,
                              alignment: Alignment.center,
                              child: Text(
                                AppConstants.currency,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: p.income,
                                ),
                              ),
                            ),
                            suffixIcon: IconButton(
                              tooltip: 'Voice Input'.tr,
                              onPressed: f.toggleVoiceAmount,
                              icon: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: f.isListeningAmount ? p.expense.withOpacity(0.15) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  f.isListeningAmount ? Icons.mic : Icons.mic_none,
                                  color: f.isListeningAmount ? p.expense : p.mute,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (f.isListeningAmount)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Text(
                              'Listening...'.tr,
                              style: TextStyle(fontSize: 11, color: p.expense, fontWeight: FontWeight.w600),
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Note Field with Voice Input
                        TextField(
                          controller: f.noteCtrl,
                          decoration: InputDecoration(
                            labelText: 'Note'.tr,
                            hintText: 'Note (e.g. lunch, salary)'.tr,
                            prefixIcon: Icon(Icons.edit_note, color: p.mute),
                            suffixIcon: IconButton(
                              tooltip: 'Voice Input'.tr,
                              onPressed: f.toggleVoiceNote,
                              icon: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: f.isListeningNote ? p.expense.withOpacity(0.15) : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  f.isListeningNote ? Icons.mic : Icons.mic_none,
                                  color: f.isListeningNote ? p.expense : p.mute,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (f.isListeningNote)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 12),
                            child: Text(
                              'Listening...'.tr,
                              style: TextStyle(fontSize: 11, color: p.expense, fontWeight: FontWeight.w600),
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Searchable Category Dropdown Selector
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _showCategorySearchSheet(context, f, p, isBn),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Category'.tr,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  f.emojiOf(f.category ?? ''),
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                              suffixIcon: const Icon(Icons.search, size: 20),
                            ),
                            child: Text(
                              f.displayCategoryName(isBn),
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.ink),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Date Selector
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

                        // Location & Device Metadata Display
                        if (f.isEdit && (entry?.latitude != null || entry?.deviceInfo != null)) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: p.bg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: p.mute),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    [
                                      if (entry?.latitude != null && entry?.longitude != null)
                                        '📍 ${entry!.latitude!.toStringAsFixed(4)}, ${entry!.longitude!.toStringAsFixed(4)}',
                                      if (entry?.deviceInfo != null && entry!.deviceInfo!.isNotEmpty)
                                        '📱 ${entry!.deviceInfo!}',
                                    ].join('  ·  '),
                                    style: TextStyle(fontSize: 12, color: p.mute),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (!f.isEdit) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.my_location, size: 14, color: p.mute.withOpacity(0.7)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Location & device info will be attached automatically'.tr,
                                  style: TextStyle(fontSize: 11, color: p.mute.withOpacity(0.8)),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Action Buttons: Cancel and Submit together side-by-side
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                'Cancel',
                                style: AppButtonStyle.cancel,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton(
                                'Submit',
                                onPressed: () {
                                  if (f.save()) Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),

                        if (f.isEdit)
                          AppButton(
                            'Delete entry',
                            style: AppButtonStyle.danger,
                            onPressed: () {
                              f.delete();
                              Navigator.of(context).pop();
                            },
                          ),
                      ],
                    ),
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

  /// Opens an interactive searchable category bottom sheet
  void _showCategorySearchSheet(
    BuildContext context,
    EntryFormController f,
    AppPalette p,
    bool isBn,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (_) => _CategorySearchSheet(formCtrl: f, pal: p, isBn: isBn),
    );
  }
}

/// Interactive searchable dropdown picker for categories
class _CategorySearchSheet extends StatefulWidget {
  const _CategorySearchSheet({
    required this.formCtrl,
    required this.pal,
    required this.isBn,
  });

  final EntryFormController formCtrl;
  final AppPalette pal;
  final bool isBn;

  @override
  State<_CategorySearchSheet> createState() => _CategorySearchSheetState();
}

class _CategorySearchSheetState extends State<_CategorySearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pal;
    final allCategories = widget.formCtrl.currentCategories;
    final query = _query.trim().toLowerCase();

    final filtered = allCategories.where((c) {
      if (query.isEmpty) return true;
      final name = c.name.toLowerCase();
      final bn = c.nameBn.toLowerCase();
      final en = c.nameEn.toLowerCase();
      final emoji = c.emoji;
      return name.contains(query) || bn.contains(query) || en.contains(query) || emoji.contains(query);
    }).toList();

    return Material(
      color: p.card,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                color: p.income,
                child: Row(
                  children: [
                    const Icon(Icons.category_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Select Category'.tr,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
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

              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: false,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search categories...'.tr,
                    prefixIcon: Icon(Icons.search, color: p.mute),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),

              // Category List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: p.mute.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text(
                              'No categories found'.tr,
                              style: TextStyle(color: p.mute, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: p.line),
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          final isSelected = c.name == widget.formCtrl.category;
                          final displayName = c.displayName(widget.isBn);
                          final subtitle = widget.isBn ? c.nameEn : c.nameBn;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            leading: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? p.income.withOpacity(0.15) : p.bg,
                                shape: BoxShape.circle,
                              ),
                              child: Text(c.emoji, style: const TextStyle(fontSize: 22)),
                            ),
                            title: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? p.income : p.ink,
                              ),
                            ),
                            subtitle: subtitle.isNotEmpty && subtitle != displayName
                                ? Text(subtitle, style: TextStyle(fontSize: 12, color: p.mute))
                                : null,
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: p.income, size: 22)
                                : null,
                            onTap: () {
                              widget.formCtrl.setCategory(c.name);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
