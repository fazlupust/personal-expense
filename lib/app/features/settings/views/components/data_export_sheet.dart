import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../core/utils/formatters.dart';
import '../../../notes/controllers/notes_controller.dart';
import '../../../prayer_tasbih/controllers/prayer_tasbih_controller.dart';
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

class DataExportSheet extends StatefulWidget {
  const DataExportSheet({super.key});

  @visibleForTesting
  static String formatIsoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @visibleForTesting
  static String formatAsciiTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  @visibleForTesting
  static String cleanCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  @visibleForTesting
  static String generateTransactionsCsv(TransactionsController tc) {
    final buffer = StringBuffer();
    // Excel-compatible UTF-8 BOM so Excel opens CSV with proper Unicode/Bengali font support
    buffer.write('\uFEFF');
    // CSV Header
    buffer.writeln('ID,Date,Time,Type,Category,Amount,Account,Note');
    for (final e in tc.entries) {
      final dateStr = formatIsoDate(e.date);
      final timeStr = formatAsciiTime(e.date);
      final typeStr = e.type.name;
      final categoryStr = cleanCsvField(e.category);
      final amountStr = e.amount.toStringAsFixed(2);
      final accountStr = cleanCsvField(e.account);
      final noteStr = cleanCsvField(e.note);
      buffer.writeln('${e.id},$dateStr,$timeStr,$typeStr,$categoryStr,$amountStr,$accountStr,$noteStr');
    }
    return buffer.toString();
  }

  @visibleForTesting
  static String generateNotesCsv(NotesController nc) {
    final buffer = StringBuffer();
    // Excel-compatible UTF-8 BOM
    buffer.write('\uFEFF');
    // CSV Header
    buffer.writeln('SL,Date,Time,Title,Person,Amount,Note');
    for (int i = 0; i < nc.notes.length; i++) {
      final n = nc.notes[i];
      final sl = i + 1;
      final dateStr = formatIsoDate(n.date);
      final timeStr = formatAsciiTime(n.date);
      final titleStr = cleanCsvField(n.title);
      final personStr = cleanCsvField(n.personName);
      final amountStr = n.amount.toStringAsFixed(2);
      final noteStr = cleanCsvField(n.notes);
      buffer.writeln('$sl,$dateStr,$timeStr,$titleStr,$personStr,$amountStr,$noteStr');
    }
    return buffer.toString();
  }

  @visibleForTesting
  static String generateZikirCsv(PrayerTasbihController? ptc) {
    final buffer = StringBuffer();
    // Excel-compatible UTF-8 BOM
    buffer.write('\uFEFF');
    // CSV Header
    buffer.writeln('Date,Zikir Name,Arabic,Category,Count');
    if (ptc != null) {
      final entries = ptc.historyEntries;
      if (entries.isNotEmpty) {
        for (final e in entries) {
          final dateStr = e.date;
          final nameStr = cleanCsvField(e.jikirName);
          final arabicStr = cleanCsvField(e.arabic);
          final categoryStr = cleanCsvField(e.category);
          final countStr = e.jikirCount.toString();
          buffer.writeln('$dateStr,$nameStr,$arabicStr,$categoryStr,$countStr');
        }
      } else {
        // Fallback to lifetime totals
        for (final z in ptc.allZikirs) {
          final count = ptc.zikirLifetimeCounts[z.id] ?? 0;
          if (count > 0) {
            final dateStr = formatIsoDate(DateTime.now());
            final nameStr = cleanCsvField(z.titleBn);
            final arabicStr = cleanCsvField(z.arabic);
            final categoryStr = cleanCsvField(z.category.name);
            buffer.writeln('$dateStr,$nameStr,$arabicStr,$categoryStr,$count');
          }
        }
      }
    }
    return buffer.toString();
  }

