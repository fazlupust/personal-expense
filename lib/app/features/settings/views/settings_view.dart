import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/entry_type.dart';
import '../../../routes/app_routes.dart';
import '../../transactions/controllers/transactions_controller.dart';
import '../controllers/settings_controller.dart';
import 'components/settings_form_card.dart';

/// "Profile" tab: profile header, lifetime stats, settings and category shortcut.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GetBuilder<SettingsController>(
      builder: (s) => GetBuilder<TransactionsController>(builder: (tc) {
        final income = tc.sum(tc.entries, EntryType.income);
        final expense = tc.sum(tc.entries, EntryType.expense);
        final balance = income - expense;
        return ContentWrap(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageTitle('Profile'),
              AdaptiveColumns(
                left: [
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: p.income, shape: BoxShape.circle),
                          child: Text(
                            s.name.isEmpty ? '?' : s.name.characters.first.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            s.name.isEmpty ? 'Add your name'.tr : s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppCard(
                    child: StatGrid(items: [
                      StatItem('Total entries', Fmt.count(tc.entries.length)),
                      StatItem('Lifetime balance', '${balance < 0 ? '−' : ''}${Fmt.money(balance.abs())}'),
                      StatItem('Total income', Fmt.money(income)),
                      StatItem('Total expense', Fmt.money(expense)),
                    ]),
                  ),
                  AppCard(
                    flush: true,
                    child: InkWell(
                      onTap: () => Get.toNamed(AppRoutes.categories),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.category_outlined, color: p.income),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Manage categories'.tr,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.ink)),
                            ),
                            Icon(Icons.chevron_right, color: p.mute),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                right: [SettingsFormCard(settings: s)],
              ),
            ],
          ),
        );
      }),
    );
  }
}
