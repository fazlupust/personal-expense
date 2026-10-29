import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:personal_expense/app/core/constants/app_constants.dart';
import 'package:personal_expense/app/features/notes/controllers/notes_controller.dart';
import 'package:personal_expense/app/features/prayer_tasbih/controllers/prayer_tasbih_controller.dart';
import 'package:personal_expense/app/features/transactions/controllers/transactions_controller.dart';
import 'package:personal_expense/app/features/settings/controllers/settings_controller.dart';

class DataExportGenerator {
  const DataExportGenerator._();

  static String formatIsoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String formatAsciiTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  static String cleanCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

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

  static String generateFullJsonBackup(
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
      'transactions': tc.entries.map((e) => e.toJson()).toList(),
      'notes': nc.notes.map((n) => n.toJson()).toList(),
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
    final encoder = JsonEncoder.withIndent('  ', (nonEncodable) {
      if (nonEncodable is Timestamp) {
        return nonEncodable.toDate().toIso8601String();
      }
      if (nonEncodable is DateTime) {
        return nonEncodable.toIso8601String();
      }
      return nonEncodable.toString();
    });
    return encoder.convert(map);
  }
}