  @visibleForTesting
  static List<int>? fixExcelFonts(List<int>? bytes) {
    if (bytes == null) return null;
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final newArchive = Archive();
      const unicodeFont =
          '<font><sz val="11.0"/><color rgb="FF000000"/><name val="Calibri"/><family val="2"/><charset val="1"/></font>';
      final fontsRegex = RegExp(r'<fonts[^>]*>.*?</fonts>');

      for (final file in archive) {
        if (file.name == 'xl/styles.xml') {
          var xml = utf8.decode(file.content as List<int>);
          // 1. Replace entire <fonts> block so neither font 0 nor font 1 has an empty <font/> or Arial tag
          xml = xml.replaceAll(
              fontsRegex, '<fonts count="2">$unicodeFont$unicodeFont</fonts>');
          // 2. Ensure all cellXfs point to valid Unicode font and apply font styling
          xml = xml.replaceAll('fontId="1"', 'fontId="0" applyFont="1"');
          // 3. Fallback replace any lingering Arial
          xml = xml.replaceAll('name val="Arial"', 'name val="Calibri"');
          final encoded = utf8.encode(xml);
          newArchive.addFile(ArchiveFile(file.name, encoded.length, encoded));
        } else {
          newArchive.addFile(file);
        }
      }
      return ZipEncoder().encode(newArchive);
    } catch (_) {
      return bytes;
    }
  }

  @visibleForTesting
  static List<int>? generateMultiTabExcel(
    TransactionsController tc,
    NotesController? nc,
    PrayerTasbihController? ptc,
  ) {
    final excel = Excel.createExcel();

    // 1. Transactions Sheet
    final txSheet = excel['Transactions'];
    txSheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Amount (Tk)'),
      TextCellValue('Account'),
      TextCellValue('Note'),
    ]);
    for (final e in tc.entries) {
      txSheet.appendRow([
        TextCellValue(e.id),
        TextCellValue(formatIsoDate(e.date)),
        TextCellValue(formatAsciiTime(e.date)),
        TextCellValue(e.type.name.toUpperCase()),
        TextCellValue(e.category),
        DoubleCellValue(e.amount),
        TextCellValue(e.account),
        TextCellValue(e.note),
      ]);
    }

    // 2. Notes & Debts Sheet
    final notesSheet = excel['Notes & Debts'];
    notesSheet.appendRow([
      TextCellValue('SL'),
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Title'),
      TextCellValue('Person'),
      TextCellValue('Amount (Tk)'),
      TextCellValue('Note'),
    ]);
    final notesList = nc?.notes ?? [];
    for (int i = 0; i < notesList.length; i++) {
      final n = notesList[i];
      notesSheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(formatIsoDate(n.date)),
        TextCellValue(formatAsciiTime(n.date)),
        TextCellValue(n.title),
        TextCellValue(n.personName),
        DoubleCellValue(n.amount),
        TextCellValue(n.notes),
      ]);
    }

    // 3. Zikir & Tasbih Sheet
    final zikirSheet = excel['Zikir & Tasbih'];
    zikirSheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Zikir Name (Bangla)'),
      TextCellValue('Arabic Text'),
      TextCellValue('Category'),
      TextCellValue('Count'),
    ]);
    if (ptc != null) {
      final entries = ptc.historyEntries;
      if (entries.isNotEmpty) {
        for (final e in entries) {
          zikirSheet.appendRow([
            TextCellValue(e.date),
            TextCellValue(e.jikirName),
            TextCellValue(e.arabic),
            TextCellValue(e.category),
            IntCellValue(e.jikirCount),
          ]);
        }
      } else {
        final nowStr = formatIsoDate(DateTime.now());
        for (final z in ptc.allZikirs) {
          final count = ptc.zikirLifetimeCounts[z.id] ?? 0;
          if (count > 0) {
            zikirSheet.appendRow([
              TextCellValue(nowStr),
              TextCellValue(z.titleBn),
              TextCellValue(z.arabic),
              TextCellValue(z.category.name),
              IntCellValue(count),
            ]);
          }
        }
      }
    }

    excel.delete('Sheet1');
    return fixExcelFonts(excel.save());
  }

  @visibleForTesting
  static List<int>? generateSingleTabExcel({
    required String sheetName,
    required List<CellValue> headers,
    required List<List<CellValue>> rows,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];
    sheet.appendRow(headers);
    for (final row in rows) {
      sheet.appendRow(row);
    }
    excel.delete('Sheet1');
    return fixExcelFonts(excel.save());
  }

  @override
  State<DataExportSheet> createState() => _DataExportSheetState();
}

