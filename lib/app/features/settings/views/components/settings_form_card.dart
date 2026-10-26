import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../controllers/settings_controller.dart';

import '../../../../data/services/app_update_service.dart';

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
          AppButton('Save settings', onPressed: s.saveProfile),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => AppUpdateService.to.checkManually(),
            icon: Icon(Icons.sync_rounded, size: 16, color: context.pal.acc),
            label: Text(
              'Check for Updates'.tr,
              style: TextStyle(
                color: context.pal.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              side: BorderSide(color: context.pal.line),
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
                  'Personal Expense v$v',
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
