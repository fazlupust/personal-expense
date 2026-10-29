import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:personal_expense/app/core/theme/app_theme.dart';
import 'package:personal_expense/app/features/notes/controllers/notes_controller.dart';
import 'package:personal_expense/app/features/prayer_tasbih/controllers/prayer_tasbih_controller.dart';
import 'package:personal_expense/app/features/transactions/controllers/transactions_controller.dart';
import 'package:personal_expense/app/features/settings/controllers/settings_controller.dart';
import 'data_export_generator.dart';
import 'export_dialogs.dart';
import 'export_file_sharer.dart';

class ExportPillButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isLoading;
  final Color? color;

  const ExportPillButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final primary = color ?? const Color(0xFF1F8A5B);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLoading
              ? [primary.withOpacity(0.7), primary.withOpacity(0.9)]
              : [primary, const Color(0xFF2ECC71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 5),
                ] else ...[
                  Icon(icon, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  isLoading ? 'Generating...'.tr : label.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExportIconAction extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color? color;
  final bool isLoading;

  const ExportIconAction({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.grey),
              ),
            )
          : Icon(icon, size: 19, color: color),
      tooltip: tooltip.tr,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      onPressed: isLoading ? null : onPressed,
    );
  }
}

class ExportActionCards {
  const ExportActionCards._();

