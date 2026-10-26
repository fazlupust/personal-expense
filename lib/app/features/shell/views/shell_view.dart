import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../reports/views/reports_view.dart';
import '../../settings/views/settings_view.dart';
import '../../transactions/views/components/entry_form_sheet.dart';
import '../../transactions/views/transactions_view.dart';
import '../controllers/shell_controller.dart';

/// Root layout: bottom navigation on phones, side rail/sidebar on tablet & desktop.
class ShellView extends StatelessWidget {
  const ShellView({super.key});

  static const _pages = <Widget>[
    DashboardView(),
    TransactionsView(),
    ReportsView(),
    SettingsView(),
  ];

  static const _icons = <IconData>[
    Icons.home_outlined,
    Icons.receipt_long_outlined,
    Icons.bar_chart_outlined,
    Icons.person_outline,
  ];
  static const _selectedIcons = <IconData>[
    Icons.home,
    Icons.receipt_long,
    Icons.bar_chart,
    Icons.person,
  ];
  static const _labels = ['Dashboard', 'Transactions', 'Reports', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GetBuilder<ShellController>(builder: (c) {
      final size = Responsive.sizeOf(context);
      final fab = FloatingActionButton.extended(
        onPressed: () => showEntrySheet(context),
        backgroundColor: p.income,
        foregroundColor: Colors.white,
        label: Text('+ Add'.tr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      );
      final page = _pages[c.index];

      if (size == ScreenSize.mobile) {
        return Scaffold(
          body: SafeArea(child: page),
          floatingActionButton: fab,
          bottomNavigationBar: NavigationBar(
            selectedIndex: c.index,
            onDestinationSelected: c.select,
            destinations: [
              for (var i = 0; i < _labels.length; i++)
                NavigationDestination(
                  icon: Icon(_icons[i]),
                  selectedIcon: Icon(_selectedIcons[i], color: p.income),
                  label: _labels[i].tr,
                ),
            ],
          ),
        );
      }

      final extended = size == ScreenSize.desktop;
      return Scaffold(
        floatingActionButton: fab,
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: extended,
                selectedIndex: c.index,
                onDestinationSelected: c.select,
                labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: extended
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, color: p.income),
                            const SizedBox(width: 10),
                            Text('Personal Expense'.tr,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink)),
                          ],
                        )
                      : Icon(Icons.account_balance_wallet_outlined, color: p.income),
                ),
                destinations: [
                  for (var i = 0; i < _labels.length; i++)
                    NavigationRailDestination(
                      icon: Icon(_icons[i]),
                      selectedIcon: Icon(_selectedIcons[i], color: p.income),
                      label: Text(_labels[i].tr),
                    ),
                ],
              ),
            ),
            VerticalDivider(width: 1, color: p.line),
            Expanded(child: SafeArea(child: page)),
          ],
        ),
      );
    });
  }
}
