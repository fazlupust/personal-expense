import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_widgets.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_app_bar.dart';
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

  Future<bool?> _confirmExit(BuildContext context) {
    final p = context.pal;
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.expense.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.exit_to_app_rounded, color: p.expense, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                'Exit App?'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to close the app?'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: p.mute),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      'Cancel',
                      style: AppButtonStyle.outlined,
                      height: 44,
                      fontSize: 13.5,
                      margin: EdgeInsets.zero,
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      'Exit',
                      style: AppButtonStyle.cancel,
                      height: 44,
                      fontSize: 13.5,
                      margin: EdgeInsets.zero,
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
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

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GetBuilder<NavigationController>(builder: (c) {
      final size = Responsive.sizeOf(context);
      final fab = Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF0D9488), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.38),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => showEntrySheet(context),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const CircleBorder(),
          tooltip: '+ Add'.tr,
          child: const Icon(Icons.add_rounded, size: 30),
        ),
      );
      final page = _pages[c.index];

      final Widget scaffold;
      if (size == ScreenSize.mobile) {
        scaffold = Scaffold(
          appBar: CustomAppBar(
            title: _labels[c.index].tr,
          ),
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
            height: 70,
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
      } else {
        final extended = size == ScreenSize.desktop;
        scaffold = Scaffold(
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
                              Text('My Wallet'.tr,
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
                        label: Text(
                          _labels[i].tr,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              VerticalDivider(width: 1, color: p.line),
              Expanded(
                child: Column(
                  children: [
                    CustomAppBar(
                      title: _labels[c.index].tr,
                      showBackButton: false,
                    ),
                    Expanded(child: SafeArea(child: page)),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (c.index != 0) {
            c.select(0);
            return;
          }
          final shouldExit = await _confirmExit(context);
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        },
        child: scaffold,
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
            Icon(selected ? selectedIcon : icon, color: color, size: 24.5),
            const SizedBox(height: 2.5),
            Text(
              label.tr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