  static Widget buildMultiTabExcelCard({
    required BuildContext context,
    required TransactionsController tc,
    required NotesController? nc,
    required PrayerTasbihController? ptc,
    required int txCount,
    required int notesCount,
    required int tasbihCount,
    required String todayStr,
    required AppPalette p,
    required String? loadingAction,
    required ValueChanged<String?> onLoading,
  }) {
    Future<void> shareMultiTabExcel() async {
      onLoading('excel_all');
      BuildContext? dlgCtx;
      ExportDialogs.showLoadingProgressDialog(
        context,
        p,
        title: 'Generating Excel file...',
        subtitle: 'Packing 3 tabs into Excel (.xlsx)...',
        status: 'Preparing Excel workbook...',
        statusIcon: Icons.table_view_rounded,
        onCreated: (ctx) => dlgCtx = ctx,
      );
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (dlgCtx != null && dlgCtx!.mounted) {
        Navigator.of(dlgCtx!).pop();
      }
      final bytes = DataExportGenerator.generateMultiTabExcel(tc, nc, ptc);
      if (bytes != null && context.mounted) {
        await ExportFileSharer.shareBytesFile(
          context,
          bytes: bytes,
          fileName: 'personal_expense_all_$todayStr.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          subject: 'Personal Expense All Data Workbook ($todayStr)',
        );
      }
      onLoading(null);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.income.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: p.income.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: p.income.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.table_view_rounded, size: 24, color: p.income),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multi-Tab Excel Workbook (.xlsx)'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: p.income,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '1 file with 3 tabs: Transactions, Notes, Zikir'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: p.mute),
                ),
              ],
            ),
          ),
          ExportIconAction(
            icon: Icons.visibility_outlined,
            tooltip: 'Preview Tabs',
            color: p.mute,
            onPressed: loadingAction != null
                ? null
                : () => ExportDialogs.showWorkbookPreviewDialog(
                      context,
                      txCount: txCount,
                      notesCount: notesCount,
                      tasbihCount: tasbihCount,
                      onShareExcel: () async {
                        onLoading('excel_all');
                        await Future<void>.delayed(const Duration(milliseconds: 300));
                        final bytes = DataExportGenerator.generateMultiTabExcel(tc, nc, ptc);
                        if (bytes != null && context.mounted) {
                          await ExportFileSharer.shareBytesFile(
                            context,
                            bytes: bytes,
                            fileName: 'personal_expense_all_$todayStr.xlsx',
                            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                            subject: 'Personal Expense All Data Workbook ($todayStr)',
                          );
                        }
                        onLoading(null);
                      },
                    ),
          ),
          const SizedBox(width: 2),
          ExportPillButton(
            icon: Icons.share_rounded,
            label: 'Share Excel',
            color: p.income,
            isLoading: loadingAction == 'excel_all',
            onPressed: loadingAction != null ? null : shareMultiTabExcel,
          ),
        ],
      ),
    );
  }

  static Widget buildTransactionsCsvCard({
    required BuildContext context,
    required TransactionsController tc,
    required String todayStr,
    required AppPalette p,
    required String? loadingAction,
    required ValueChanged<String?> onLoading,
  }) {
    return Container(
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
          ExportIconAction(
            icon: Icons.visibility_outlined,
            tooltip: 'Preview',
            color: p.mute,
            onPressed: loadingAction != null
                ? null
                : () {
                    final csv = DataExportGenerator.generateTransactionsCsv(tc);
                    ExportDialogs.showDataPreviewDialog(context, csv, 'Transactions (CSV)');
                  },
          ),
          ExportIconAction(
            icon: Icons.copy_rounded,
            tooltip: 'Copy',
            color: p.mute,
            onPressed: loadingAction != null
                ? null
                : () {
                    final csv = DataExportGenerator.generateTransactionsCsv(tc);
                    ExportFileSharer.copyToClipboard(context, csv, 'Transactions (CSV)');
                  },
          ),
          const SizedBox(width: 2),
          ExportPillButton(
            icon: Icons.share_rounded,
            label: 'Share',
            isLoading: loadingAction == 'tx_share',
            onPressed: loadingAction != null
                ? null
                : () async {
                    onLoading('tx_share');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    final csv = DataExportGenerator.generateTransactionsCsv(tc);
                    if (context.mounted) {
                      await ExportFileSharer.shareFile(
                        context,
                        content: csv,
                        fileName: 'transactions_$todayStr.csv',
                        mimeType: 'text/csv',
                        subject: 'Personal Expense Transactions ($todayStr)',
                      );
                    }
                    onLoading(null);
                  },
          ),
        ],
      ),
    );
  }

  static Widget buildTransactionsExcelCard({
    required BuildContext context,
    required TransactionsController tc,
    required String todayStr,
    required AppPalette p,
    required String? loadingAction,
    required ValueChanged<String?> onLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Icon(Icons.table_view_rounded, size: 24, color: p.income),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transactions (Excel .xlsx)'.tr,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
                ),
                const SizedBox(height: 1),
                Text(
                  'Excel format with formatting & headers'.tr,
                  style: TextStyle(fontSize: 11.5, color: p.mute),
                ),
              ],
            ),
          ),
          ExportPillButton(
            icon: Icons.share_rounded,
            label: 'Share Excel',
            color: p.income,
            isLoading: loadingAction == 'excel_tx',
            onPressed: loadingAction != null
                ? null
                : () async {
                    onLoading('excel_tx');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    final rows = tc.entries
                        .map((e) => <CellValue>[
                              TextCellValue(e.id),
                              TextCellValue(DataExportGenerator.formatIsoDate(e.date)),
                              TextCellValue(DataExportGenerator.formatAsciiTime(e.date)),
                              TextCellValue(e.type.name.toUpperCase()),
                              TextCellValue(e.category),
                              DoubleCellValue(e.amount),
                              TextCellValue(e.account),
                              TextCellValue(e.note),
                            ])
                        .toList();
                    final bytes = DataExportGenerator.generateSingleTabExcel(
                      sheetName: 'Transactions',
                      headers: [
                        TextCellValue('ID'),
                        TextCellValue('Date'),
                        TextCellValue('Time'),
                        TextCellValue('Type'),
                        TextCellValue('Category'),
                        TextCellValue('Amount (Tk)'),
                        TextCellValue('Account'),
                        TextCellValue('Note'),
                      ],
                      rows: rows,
                    );
                    if (bytes != null && context.mounted) {
                      await ExportFileSharer.shareBytesFile(
                        context,
                        bytes: bytes,
                        fileName: 'transactions_$todayStr.xlsx',
                        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                        subject: 'Personal Expense Transactions ($todayStr)',
                      );
                    }
                    onLoading(null);
                  },
          ),
        ],
      ),
    );
  }

  static Widget buildNotesCsvCard({
    required BuildContext context,
    required NotesController nc,
    required String todayStr,
    required AppPalette p,
    required String? loadingAction,
    required ValueChanged<String?> onLoading,
  }) {
    return Container(
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
          ExportIconAction(
            icon: Icons.visibility_outlined,
            tooltip: 'Preview',
            color: p.mute,
            onPressed: loadingAction != null
                ? null
                : () {
                    final csv = DataExportGenerator.generateNotesCsv(nc);
                    ExportDialogs.showDataPreviewDialog(context, csv, 'Notes & Debts (CSV)');
                  },
          ),
          ExportIconAction(
            icon: Icons.copy_rounded,
            tooltip: 'Copy',
            color: p.mute,
            onPressed: loadingAction != null
                ? null
                : () {
                    final csv = DataExportGenerator.generateNotesCsv(nc);
                    ExportFileSharer.copyToClipboard(context, csv, 'Notes & Debts (CSV)');
                  },
          ),
          const SizedBox(width: 2),
          ExportPillButton(
            icon: Icons.share_rounded,
            label: 'Share',
            isLoading: loadingAction == 'notes_share',
            onPressed: loadingAction != null
                ? null
                : () async {
                    onLoading('notes_share');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    final csv = DataExportGenerator.generateNotesCsv(nc);
                    if (context.mounted) {
                      await ExportFileSharer.shareFile(
                        context,
                        content: csv,
                        fileName: 'notes_debts_$todayStr.csv',
                        mimeType: 'text/csv',
                        subject: 'Personal Expense Notes & Debts ($todayStr)',
                      );
                    }
                    onLoading(null);
                  },
          ),
        ],
      ),
    );
  }

  static Widget buildNotesExcelCard({
    required BuildContext context,
    required NotesController nc,
    required String todayStr,
    required AppPalette p,
    required String? loadingAction,
    required ValueChanged<String?> onLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Icon(Icons.table_view_rounded, size: 24, color: p.acc),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notes & Debts (Excel .xlsx)'.tr,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
                ),
                const SizedBox(height: 1),
                Text(
                  'Excel format with formatting & headers'.tr,
                  style: TextStyle(fontSize: 11.5, color: p.mute),
                ),
              ],
            ),
          ),
          ExportPillButton(
            icon: Icons.share_rounded,
            label: 'Share Excel',
            color: p.acc,
            isLoading: loadingAction == 'excel_notes',
            onPressed: loadingAction != null
                ? null
                : () async {
                    onLoading('excel_notes');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    final rows = <List<CellValue>>[];
                    for (int i = 0; i < nc.notes.length; i++) {
                      final n = nc.notes[i];
                      rows.add([
                        IntCellValue(i + 1),
                        TextCellValue(DataExportGenerator.formatIsoDate(n.date)),
                        TextCellValue(DataExportGenerator.formatAsciiTime(n.date)),
                        TextCellValue(n.title),
                        TextCellValue(n.personName),
                        DoubleCellValue(n.amount),
                        TextCellValue(n.notes),
                      ]);
                    }
                    final bytes = DataExportGenerator.generateSingleTabExcel(
                      sheetName: 'Notes & Debts',
                      headers: [
                        TextCellValue('SL'),
                        TextCellValue('Date'),
                        TextCellValue('Time'),
                        TextCellValue('Title'),
                        TextCellValue('Person'),
                        TextCellValue('Amount (Tk)'),
                        TextCellValue('Note'),
                      ],
                      rows: rows,
                    );
                    if (bytes != null && context.mounted) {
                      await ExportFileSharer.shareBytesFile(
                        context,
                        bytes: bytes,
                        fileName: 'notes_debts_$todayStr.xlsx',
                        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                        subject: 'Personal Expense Notes & Debts ($todayStr)',
                      );
                    }
                    onLoading(null);
                  },
          ),
        ],
      ),
    );
  }

  static Widget buildZikirCsvCard({
    required BuildContext context,
    required PrayerTasbihController? ptc,
    required String todayStr,
    required AppPalette p,
    required String? loadingAction,
    required ValueChanged<String?> onLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint_rounded, size: 24, color: Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zikir & Tasbih (CSV)'.tr,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
                ),
                const SizedBox(height: 1),
                Text(
                  'Date, Zikir Name, Arabic, Category, Count'.tr,
                  style: TextStyle(fontSize: 11.5, color: p.mute),
                ),
              ],
            ),
          ),
          ExportIconAction(
            icon: Icons.visibility_outlined,
            tooltip: 'Preview',
            color: p.mute,
            onPressed: loadingAction != null
                ? null
                : () {
                    final csv = DataExportGenerator.generateZikirCsv(ptc);
                    ExportDialogs.showDataPreviewDialog(context, csv, 'Zikir & Tasbih (CSV)');
                  },
          ),
          ExportIconAction(
            icon: Icons.copy_rounded,
            tooltip: 'Copy',
            color: p.mute,
            onPressed: loadingAction != null
                ? null
                : () {
                    final csv = DataExportGenerator.generateZikirCsv(ptc);
                    ExportFileSharer.copyToClipboard(context, csv, 'Zikir & Tasbih (CSV)');
                  },
          ),
          const SizedBox(width: 2),
          ExportPillButton(
            icon: Icons.share_rounded,
            label: 'Share',
            isLoading: loadingAction == 'zikir_share',
            onPressed: loadingAction != null
                ? null
                : () async {
                    onLoading('zikir_share');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    final csv = DataExportGenerator.generateZikirCsv(ptc);
                    if (context.mounted) {
                      await ExportFileSharer.shareFile(
                        context,
                        content: csv,
                        fileName: 'zikir_tasbih_$todayStr.csv',
                        mimeType: 'text/csv',
                        subject: 'Personal Expense Zikir & Tasbih ($todayStr)',
                      );
                    }
                    onLoading(null);
                  },
          ),
        ],
      ),
    );
  }

  static Widget buildZikirExcelCard({
    required BuildContext context,
    required PrayerTasbihController? ptc,
    required String todayStr,
    required AppPalette p,
    required String? loadingAction,
    required ValueChanged<String?> onLoading,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_view_rounded, size: 24, color: Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zikir & Tasbih (Excel .xlsx)'.tr,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.ink),
                ),
                const SizedBox(height: 1),
                Text(
                  'Excel format with formatting & headers'.tr,
                  style: TextStyle(fontSize: 11.5, color: p.mute),
                ),
              ],
            ),
          ),
          ExportPillButton(
            icon: Icons.share_rounded,
            label: 'Share Excel',
            color: const Color(0xFF10B981),
            isLoading: loadingAction == 'excel_zikir',
            onPressed: loadingAction != null
                ? null
                : () async {
                    onLoading('excel_zikir');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    final rows = <List<CellValue>>[];
                    if (ptc != null && ptc.historyEntries.isNotEmpty) {
                      for (final e in ptc.historyEntries) {
                        rows.add([
                          TextCellValue(e.date),
                          TextCellValue(e.jikirName),
                          TextCellValue(e.arabic),
                          TextCellValue(e.category),
                          IntCellValue(e.jikirCount),
                        ]);
                      }
                    } else if (ptc != null) {
                      for (final z in ptc.allZikirs) {
                        final count = ptc.zikirLifetimeCounts[z.id] ?? 0;
                        if (count > 0) {
                          rows.add([
                            TextCellValue(todayStr),
                            TextCellValue(z.titleBn),
                            TextCellValue(z.arabic),
                            TextCellValue(z.category.name),
                            IntCellValue(count),
                          ]);
                        }
                      }
                    }
                    final bytes = DataExportGenerator.generateSingleTabExcel(
                      sheetName: 'Zikir & Tasbih',
                      headers: [
                        TextCellValue('Date'),
                        TextCellValue('Zikir Name (Bangla)'),
                        TextCellValue('Arabic Text'),
                        TextCellValue('Category'),
                        TextCellValue('Count'),
                      ],
                      rows: rows,
                    );
                    if (bytes != null && context.mounted) {
                      await ExportFileSharer.shareBytesFile(
                        context,
                        bytes: bytes,
                        fileName: 'zikir_tasbih_$todayStr.xlsx',
                        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                        subject: 'Personal Expense Zikir & Tasbih ($todayStr)',
                      );
                    }
                    onLoading(null);
                  },
          ),
        ],
      ),
    );
  }

  static Widget buildFullBackupCard({
    required BuildContext context,
    required TransactionsController tc,
    required NotesController nc,
    required SettingsController sc,
    required PrayerTasbihController? ptc,
    required int txCount,
    required int notesCount,
    required int tasbihCount,
    required String todayStr,
    required AppPalette p,
    required String? loadingAction,
    required ValueChanged<String?> onLoading,
  }) {
    final isBackingUp = loadingAction == 'backup';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.income.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: p.income.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: p.income.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cloud_sync_rounded, size: 24, color: p.income),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Full Data Backup (JSON)'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: p.income,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Complete backup of all transactions, notes, settings'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: p.mute),
                    ),
                  ],
                ),
              ),
              ExportIconAction(
                icon: Icons.visibility_outlined,
                tooltip: 'Preview',
                color: p.mute,
                onPressed: loadingAction != null
                    ? null
                    : () {
                        final jsonStr = DataExportGenerator.generateFullJsonBackup(tc, nc, sc, ptc);
                        ExportDialogs.showDataPreviewDialog(context, jsonStr, 'Full Data Backup (JSON)');
                      },
              ),
              ExportIconAction(
                icon: Icons.share_rounded,
                tooltip: 'Share Backup',
                color: p.income,
                isLoading: loadingAction == 'backup_share',
                onPressed: loadingAction != null
                    ? null
                    : () async {
                        onLoading('backup_share');
                        BuildContext? dlgCtx;
                        ExportDialogs.showLoadingProgressDialog(
                          context,
                          p,
                          title: 'Generating Backup...',
                          subtitle: 'Packing transactions, notes & tasbih records...',
                          status: 'Sharing backup file...',
                          onCreated: (ctx) => dlgCtx = ctx,
                        );
                        await Future<void>.delayed(const Duration(milliseconds: 600));
                        if (dlgCtx != null && dlgCtx!.mounted) {
                          Navigator.of(dlgCtx!).pop();
                        }
                        final jsonStr = DataExportGenerator.generateFullJsonBackup(tc, nc, sc, ptc);
                        if (context.mounted) {
                          await ExportFileSharer.shareFile(
                            context,
                            content: jsonStr,
                            fileName: 'personal_expense_backup_$todayStr.json',
                            mimeType: 'application/json',
                            subject: 'Personal Expense Full Backup ($todayStr)',
                          );
                        }
                        onLoading(null);
                      },
              ),
              const SizedBox(width: 2),
              ExportPillButton(
                icon: Icons.cloud_upload_rounded,
                label: 'Backup',
                color: p.income,
                isLoading: isBackingUp,
                onPressed: loadingAction != null
                    ? null
                    : () async {
                        onLoading('backup');
                        BuildContext? dlgCtx;
                        ExportDialogs.showLoadingProgressDialog(
                          context,
                          p,
                          title: 'Generating Backup...',
                          subtitle: 'Packing transactions, notes & tasbih records...',
                          status: 'Preparing JSON backup file...',
                          onCreated: (ctx) => dlgCtx = ctx,
                        );
                        await Future<void>.delayed(const Duration(milliseconds: 700));
                        if (dlgCtx != null && dlgCtx!.mounted) {
                          Navigator.of(dlgCtx!).pop();
                        }
                        final jsonStr = DataExportGenerator.generateFullJsonBackup(tc, nc, sc, ptc);
                        onLoading(null);
                        if (context.mounted) {
                          ExportDialogs.showBackupSuccessSheet(
                            context,
                            jsonStr,
                            txCount,
                            notesCount,
                            tasbihCount,
                            onShareBackup: (sheetCtx, content) async {
                              await ExportFileSharer.shareFile(
                                sheetCtx,
                                content: content,
                                fileName: 'personal_expense_backup_$todayStr.json',
                                mimeType: 'application/json',
                                subject: 'Personal Expense Full Backup ($todayStr)',
                              );
                            },
                            onDismissAll: () => Navigator.of(context).pop(),
                          );
                        }
                      },
              ),
            ],
          ),
          if (isBackingUp) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: p.income.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(p.income),
                minHeight: 3.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(p.income),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Generating backup, please wait...'.tr,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: p.income,
                    ),
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