class _DataExportSheetState extends State<DataExportSheet> {
  String? _loadingAction;
  int _selectedTab = 0; // 0: All in One, 1: Transactions, 2: Notes & Debts, 3: Zikir Logs
  BuildContext? _loadingDialogContext;

  String _generateTransactionsCsv(TransactionsController tc) => DataExportSheet.generateTransactionsCsv(tc);

  String _generateNotesCsv(NotesController nc) => DataExportSheet.generateNotesCsv(nc);

  String _generateZikirCsv(PrayerTasbihController? ptc) => DataExportSheet.generateZikirCsv(ptc);

  String _generateFullJsonBackup(
    TransactionsController tc,
    NotesController nc,
    SettingsController sc,
    PrayerTasbihController? ptc,
  ) {
    final map = {
      'exported_at': DateTime.now().toIso8601String(),
      'app': AppConstants.appName,
      'settings': {
        'language': sc.langCode,
        'monthly_budget': sc.budget,
        'category_budgets': sc.categoryBudgets,
        'default_account': sc.defaultAccount,
        'show_prayer_card': sc.showPrayerCard,
        'show_weather_card': sc.showWeatherCard,
      },
      'transactions': tc.entries.map((e) => e.toMap()).toList(),
      'notes': nc.notes.map((n) => n.toMap()).toList(),
      'tasbih': {
        'lifetime_total': ptc?.lifetimeTotal ?? 0,
        'today_total': ptc?.todayTotal ?? 0,
        'lifetime_counts': ptc?.zikirLifetimeCounts ?? {},
        'history': (ptc?.historyEntries ?? []).map((e) => {
              'date': e.date,
              'jikir_id': e.jikirId,
              'jikir_name': e.jikirName,
              'jikir_name_en': e.jikirNameEn,
              'category': e.category,
              'count': e.jikirCount,
            }).toList(),
      },
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  Future<void> _shareFile(
    BuildContext context, {
    required String content,
    required String fileName,
    required String mimeType,
    required String subject,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType, name: fileName)],
        subject: subject,
        text: subject,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      // Fallback: Share raw text
      try {
        await Share.share(
          content,
          subject: subject,
          sharePositionOrigin: origin,
        );
      } catch (e) {
        // Last resort: Copy to clipboard
        await Clipboard.setData(ClipboardData(text: content));
        Get.snackbar(
          'Copied to Clipboard'.tr,
          'Sharing failed. Content copied to clipboard!'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1F8A5B),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 12,
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String data, String title) {
    Clipboard.setData(ClipboardData(text: data));
    Get.snackbar(
      title.tr,
      'Copied to clipboard! You can paste it into Excel or Google Sheets.'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1F8A5B),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
      duration: const Duration(seconds: 3),
      maxWidth: 420,
      margin: const EdgeInsets.all(14),
      borderRadius: 12,
    );
  }

  List<int>? _generateMultiTabExcel(
    TransactionsController tc,
    NotesController? nc,
    PrayerTasbihController? ptc,
  ) => DataExportSheet.generateMultiTabExcel(tc, nc, ptc);

  List<int>? _generateSingleTabExcel({
    required String sheetName,
    required List<CellValue> headers,
    required List<List<CellValue>> rows,
  }) => DataExportSheet.generateSingleTabExcel(
    sheetName: sheetName,
    headers: headers,
    rows: rows,
  );

  Future<void> _shareBytesFile(
    BuildContext context, {
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    required String subject,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType, name: fileName)],
        subject: subject,
        text: subject,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      Get.snackbar(
        'Export Failed'.tr,
        'Could not share file: $e'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 12,
      );
    }
  }

  void _previewMultiTabWorkbook(
    BuildContext context, {
    required int txCount,
    required int notesCount,
    required int tasbihCount,
    required TransactionsController tc,
    required NotesController? nc,
    required PrayerTasbihController? ptc,
    required String todayStr,
  }) {
    final p = context.pal;
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        'Multi-Tab Excel Workbook (.xlsx)'.tr,
                        style: TextStyle(
                          fontSize: 16,
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.income.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.income.withOpacity(0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.table_view_rounded, size: 22, color: p.income),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Worksheet Tabs'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: p.income,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: p.income.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '3 Tabs',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: p.income,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildPreviewTabItem(
                        icon: Icons.table_chart_rounded,
                        tabName: 'Tab 1: Transactions'.tr,
                        count: '$txCount records'.tr,
                        columns: 'ID, Date, Time, Type, Category, Amount, Account, Note',
                        p: p,
                      ),
                      const Divider(height: 20),
                      _buildPreviewTabItem(
                        icon: Icons.note_alt_rounded,
                        tabName: 'Tab 2: Notes & Debts'.tr,
                        count: '$notesCount records'.tr,
                        columns: 'SL, Date, Time, Title, Person, Amount, Note',
                        p: p,
                      ),
                      const Divider(height: 20),
                      _buildPreviewTabItem(
                        icon: Icons.fingerprint_rounded,
                        tabName: 'Tab 3: Zikir & Tasbih'.tr,
                        count: '$tasbihCount records'.tr,
                        columns: 'Date, Zikir Name, Arabic, Category, Count',
                        p: p,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        'Back',
                        icon: Icons.arrow_back_rounded,
                        style: AppButtonStyle.outlined,
                        height: 44,
                        fontSize: 13.5,
                        margin: EdgeInsets.zero,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        'Share Excel',
                        icon: Icons.share_rounded,
                        height: 44,
                        fontSize: 13.5,
                        margin: EdgeInsets.zero,
                        onPressed: () async {
                          Navigator.of(sheetContext).pop();
                          setState(() => _loadingAction = 'excel_all');
                          await Future<void>.delayed(const Duration(milliseconds: 300));
                          if (!mounted) return;
                          final bytes = _generateMultiTabExcel(tc, nc, ptc);
                          if (bytes != null && mounted) {
                            await _shareBytesFile(
                              this.context,
                              bytes: bytes,
                              fileName: 'personal_expense_all_$todayStr.xlsx',
                              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                              subject: 'Personal Expense All Data Workbook ($todayStr)',
                            );
                          }
                          if (mounted) {
                            setState(() => _loadingAction = null);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewTabItem({
    required IconData icon,
    required String tabName,
    required String count,
    required String columns,
    required AppPalette p,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: p.ink),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tabName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: p.mute,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                columns,
                style: TextStyle(
                  fontSize: 11,
                  color: p.mute,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLoadingProgressDialog(
    BuildContext context,
    AppPalette p, {
    required String title,
    required String subtitle,
    required String status,
    IconData statusIcon = Icons.cloud_sync_rounded,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogCtx) {
        _loadingDialogContext = dialogCtx;
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: p.income.withOpacity(0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.income.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation<Color>(p.income),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title.tr,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: p.mute,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: p.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.line),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(statusIcon, size: 16, color: p.income),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            status.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: p.income,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _dismissLoadingDialog() {
    if (_loadingDialogContext != null && _loadingDialogContext!.mounted) {
      Navigator.of(_loadingDialogContext!).pop();
      _loadingDialogContext = null;
    }
  }

  void _showBackupSuccessSheet(
    BuildContext context,
    String jsonStr,
    int txCount,
    int notesCount,
    int tasbihCount,
  ) {
    final p = context.pal;
    final dateStr = Fmt.date(DateTime.now(), 'yyyy-MM-dd, hh:mm a');
    final todayFileStr = DataExportSheet.formatIsoDate(DateTime.now());

    // Auto-copy as convenience
    Clipboard.setData(ClipboardData(text: jsonStr));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 580),
      builder: (sheetContext) {
        bool isSharing = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
              child: SingleChildScrollView(
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

              // Header bar
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
                            'All transactions, notes, zikir logs & settings are packed in JSON format.'.tr,
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
                                '📿 $tasbihCount ${'logs'.tr}',
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

              // Action 1: Native Share Backup File Button
              AppButton(
                'Share Backup',
                icon: Icons.share_rounded,
                isLoading: isSharing,
                height: 48,
                fontSize: 15,
                margin: const EdgeInsets.only(bottom: 10),
                onPressed: isSharing
                    ? null
                    : () async {
                        setSheetState(() => isSharing = true);
                        await Future<void>.delayed(const Duration(milliseconds: 250));
                        if (!sheetContext.mounted) return;
                        await _shareFile(
                          sheetContext,
                          content: jsonStr,
                          fileName: 'personal_expense_backup_$todayFileStr.json',
                          mimeType: 'application/json',
                          subject: 'Personal Expense Full Backup ($todayFileStr)',
                        );
                        if (sheetContext.mounted) {
                          setSheetState(() => isSharing = false);
                        }
                      },
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
                          backgroundColor: const Color(0xFF1F8A5B),
                          colorText: Colors.white,
                          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
                          duration: const Duration(seconds: 2),
                          maxWidth: 420,
                          margin: const EdgeInsets.all(14),
                          borderRadius: 12,
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

              // Action 3: Navigation buttons
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
        ),
      );
    },
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
                          backgroundColor: const Color(0xFF1F8A5B),
                          colorText: Colors.white,
                          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
                          duration: const Duration(seconds: 2),
                          maxWidth: 400,
                          margin: const EdgeInsets.all(12),
                          borderRadius: 12,
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

  Widget _buildPillButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    bool isLoading = false,
    Color? color,
  }) {
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

  Widget _buildIconAction({
    required VoidCallback? onPressed,
    required IconData icon,
    required String tooltip,
    Color? color,
    bool isLoading = false,
  }) {
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

  Widget _buildMultiTabExcelCard({
    required BuildContext context,
    required TransactionsController tc,
    required NotesController? nc,
    required PrayerTasbihController? ptc,
    required int txCount,
    required int notesCount,
    required int tasbihCount,
    required String todayStr,
    required AppPalette p,
  }) {
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
          _buildIconAction(
            icon: Icons.visibility_outlined,
            tooltip: 'Preview Tabs',
            color: p.mute,
            onPressed: _loadingAction != null
                ? null
                : () => _previewMultiTabWorkbook(
                      context,
                      txCount: txCount,
                      notesCount: notesCount,
                      tasbihCount: tasbihCount,
                      tc: tc,
                      nc: nc,
                      ptc: ptc,
                      todayStr: todayStr,
                    ),
          ),
          const SizedBox(width: 2),
          _buildPillButton(
            icon: Icons.share_rounded,
            label: 'Share Excel',
            color: p.income,
            isLoading: _loadingAction == 'excel_all',
            onPressed: _loadingAction != null
                ? null
                : () async {
                    setState(() => _loadingAction = 'excel_all');
                    _showLoadingProgressDialog(
                      context,
                      p,
                      title: 'Generating Excel file...',
                      subtitle: 'Packing 3 tabs into Excel (.xlsx)...',
                      status: 'Preparing Excel workbook...',
                      statusIcon: Icons.table_view_rounded,
                    );
                    await Future<void>.delayed(const Duration(milliseconds: 600));
                    _dismissLoadingDialog();
                    if (!mounted) return;
                    final bytes = _generateMultiTabExcel(tc, nc, ptc);
                    if (bytes != null && mounted) {
                      await _shareBytesFile(
                        this.context,
                        bytes: bytes,
                        fileName: 'personal_expense_all_$todayStr.xlsx',
                        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                        subject: 'Personal Expense All Data Workbook ($todayStr)',
                      );
                    }
                    if (mounted) {
                      setState(() => _loadingAction = null);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsCsvCard({
    required BuildContext context,
    required TransactionsController tc,
    required String todayStr,
    required AppPalette p,
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
          _buildIconAction(
            icon: Icons.visibility_outlined,
            tooltip: 'Preview',
            color: p.mute,
            onPressed: _loadingAction != null
                ? null
                : () {
                    final csv = _generateTransactionsCsv(tc);
                    _previewData(context, csv, 'Transactions (CSV)');
                  },
          ),
          _buildIconAction(
            icon: Icons.copy_rounded,
            tooltip: 'Copy',
            color: p.mute,
            onPressed: _loadingAction != null
                ? null
                : () {
                    final csv = _generateTransactionsCsv(tc);
                    _copyToClipboard(context, csv, 'Transactions (CSV)');
                  },
          ),
          const SizedBox(width: 2),
          _buildPillButton(
            icon: Icons.share_rounded,
            label: 'Share',
            isLoading: _loadingAction == 'tx_share',
            onPressed: _loadingAction != null
                ? null
                : () async {
                    setState(() => _loadingAction = 'tx_share');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    if (!mounted) return;
                    final csv = _generateTransactionsCsv(tc);
                    await _shareFile(
                      this.context,
                      content: csv,
                      fileName: 'transactions_$todayStr.csv',
                      mimeType: 'text/csv',
                      subject: 'Personal Expense Transactions ($todayStr)',
                    );
                    if (mounted) {
                      setState(() => _loadingAction = null);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsExcelCard({
    required BuildContext context,
    required TransactionsController tc,
    required String todayStr,
    required AppPalette p,
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
          _buildPillButton(
            icon: Icons.share_rounded,
            label: 'Share Excel',
            color: p.income,
            isLoading: _loadingAction == 'excel_tx',
            onPressed: _loadingAction != null
                ? null
                : () async {
                    setState(() => _loadingAction = 'excel_tx');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    if (!mounted) return;
                    final rows = tc.entries
                        .map((e) => <CellValue>[
                              TextCellValue(e.id),
                              TextCellValue(DataExportSheet.formatIsoDate(e.date)),
                              TextCellValue(DataExportSheet.formatAsciiTime(e.date)),
                              TextCellValue(e.type.name.toUpperCase()),
                              TextCellValue(e.category),
                              DoubleCellValue(e.amount),
                              TextCellValue(e.account),
                              TextCellValue(e.note),
                            ])
                        .toList();
                    final bytes = _generateSingleTabExcel(
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
                    if (bytes != null && mounted) {
                      await _shareBytesFile(
                        this.context,
                        bytes: bytes,
                        fileName: 'transactions_$todayStr.xlsx',
                        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                        subject: 'Personal Expense Transactions ($todayStr)',
                      );
                    }
                    if (mounted) {
                      setState(() => _loadingAction = null);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCsvCard({
    required BuildContext context,
    required NotesController nc,
    required String todayStr,
    required AppPalette p,
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
          _buildIconAction(
            icon: Icons.visibility_outlined,
            tooltip: 'Preview',
            color: p.mute,
            onPressed: _loadingAction != null
                ? null
                : () {
                    final csv = _generateNotesCsv(nc);
                    _previewData(context, csv, 'Notes & Debts (CSV)');
                  },
          ),
          _buildIconAction(
            icon: Icons.copy_rounded,
            tooltip: 'Copy',
            color: p.mute,
            onPressed: _loadingAction != null
                ? null
                : () {
                    final csv = _generateNotesCsv(nc);
                    _copyToClipboard(context, csv, 'Notes & Debts (CSV)');
                  },
          ),
          const SizedBox(width: 2),
          _buildPillButton(
            icon: Icons.share_rounded,
            label: 'Share',
            isLoading: _loadingAction == 'notes_share',
            onPressed: _loadingAction != null
                ? null
                : () async {
                    setState(() => _loadingAction = 'notes_share');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    if (!mounted) return;
                    final csv = _generateNotesCsv(nc);
                    await _shareFile(
                      this.context,
                      content: csv,
                      fileName: 'notes_debts_$todayStr.csv',
                      mimeType: 'text/csv',
                      subject: 'Personal Expense Notes & Debts ($todayStr)',
                    );
                    if (mounted) {
                      setState(() => _loadingAction = null);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesExcelCard({
    required BuildContext context,
    required NotesController nc,
    required String todayStr,
    required AppPalette p,
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
          _buildPillButton(
            icon: Icons.share_rounded,
            label: 'Share Excel',
            color: p.acc,
            isLoading: _loadingAction == 'excel_notes',
            onPressed: _loadingAction != null
                ? null
                : () async {
                    setState(() => _loadingAction = 'excel_notes');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    if (!mounted) return;
                    final rows = <List<CellValue>>[];
                    for (int i = 0; i < nc.notes.length; i++) {
                      final n = nc.notes[i];
                      rows.add([
                        IntCellValue(i + 1),
                        TextCellValue(DataExportSheet.formatIsoDate(n.date)),
                        TextCellValue(DataExportSheet.formatAsciiTime(n.date)),
                        TextCellValue(n.title),
                        TextCellValue(n.personName),
                        DoubleCellValue(n.amount),
                        TextCellValue(n.notes),
                      ]);
                    }
                    final bytes = _generateSingleTabExcel(
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
                    if (bytes != null && mounted) {
                      await _shareBytesFile(
                        this.context,
                        bytes: bytes,
                        fileName: 'notes_debts_$todayStr.xlsx',
                        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                        subject: 'Personal Expense Notes & Debts ($todayStr)',
                      );
                    }
                    if (mounted) {
                      setState(() => _loadingAction = null);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildZikirCsvCard({
    required BuildContext context,
    required PrayerTasbihController? ptc,
    required String todayStr,
    required AppPalette p,
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
          _buildIconAction(
            icon: Icons.visibility_outlined,
            tooltip: 'Preview',
            color: p.mute,
            onPressed: _loadingAction != null
                ? null
                : () {
                    final csv = _generateZikirCsv(ptc);
                    _previewData(context, csv, 'Zikir & Tasbih (CSV)');
                  },
          ),
          _buildIconAction(
            icon: Icons.copy_rounded,
            tooltip: 'Copy',
            color: p.mute,
            onPressed: _loadingAction != null
                ? null
                : () {
                    final csv = _generateZikirCsv(ptc);
                    _copyToClipboard(context, csv, 'Zikir & Tasbih (CSV)');
                  },
          ),
          const SizedBox(width: 2),
          _buildPillButton(
            icon: Icons.share_rounded,
            label: 'Share',
            isLoading: _loadingAction == 'zikir_share',
            onPressed: _loadingAction != null
                ? null
                : () async {
                    setState(() => _loadingAction = 'zikir_share');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    if (!mounted) return;
                    final csv = _generateZikirCsv(ptc);
                    await _shareFile(
                      this.context,
                      content: csv,
                      fileName: 'zikir_tasbih_$todayStr.csv',
                      mimeType: 'text/csv',
                      subject: 'Personal Expense Zikir & Tasbih ($todayStr)',
                    );
                    if (mounted) {
                      setState(() => _loadingAction = null);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildZikirExcelCard({
    required BuildContext context,
    required PrayerTasbihController? ptc,
    required String todayStr,
    required AppPalette p,
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
          _buildPillButton(
            icon: Icons.share_rounded,
            label: 'Share Excel',
            color: const Color(0xFF10B981),
            isLoading: _loadingAction == 'excel_zikir',
            onPressed: _loadingAction != null
                ? null
                : () async {
                    setState(() => _loadingAction = 'excel_zikir');
                    await Future<void>.delayed(const Duration(milliseconds: 250));
                    if (!mounted) return;
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
                    final bytes = _generateSingleTabExcel(
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
                    if (bytes != null && mounted) {
                      await _shareBytesFile(
                        this.context,
                        bytes: bytes,
                        fileName: 'zikir_tasbih_$todayStr.xlsx',
                        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                        subject: 'Personal Expense Zikir & Tasbih ($todayStr)',
                      );
                    }
                    if (mounted) {
                      setState(() => _loadingAction = null);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildFullBackupCard({
    required BuildContext context,
    required TransactionsController tc,
    required NotesController? nc,
    required SettingsController sc,
    required PrayerTasbihController? ptc,
    required int txCount,
    required int notesCount,
    required int tasbihCount,
    required String todayStr,
    required AppPalette p,
  }) {
    final isBackingUp = _loadingAction == 'backup';
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
              _buildIconAction(
                icon: Icons.visibility_outlined,
                tooltip: 'Preview',
                color: p.mute,
                onPressed: _loadingAction != null
                    ? null
                    : () {
                        final jsonStr = _generateFullJsonBackup(tc, nc ?? NotesController(), sc, ptc);
                        _previewData(context, jsonStr, 'Full Data Backup (JSON)');
                      },
              ),
              _buildIconAction(
                icon: Icons.share_rounded,
                tooltip: 'Share Backup',
                color: p.income,
                isLoading: _loadingAction == 'backup_share',
                onPressed: _loadingAction != null
                    ? null
                    : () async {
                        setState(() => _loadingAction = 'backup_share');
                        _showLoadingProgressDialog(
                          context,
                          p,
                          title: 'Generating Backup...',
                          subtitle: 'Packing transactions, notes & tasbih records...',
                          status: 'Sharing backup file...',
                        );
                        await Future<void>.delayed(const Duration(milliseconds: 600));
                        _dismissLoadingDialog();
                        if (!mounted) return;
                        final jsonStr = _generateFullJsonBackup(tc, nc ?? NotesController(), sc, ptc);
                        await _shareFile(
                          this.context,
                          content: jsonStr,
                          fileName: 'personal_expense_backup_$todayStr.json',
                          mimeType: 'application/json',
                          subject: 'Personal Expense Full Backup ($todayStr)',
                        );
                        if (mounted) {
                          setState(() => _loadingAction = null);
                        }
                      },
              ),
              const SizedBox(width: 2),
              _buildPillButton(
                icon: Icons.cloud_upload_rounded,
                label: 'Backup',
                color: p.income,
                isLoading: isBackingUp,
                onPressed: _loadingAction != null
                    ? null
                    : () async {
                        setState(() => _loadingAction = 'backup');
                        _showLoadingProgressDialog(
                          context,
                          p,
                          title: 'Generating Backup...',
                          subtitle: 'Packing transactions, notes & tasbih records...',
                          status: 'Preparing JSON backup file...',
                        );
                        await Future<void>.delayed(const Duration(milliseconds: 700));
                        _dismissLoadingDialog();
                        if (!mounted) return;
                        final jsonStr = _generateFullJsonBackup(tc, nc ?? NotesController(), sc, ptc);
                        setState(() => _loadingAction = null);
                        _showBackupSuccessSheet(this.context, jsonStr, txCount, notesCount, tasbihCount);
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

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tc = Get.find<TransactionsController>();
    final nc = Get.isRegistered<NotesController>() ? Get.find<NotesController>() : null;
    final sc = Get.find<SettingsController>();
    final ptc = Get.isRegistered<PrayerTasbihController>()
        ? Get.find<PrayerTasbihController>()
        : (Get.put(PrayerTasbihController(), permanent: true));

    final txCount = tc.entries.length;
    final notesCount = nc?.notes.length ?? 0;
    final tasbihCount = ptc.historyEntries.isNotEmpty
        ? ptc.historyEntries.length
        : ptc.zikirLifetimeCounts.values.where((c) => c > 0).length;

    final todayStr = DataExportSheet.formatIsoDate(DateTime.now());

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
                // Drag handle
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
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.mute),
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
              _buildMultiTabExcelCard(
                context: context,
                tc: tc,
                nc: nc,
                ptc: ptc,
                txCount: txCount,
                notesCount: notesCount,
                tasbihCount: tasbihCount,
                todayStr: todayStr,
                p: p,
              ),
              const SizedBox(height: 10),

              // Option 1: Transactions CSV
              _buildTransactionsCsvCard(context: context, tc: tc, todayStr: todayStr, p: p),
              const SizedBox(height: 10),

              // Option 2: Notes & Debts CSV
              if (nc != null) ...[
                _buildNotesCsvCard(context: context, nc: nc, todayStr: todayStr, p: p),
                const SizedBox(height: 10),
              ],

              // Option 3: Zikir & Tasbih CSV
              _buildZikirCsvCard(context: context, ptc: ptc, todayStr: todayStr, p: p),
              const SizedBox(height: 10),

              // Option 4: Full JSON Backup
              _buildFullBackupCard(
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
              ),
            ] else if (_selectedTab == 1) ...[
              // Tab 1: Transactions
              _buildTransactionsExcelCard(context: context, tc: tc, todayStr: todayStr, p: p),
              const SizedBox(height: 10),
              _buildTransactionsCsvCard(context: context, tc: tc, todayStr: todayStr, p: p),
            ] else if (_selectedTab == 2) ...[
              // Tab 2: Notes & Debts
              if (nc != null) ...[
                _buildNotesExcelCard(context: context, nc: nc, todayStr: todayStr, p: p),
                const SizedBox(height: 10),
                _buildNotesCsvCard(context: context, nc: nc, todayStr: todayStr, p: p),
              ],
            ] else if (_selectedTab == 3) ...[
              // Tab 3: Zikir Logs
              _buildZikirExcelCard(context: context, ptc: ptc, todayStr: todayStr, p: p),
              const SizedBox(height: 10),
              _buildZikirCsvCard(context: context, ptc: ptc, todayStr: todayStr, p: p),
            ],

            const SizedBox(height: 16),

            // Cancel / Close button
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
