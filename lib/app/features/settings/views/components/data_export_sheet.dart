import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:personal_expense/app/core/theme/app_theme.dart';
import 'package:personal_expense/app/core/theme/app_widgets.dart';
import 'package:personal_expense/app/features/notes/controllers/notes_controller.dart';
import 'package:personal_expense/app/features/prayer_tasbih/controllers/prayer_tasbih_controller.dart';
import 'package:personal_expense/app/features/transactions/controllers/transactions_controller.dart';
import 'package:personal_expense/app/features/settings/controllers/settings_controller.dart';
import 'export/data_export_generator.dart';
import 'export/export_action_cards.dart';

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

class DataExportSheet extends StatefulWidget {
  const DataExportSheet({super.key});

  @visibleForTesting
  static String formatIsoDate(DateTime d) => DataExportGenerator.formatIsoDate(d);

  @visibleForTesting
  static String formatAsciiTime(DateTime d) => DataExportGenerator.formatAsciiTime(d);

  @visibleForTesting
  static String cleanCsvField(String field) => DataExportGenerator.cleanCsvField(field);

  @visibleForTesting
  static String generateTransactionsCsv(TransactionsController tc) =>
      DataExportGenerator.generateTransactionsCsv(tc);

  @visibleForTesting
  static String generateNotesCsv(NotesController nc) =>
      DataExportGenerator.generateNotesCsv(nc);

  @visibleForTesting
  static String generateZikirCsv(PrayerTasbihController? ptc) =>
      DataExportGenerator.generateZikirCsv(ptc);

  @visibleForTesting
  static List<int>? fixExcelFonts(List<int>? bytes) =>
      DataExportGenerator.fixExcelFonts(bytes);

  @visibleForTesting
  static List<int>? generateMultiTabExcel(
    TransactionsController tc,
    NotesController? nc,
    PrayerTasbihController? ptc,
  ) =>
      DataExportGenerator.generateMultiTabExcel(tc, nc, ptc);

  @visibleForTesting
  static List<int>? generateSingleTabExcel({
    required String sheetName,
    required List<CellValue> headers,
    required List<List<CellValue>> rows,
  }) =>
      DataExportGenerator.generateSingleTabExcel(
        sheetName: sheetName,
        headers: headers,
        rows: rows,
      );

  @override
  State<DataExportSheet> createState() => _DataExportSheetState();
}

class _DataExportSheetState extends State<DataExportSheet> {
  String? _loadingAction;
  int _selectedTab = 0; // 0: All in One, 1: Transactions, 2: Notes & Debts, 3: Zikir Logs

