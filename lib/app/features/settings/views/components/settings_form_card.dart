import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../controllers/settings_controller.dart';

import '../../../../data/services/app_update_service.dart';
import 'budget_management_sheet.dart';
import 'data_export_sheet.dart';
import 'weather_check_sheet.dart';

class SettingsFormCard extends StatelessWidget {
  const SettingsFormCard({super.key, required this.settings});
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return AppCard(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('Your name'),
          TextField(
            controller: s.nameCtrl,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
            decoration: InputDecoration(
              hintText: 'Enter your name'.tr,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          const FieldLabel('Monthly budget (0 = none)'),
          TextField(
            controller: s.budgetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(
              errorText: s.budgetError?.tr,
              prefixIcon: Container(
                width: 44,
                alignment: Alignment.center,
                child: Text(
                  AppConstants.currency,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.pal.income,
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => showBudgetManagementSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.pal.income.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.pal.income.withOpacity(0.28)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: context.pal.income),
                      const SizedBox(width: 5),
                      Text(
                        'Manage Category Budgets'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.pal.income,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const FieldLabel('Language'),
          SegmentBar<String>(
            options: const {'en': 'English', 'bn': 'বাংলা'},
            value: s.langCode,
            onChanged: s.setLanguage,
          ),
          const FieldLabel('Theme'),
          SegmentBar<ThemeMode>(
            options: {
              ThemeMode.system: 'Auto'.tr,
              ThemeMode.light: 'Light'.tr,
              ThemeMode.dark: 'Dark'.tr,
            },
            value: s.themeMode,
            onChanged: s.setTheme,
          ),
          const FieldLabel('Default account'),
          DropdownButtonFormField<String>(
            value: s.defaultAccount,
            isExpanded: true,
            items: [
              for (final a in AppConstants.accounts) DropdownMenuItem(value: a, child: Text(a.tr)),
            ],
            onChanged: (v) {
              if (v != null) s.setDefaultAccount(v);
            },
          ),
          const SizedBox(height: 14),

          // Show income & balance toggle
          Container(
            decoration: BoxDecoration(
              color: context.pal.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.pal.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => s.setShowIncome(!s.showIncome),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: s.showIncome,
                        activeColor: context.pal.income,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onChanged: (v) {
                          if (v != null) s.setShowIncome(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show income & balance'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.pal.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Display income and balance on dashboard'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.pal.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      s.showIncome ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      size: 20,
                      color: s.showIncome ? context.pal.income : context.pal.mute,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Show expense toggle
          Container(
            decoration: BoxDecoration(
              color: context.pal.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.pal.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => s.setShowExpense(!s.showExpense),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: s.showExpense,
                        activeColor: context.pal.income,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onChanged: (v) {
                          if (v != null) s.setShowExpense(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show expense'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.pal.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Display expense on dashboard'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.pal.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      s.showExpense ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      size: 20,
                      color: s.showExpense ? context.pal.income : context.pal.mute,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Show prayer & tasbih toggle
          Container(
            decoration: BoxDecoration(
              color: context.pal.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.pal.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => s.setShowPrayerCard(!s.showPrayerCard),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: s.showPrayerCard,
                        activeColor: context.pal.income,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onChanged: (v) {
                          if (v != null) s.setShowPrayerCard(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show prayer & tasbih'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.pal.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Display prayer times and zikir card on dashboard'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.pal.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      s.showPrayerCard ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      size: 20,
                      color: s.showPrayerCard ? context.pal.income : context.pal.mute,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Show weather toggle
          Container(
            decoration: BoxDecoration(
              color: context.pal.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.pal.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => s.setShowWeatherCard(!s.showWeatherCard),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: s.showWeatherCard,
                        activeColor: context.pal.income,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        onChanged: (v) {
                          if (v != null) s.setShowWeatherCard(v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Show weather'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.pal.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Display live weather and temperature on dashboard'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.pal.mute,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      s.showWeatherCard ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      size: 20,
                      color: s.showWeatherCard ? context.pal.income : context.pal.mute,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppButton('Save settings', onPressed: s.saveProfile),

          const SizedBox(height: 4),
          AppButton(
            'Check Weather',
            icon: Icons.cloud_queue_rounded,
            height: 44,
            fontSize: 13.5,
            margin: const EdgeInsets.only(bottom: 8),
            onPressed: () => showWeatherCheckSheet(context),
          ),

          AppButton(
            'Export Data (CSV / JSON)',
            icon: Icons.file_download_outlined,
            height: 44,
            fontSize: 13.5,
            margin: const EdgeInsets.only(bottom: 8),
            onPressed: () => showDataExportSheet(context),
          ),

          GestureDetector(
            onLongPress: () => AppUpdateService.to.showTestOptionalDialog(),
            child: AppButton(
              'Check for Updates',
              icon: Icons.sync_rounded,
              height: 44,
              fontSize: 13.5,
              margin: const EdgeInsets.only(bottom: 8),
              onPressed: () => AppUpdateService.to.checkManually(),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (ctx, snapshot) {
                final v = snapshot.data?.version ?? '';
                return Text(
                  v.isNotEmpty ? '${AppConstants.appName} v$v' : AppConstants.appName,
                  style: TextStyle(fontSize: 11, color: context.pal.mute.withOpacity(0.6)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
