import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../../notes/controllers/notes_controller.dart';
import '../../../transactions/controllers/transactions_controller.dart';
import '../../controllers/settings_controller.dart';

void showDataExportSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    constraints: const BoxConstraints(maxWidth: 580),
    builder: (ctx) => const DataExportSheet(),
  );
}

class DataExportSheet extends StatelessWidget {
  const DataExportSheet({super.key});

  String _cleanCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  String _generateTransactionsCsv(TransactionsController tc) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('ID,Date,Time,Type,Category,Amount,Account,Note');
    for (final e in tc.entries) {
      final dateStr = Fmt.date(e.date, 'yyyy-MM-dd');
      final timeStr = Fmt.date(e.date, 'hh:mm a');
      final typeStr = e.type.name;
      final categoryStr = _cleanCsvField(e.category);
      final amountStr = e.amount.toStringAsFixed(2);
      final accountStr = _cleanCsvField(e.account);
      final noteStr = _cleanCsvField(e.note);
      buffer.writeln('${e.id},$dateStr,$timeStr,$typeStr,$categoryStr,$amountStr,$accountStr,$noteStr');
    }
    return buffer.toString();
  }

  String _generateNotesCsv(NotesController nc) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('SL,Date,Time,Title,Person,Amount,Note');
    for (int i = 0; i < nc.notes.length; i++) {
      final n = nc.notes[i];
      final sl = i + 1;
      final dateStr = Fmt.date(n.date, 'yyyy-MM-dd');
      final timeStr = Fmt.date(n.date, 'hh:mm a');
      final titleStr = _cleanCsvField(n.title);
      final personStr = _cleanCsvField(n.personName);
      final amountStr = n.amount.toStringAsFixed(2);
      final noteStr = _cleanCsvField(n.notes);
      buffer.writeln('$sl,$dateStr,$timeStr,$titleStr,$personStr,$amountStr,$noteStr');
    }
    return buffer.toString();
  }

  String _generateFullJsonBackup(TransactionsController tc, NotesController nc, SettingsController sc) {
    final map = {
      'exported_at': DateTime.now().toIso8601String(),
      'app': AppConstants.appName,
      'settings': {
        'language': sc.langCode,
        'monthly_budget': sc.budget,
        'category_budgets': sc.categoryBudgets,
        'default_account': sc.defaultAccount,
      },
      'transactions': tc.entries.map((e) => e.toMap()).toList(),
      'notes': nc.notes.map((n) => n.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  void _copyToClipboard(BuildContext context, String data, String title) {
    Clipboard.setData(ClipboardData(text: data));
    Get.snackbar(
      title.tr,
      'Copied to clipboard! You can paste it into Excel or Google Sheets.'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: context.pal.card,
      colorText: context.pal.ink,
      duration: const Duration(seconds: 3),
      maxWidth: 420,
      margin: const EdgeInsets.all(14),
    );
  }

  Future<void> _shareBackup(BuildContext context, String jsonStr) async {
    await Clipboard.setData(ClipboardData(text: jsonStr));

    final dateStr = Fmt.date(DateTime.now(), 'yyyy-MM-dd');
    final subject = 'Personal Expense JSON Backup ($dateStr)';

    // Launch mailto if payload fits in standard URI length
    if (jsonStr.length < 2500) {
      final mailtoUri = Uri(
        scheme: 'mailto',
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(jsonStr)}',
      );
      try {
        if (await canLaunchUrl(mailtoUri)) {
          await launchUrl(mailtoUri);
        }
      } catch (_) {}
    }

    if (context.mounted) {
      Get.snackbar(
        'Backup Ready & Copied'.tr,
        'Backup JSON copied to clipboard! You can paste and share it in any app.'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: context.pal.card,
        colorText: context.pal.ink,
        duration: const Duration(seconds: 4),
        maxWidth: 420,
        margin: const EdgeInsets.all(14),
      );
    }
  }

  void _showBackupSuccessSheet(
    BuildContext context,
    String jsonStr,
    int txCount,
    int notesCount,
  ) {
    final p = context.pal;
    final dateStr = Fmt.date(DateTime.now(), 'yyyy-MM-dd, hh:mm a');

    // Auto-copy so the user always has it ready
    Clipboard.setData(ClipboardData(text: jsonStr));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 580),
      builder: (sheetContext) {
        return Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: p.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header bar with Back button and Close button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Back'.tr,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Full Backup Completed'.tr,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: p.mute),
                    tooltip: 'Close'.tr,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Success Summary Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      p.income.withOpacity(0.12),
                      p.income.withOpacity(0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.income.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.income,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Backup Generated Successfully!'.tr,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All transactions, notes & settings are packed in JSON format.'.tr,
                            style: TextStyle(fontSize: 12, color: p.mute),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              Text(
                                '🧾 $txCount ${'entries'.tr}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: p.income,
                                ),
                              ),
                              Text(
                                '📝 $notesCount ${'notes'.tr}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: p.income,
                                ),
                              ),
                              Text(
                                '🕒 $dateStr',
                                style: TextStyle(fontSize: 11.5, color: p.mute),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Action 1: Share Backup Button
              AppButton(
                'Share Backup',
                icon: Icons.share_rounded,
                height: 48,
                fontSize: 15,
                margin: const EdgeInsets.only(bottom: 10),
                onPressed: () => _shareBackup(sheetContext, jsonStr),
              ),

              // Action 2: Copy JSON & Preview Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      'Copy JSON',
                      icon: Icons.copy_rounded,
                      style: AppButtonStyle.outlined,
                      height: 44,
                      fontSize: 13.5,
                      margin: EdgeInsets.zero,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: jsonStr));
                        Get.snackbar(
                          'Success'.tr,
                          'Backup JSON copied to clipboard!'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                          maxWidth: 420,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      'Preview',
                      icon: Icons.visibility_outlined,
                      style: AppButtonStyle.outlined,
                      height: 44,
                      fontSize: 13.5,
                      margin: EdgeInsets.zero,
                      onPressed: () {
                        _previewData(sheetContext, jsonStr, 'Full Data Backup (JSON)');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action 3: Navigation buttons (Back / Back to Settings)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      'Back',
                      icon: Icons.arrow_back_rounded,
                      style: AppButtonStyle.outlined,
                      height: 44,
                      fontSize: 13,
                      margin: EdgeInsets.zero,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      'Back to Settings',
                      icon: Icons.done_all_rounded,
                      style: AppButtonStyle.outlined,
                      height: 44,
                      fontSize: 13,
                      margin: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _previewData(BuildContext context, String data, String title) {
    final p = context.pal;
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    tooltip: 'Back'.tr,
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title.tr,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20, color: p.mute),
                    tooltip: 'Close'.tr,
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.line),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      data,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: p.ink,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      'Back',
                      icon: Icons.arrow_back_rounded,
                      style: AppButtonStyle.outlined,
                      height: 42,
                      fontSize: 13,
                      margin: EdgeInsets.zero,
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      'Copy All',
                      icon: Icons.copy_rounded,
                      height: 42,
                      fontSize: 13,
                      margin: EdgeInsets.zero,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: data));
                        Navigator.of(dialogCtx).pop();
                        Get.snackbar(
                          title.tr,
                          'Copied to clipboard!'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                          maxWidth: 400,
                          margin: const EdgeInsets.all(12),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tc = Get.find<TransactionsController>();
    final nc = Get.isRegistered<NotesController>() ? Get.find<NotesController>() : null;
    final sc = Get.find<SettingsController>();

    final txCount = tc.entries.length;
    final notesCount = nc?.notes.length ?? 0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 580),
      margin: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: p.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: p.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: p.income.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.download_rounded, color: p.income, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Data'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Export transactions & notes into CSV or JSON'.tr,
                      style: TextStyle(fontSize: 12.5, color: p.mute),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 22, color: p.mute),
                tooltip: 'Close'.tr,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Counts summary
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transactions'.tr,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.mute),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$txCount ${'entries'.tr}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.income),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes & Debts'.tr,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.mute),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$notesCount ${'notes'.tr}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.acc),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Option 1: Export Transactions CSV
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart_rounded, size: 24, color: p.income),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transactions (CSV)'.tr,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Date, Time, Type, Category, Amount, Note'.tr,
                        style: TextStyle(fontSize: 11.5, color: p.mute),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.visibility_outlined, size: 18, color: p.mute),
                  tooltip: 'Preview'.tr,
                  onPressed: () {
                    final csv = _generateTransactionsCsv(tc);
                    _previewData(context, csv, 'Transactions (CSV)');
                  },
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: () {
                    final csv = _generateTransactionsCsv(tc);
                    _copyToClipboard(context, csv, 'Transactions (CSV)');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                  label: Text('Copy'.tr, style: const TextStyle(fontSize: 12.5)),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.income,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Option 2: Export Notes & Debts CSV
          if (nc != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.line),
              ),
              child: Row(
                children: [
                  Icon(Icons.note_alt_rounded, size: 24, color: p.acc),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes & Debts (CSV)'.tr,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'SL, Date, Time, Title, Person, Amount'.tr,
                          style: TextStyle(fontSize: 11.5, color: p.mute),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.visibility_outlined, size: 18, color: p.mute),
                    tooltip: 'Preview'.tr,
                    onPressed: () {
                      final csv = _generateNotesCsv(nc);
                      _previewData(context, csv, 'Notes & Debts (CSV)');
                    },
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: () {
                      final csv = _generateNotesCsv(nc);
                      _copyToClipboard(context, csv, 'Notes & Debts (CSV)');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                    label: Text('Copy'.tr, style: const TextStyle(fontSize: 12.5)),
                    style: FilledButton.styleFrom(
                      backgroundColor: p.income,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Option 3: Full JSON Backup
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              final jsonStr = _generateFullJsonBackup(tc, nc ?? NotesController(), sc);
              _showBackupSuccessSheet(context, jsonStr, txCount, notesCount);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: p.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.line),
              ),
              child: Row(
                children: [
                  Icon(Icons.backup_rounded, size: 24, color: p.ink),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Data Backup (JSON)'.tr,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Complete backup of all transactions, notes, settings'.tr,
                          style: TextStyle(fontSize: 11.5, color: p.mute),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.visibility_outlined, size: 18, color: p.mute),
                    tooltip: 'Preview'.tr,
                    onPressed: () {
                      final jsonStr = _generateFullJsonBackup(tc, nc ?? NotesController(), sc);
                      _previewData(context, jsonStr, 'Full Data Backup (JSON)');
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.share_rounded, size: 18, color: p.income),
                    tooltip: 'Share Backup'.tr,
                    onPressed: () {
                      final jsonStr = _generateFullJsonBackup(tc, nc ?? NotesController(), sc);
                      _shareBackup(context, jsonStr);
                    },
                  ),
                  const SizedBox(width: 2),
                  FilledButton.icon(
                    onPressed: () {
                      final jsonStr = _generateFullJsonBackup(tc, nc ?? NotesController(), sc);
                      _showBackupSuccessSheet(context, jsonStr, txCount, notesCount);
                    },
                    icon: const Icon(Icons.backup_rounded, size: 14, color: Colors.white),
                    label: Text('Backup'.tr, style: const TextStyle(fontSize: 12.5)),
                    style: FilledButton.styleFrom(
                      backgroundColor: p.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cancel / Close button
          AppButton(
            'Close',
            style: AppButtonStyle.outlined,
            height: 44,
            fontSize: 14,
            margin: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