  @override
  void initState() {
    super.initState();
    // Ensure NotesController is registered & refreshed with latest notes
    final nc = Get.isRegistered<NotesController>()
        ? Get.find<NotesController>()
        : Get.put(NotesController(), permanent: true);
    nc.addListener(_onControllerUpdate);
    nc.refreshNotes();

    final ptc = Get.isRegistered<PrayerTasbihController>()
        ? Get.find<PrayerTasbihController>()
        : Get.put(PrayerTasbihController(), permanent: true);
    ptc.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<NotesController>()) {
      Get.find<NotesController>().removeListener(_onControllerUpdate);
    }
    if (Get.isRegistered<PrayerTasbihController>()) {
      Get.find<PrayerTasbihController>().removeListener(_onControllerUpdate);
    }
    super.dispose();
  }

  Widget _buildTabChip(int index, String label, IconData icon, AppPalette p) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? p.income : p.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? p.income : p.line,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : p.mute,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : p.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tc = Get.find<TransactionsController>();
    final nc = Get.isRegistered<NotesController>()
        ? Get.find<NotesController>()
        : Get.put(NotesController(), permanent: true);
    final sc = Get.find<SettingsController>();
    final ptc = Get.isRegistered<PrayerTasbihController>()
        ? Get.find<PrayerTasbihController>()
        : (Get.put(PrayerTasbihController(), permanent: true));

    final txCount = tc.entries.length;
    final notesCount = nc.notes.length;
    final tasbihCount = ptc.historyEntries.isNotEmpty
        ? ptc.historyEntries.length
        : ptc.zikirLifetimeCounts.values.where((c) => c > 0).length;

    final todayStr = DataExportGenerator.formatIsoDate(DateTime.now());
    final maxHeight = MediaQuery.sizeOf(context).height * 0.90;

    return Container(
      constraints: BoxConstraints(maxWidth: 580, maxHeight: maxHeight),
      margin: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. FROZEN PRIMARY COLOR HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 14, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.income, p.income.withOpacity(0.92)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Data'.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Export tab-wise or all together'.tr,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: Colors.white),
                      tooltip: 'Close'.tr,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. FROZEN CONTROLS: SUMMARY COUNTS & TAB SWITCHER
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: p.card,
              border: Border(bottom: BorderSide(color: p.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3-Card Counts summary: Transactions, Notes, Zikir
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.mute),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$txCount',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.income),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.acc),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$notesCount',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: p.acc),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: p.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Zikir Logs'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.mute),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$tasbihCount',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 4-Tab row
                Row(
                  children: [
                    Expanded(child: _buildTabChip(0, 'All in One'.tr, Icons.layers_rounded, p)),
                    const SizedBox(width: 5),
                    Expanded(child: _buildTabChip(1, 'Transactions'.tr, Icons.table_chart_rounded, p)),
                    const SizedBox(width: 5),
                    Expanded(child: _buildTabChip(2, 'Notes'.tr, Icons.note_alt_rounded, p)),
                    const SizedBox(width: 5),
                    Expanded(child: _buildTabChip(3, 'Zikir'.tr, Icons.fingerprint_rounded, p)),
                  ],
                ),
              ],
            ),
          ),

          // 3. SCROLLABLE BODY CONTENT
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live Loader Banner when generating or sharing
                  if (_loadingAction != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.income.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: p.income,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _loadingAction == 'backup'
                                      ? 'Generating backup, please wait...'.tr
                                      : _loadingAction?.startsWith('excel') == true
                                          ? 'Generating Excel file...'.tr
                                          : 'Sharing backup file...'.tr,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.income,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _loadingAction == 'excel_all'
                                      ? 'Packing 3 tabs into Excel (.xlsx)...'.tr
                                      : 'Packing transactions, notes & tasbih records...'.tr,
                                  style: TextStyle(fontSize: 11.5, color: p.mute),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Content by Selected Tab
                  if (_selectedTab == 0) ...[
                    // Option 0: Multi-Tab Excel Workbook (.xlsx)
                    ExportActionCards.buildMultiTabExcelCard(
                      context: context,
                      tc: tc,
                      nc: nc,
                      ptc: ptc,
                      txCount: txCount,
                      notesCount: notesCount,
                      tasbihCount: tasbihCount,
                      todayStr: todayStr,
                      p: p,
                      loadingAction: _loadingAction,
                      onLoading: (val) => setState(() => _loadingAction = val),
                    ),
                    const SizedBox(height: 10),

                    // Option 1: Transactions CSV
                    ExportActionCards.buildTransactionsCsvCard(
                      context: context,
                      tc: tc,
                      todayStr: todayStr,
                      p: p,
                      loadingAction: _loadingAction,
                      onLoading: (val) => setState(() => _loadingAction = val),
                    ),
                    const SizedBox(height: 10),

                    // Option 2: Notes & Debts CSV
                    ExportActionCards.buildNotesCsvCard(
                      context: context,
                      nc: nc,
                      todayStr: todayStr,
                      p: p,
                      loadingAction: _loadingAction,
                      onLoading: (val) => setState(() => _loadingAction = val),
                    ),
                    const SizedBox(height: 10),

                    // Option 3: Zikir & Tasbih CSV
                    ExportActionCards.buildZikirCsvCard(
                      context: context,
                      ptc: ptc,
                      todayStr: todayStr,
                      p: p,
                      loadingAction: _loadingAction,
                      onLoading: (val) => setState(() => _loadingAction = val),
                    ),
                    const SizedBox(height: 10),

                    // Option 4: Full JSON Backup
                    ExportActionCards.buildFullBackupCard(
                      context: context,
                      tc: tc,
                      nc: nc,
                      sc: sc,
                      ptc: ptc,
                      txCount: txCount,
                      notesCount: notesCount,
                      tasbihCount: tasbihCount,
                      todayStr: todayStr,
                      p: p,
                      loadingAction: _loadingAction,
                      onLoading: (val) => setState(() => _loadingAction = val),
                    ),
                  ] else if (_selectedTab == 1) ...[
                    // Tab 1: Transactions
                    ExportActionCards.buildTransactionsExcelCard(
                      context: context,
                      tc: tc,
                      todayStr: todayStr,
                      p: p,
                      loadingAction: _loadingAction,
                      onLoading: (val) => setState(() => _loadingAction = val),
                    ),
                    const SizedBox(height: 10),
                    ExportActionCards.buildTransactionsCsvCard(
                      context: context,
                      tc: tc,
                      todayStr: todayStr,
                      p: p,
                      loadingAction: _loadingAction,
                      onLoading: (val) => setState(() => _loadingAction = val),
                    ),
                  ] else if (_selectedTab == 2) ...[
                    // Tab 2: Notes & Debts
                    ExportActionCards.buildNotesExcelCard(
                      context: context,
                      nc: nc,
                      todayStr: todayStr,
                      p: p,
                      loadingAction: _loadingAction,
                      onLoading: (val) => setState(() => _loadingAction = val),
                    ),
                    const SizedBox(height: 10),
                    ExportActionCards.buildNotesCsvCard(
                      context: context,
                      nc: nc,
                      todayStr: todayStr,
                      p: p,
                      loadingAction: _loadingAction,
                      onLoading: (val) => setState(() => _loadingAction = val),
                    ),
                  ] else if (_selectedTab == 3) ...[
                    // Tab 3: Zikir Logs
                    ExportActionCards.buildZikirExcelCard(
                      context: context,
                      ptc: ptc,
                      todayStr: todayStr,
                      p: p,
                      loadingAction: _loadingAction,
                      onLoading: (val) => setState(() => _loadingAction = val),
                    ),
                    const SizedBox(height: 10),
                    ExportActionCards.buildZikirCsvCard(
                      context: context,
                      ptc: ptc,
                      todayStr: todayStr,
                      p: p,
                      loadingAction: _loadingAction,
                      onLoading: (val) => setState(() => _loadingAction = val),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Close button
                  AppButton(
                    'Close',
                    icon: Icons.close_rounded,
                    style: AppButtonStyle.outlined,
                    height: 46,
                    fontSize: 14.5,
                    margin: EdgeInsets.zero,
                    onPressed: _loadingAction != null ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
