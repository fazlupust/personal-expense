import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../reports/views/reports_view.dart';
import '../../settings/views/settings_view.dart';
import '../../transactions/views/components/entry_form_sheet.dart';
import '../../transactions/views/transactions_view.dart';
import '../controllers/navigation_controller.dart';

/// Root navigation layout: notched bottom navigation on phones, side rail on tablet & desktop.
class NavigationView extends StatelessWidget {
  const NavigationView({super.key});

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
    return GetBuilder<NavigationController>(builder: (c) {
      final size = Responsive.sizeOf(context);
      final fab = FloatingActionButton(
        onPressed: () => showEntrySheet(context),
        backgroundColor: p.income,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        tooltip: '+ Add'.tr,
        child: const Icon(Icons.add, size: 28),
      );
      final page = _pages[c.index];

      if (size == ScreenSize.mobile) {
        return Scaffold(
          body: SafeArea(child: page),
          floatingActionButton: fab,
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            color: p.card,
            elevation: 8,
            shadowColor: Colors.black38,
            surfaceTintColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            height: 64,
            child: Row(
              children: [
                _buildNavItem(c, p, 0, _icons[0], _selectedIcons[0], _labels[0]),
                _buildNavItem(c, p, 1, _icons[1], _selectedIcons[1], _labels[1]),
                const SizedBox(width: 56),
                _buildNavItem(c, p, 2, _icons[2], _selectedIcons[2], _labels[2]),
                _buildNavItem(c, p, 3, _icons[3], _selectedIcons[3], _labels[3]),
              ],
            ),
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 28,
                                height: 28,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.account_balance_wallet, size: 24, color: p.income),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('Personal Expense'.tr,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 28,
                            height: 28,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.account_balance_wallet, size: 24, color: p.income),
                          ),
                        ),
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

  Widget _buildNavItem(
    NavigationController c,
    AppPalette p,
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final selected = c.index == index;
    final color = selected ? p.income : p.mute;
    return Expanded(
      child: InkResponse(
        onTap: () => c.select(index),
        radius: 26,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
