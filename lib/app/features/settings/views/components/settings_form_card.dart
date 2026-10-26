import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../controllers/settings_controller.dart';

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
            decoration: InputDecoration(errorText: s.budgetError?.tr),
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
        ],
      ),
    );
  }
}
