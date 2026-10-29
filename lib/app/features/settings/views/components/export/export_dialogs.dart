import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:personal_expense/app/core/theme/app_theme.dart';
import 'package:personal_expense/app/core/theme/app_widgets.dart';
import 'package:personal_expense/app/core/utils/formatters.dart';

class ExportDialogs {
  const ExportDialogs._();

  static void showLoadingProgressDialog(
    BuildContext context,
    AppPalette p, {
    required String title,
    required String subtitle,
    required String status,
    IconData statusIcon = Icons.cloud_sync_rounded,
    required void Function(BuildContext dialogContext) onCreated,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogCtx) {
        onCreated(dialogCtx);
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

  static void showDataPreviewDialog(
    BuildContext context,
    String data,
    String title,
  ) {
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

  static void showWorkbookPreviewDialog(
    BuildContext context, {
    required int txCount,
    required int notesCount,
    required int tasbihCount,
    required VoidCallback onShareExcel,
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
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          onShareExcel();
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

  static Widget _buildPreviewTabItem({
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

  static void showBackupSuccessSheet(
    BuildContext context,
    String jsonStr,
    int txCount,
    int notesCount,
    int tasbihCount, {
    required Future<void> Function(BuildContext sheetCtx, String jsonStr) onShareBackup,
    required VoidCallback onDismissAll,
  }) {
    final p = context.pal;
    final dateStr = Fmt.date(DateTime.now(), 'yyyy-MM-dd, hh:mm a');

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
                              await onShareBackup(sheetContext, jsonStr);
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
                              showDataPreviewDialog(sheetContext, jsonStr, 'Full Data Backup (JSON)');
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
                              onDismissAll();
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
}
