import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../controllers/settings_controller.dart';

import '../../../../data/services/app_update_service.dart';
import '../../../../data/services/auth_service.dart';
import 'budget_management_sheet.dart';
import 'change_password_sheet.dart';
import 'data_export_sheet.dart';

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
              TextButton.icon(
                onPressed: () => showBudgetManagementSheet(context),
                icon: Icon(Icons.tune_rounded, size: 15, color: context.pal.income),
                label: Text(
                  'Manage Category Budgets'.tr,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.pal.income,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          const SizedBox(height: 16),
          AppButton('Save settings', onPressed: s.saveProfile),

          const SizedBox(height: 4),
          ElevatedButton.icon(
            onPressed: () => showDataExportSheet(context),
            icon: const Icon(Icons.file_download_outlined, size: 17, color: Colors.white),
            label: Text(
              'Export Data (CSV / JSON)'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              backgroundColor: context.pal.income,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          // Change password option if logged in
          if (Get.isRegistered<AuthService>() && Get.find<AuthService>().isLoggedIn) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => showChangePasswordSheet(context),
              icon: const Icon(Icons.lock_reset_rounded, size: 16, color: Colors.white),
              label: Text(
                'Change Password'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                backgroundColor: context.pal.income,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],

          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => AppUpdateService.to.checkManually(),
            icon: const Icon(Icons.sync_rounded, size: 16, color: Colors.white),
            label: Text(
              'Check for Updates'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              backgroundColor: context.pal.income,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (ctx, snapshot) {
                final v = snapshot.data?.version ?? '1.0.0';
                return Text(
                  '${AppConstants.appName} v$v',
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
