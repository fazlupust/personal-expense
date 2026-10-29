import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../../settings/controllers/settings_controller.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.income,
    required this.expense,
    required this.budget,
    this.isHidden = false,
    this.onToggleVisibility,
    this.isIncomeHidden = false,
    this.onToggleIncomeVisibility,
    this.isExpenseHidden = false,
    this.onToggleExpenseVisibility,
  });

  final double income;
  final double expense;
  final double budget;
  final bool isHidden;
  final VoidCallback? onToggleVisibility;
  final bool isIncomeHidden;
  final VoidCallback? onToggleIncomeVisibility;
  final bool isExpenseHidden;
  final VoidCallback? onToggleExpenseVisibility;

  @override
  Widget build(BuildContext context) {
    final s = Get.isRegistered<SettingsController>()
        ? SettingsController.to
        : null;
    final incomeHidden = isIncomeHidden || (s?.isIncomeHidden ?? false);
    final expenseHidden = isExpenseHidden || (s?.isExpenseHidden ?? false);
    final hidden = isHidden || incomeHidden || expenseHidden;
    final toggle = onToggleVisibility ?? s?.toggleBalanceVisibility;
    final toggleIncome =
        onToggleIncomeVisibility ?? s?.toggleIncomeVisibility ?? toggle;
    final toggleExpense =
        onToggleExpenseVisibility ?? s?.toggleExpenseVisibility;
    final net = income - expense;
    final over = budget > 0 && expense > budget;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF136444), // Azan Waqt rich Islamic green (not muddy deep black)
            Color(0xFF1B8058), // Vibrant emerald
            Color(0xFF269D6E), // Bright emerald-teal highlight
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF136444).withOpacity(0.30),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
      ),
      child: Stack(
        children: [
          // Ambient background decorative circles
          Positioned(
            top: -45,
            right: -35,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -55,
            left: -35,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2ECC71).withOpacity(0.08),
              ),
            ),
          ),

          // Main Card Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header row: Badge & Currency indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 13.5,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Balance this month'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (toggle != null)
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: toggle,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4.5,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.24),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hidden
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hidden ? 'Show'.tr : 'Hide'.tr,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4EFA9D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                AppConstants.currency,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hero Balance Display
                InkWell(
                  onTap: toggle,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        hidden
                            ? '${AppConstants.currency} ••••••'
                            : Fmt.money(net),
                        style: TextStyle(
                          fontSize: hidden ? 34 : 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: hidden ? 2.0 : -0.8,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Income & Expense Glass Metric Cards
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: toggleIncome,
                          child: _GlassMetricBox(
                            label: 'Income',
                            amount: income,
                            isIncome: true,
                            isHidden: incomeHidden,
                            onToggle: toggleIncome,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: toggleExpense,
                          child: _GlassMetricBox(
                            label: 'Expense',
                            amount: expense,
                            isIncome: false,
                            isHidden: expenseHidden,
                            onToggle: toggleExpense,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Budget indicator section if configured
                if (budget > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Monthly budget (0 = none)'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.88),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                (expenseHidden || hidden)
                                    ? (over
                                          ? '${'Over budget by'.tr} ••••••'
                                          : '•••••• ${'left of'.tr} ${hidden ? '••••••' : Fmt.money(budget)}')
                                    : (over
                                          ? '${'Over budget by'.tr} ${Fmt.money(expense - budget)}'
                                          : '${Fmt.money(budget - expense)} ${'left of'.tr} ${Fmt.money(budget)}'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: over
                                      ? const Color(0xFFFF9488)
                                      : const Color(0xFF5DFFB2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (expenseHidden || hidden)
                                ? 0.0
                                : (expense / budget).clamp(0.0, 1.0).toDouble(),
                            minHeight: 6,
                            backgroundColor: Colors.white.withOpacity(0.20),
                            valueColor: AlwaysStoppedAnimation(
                              over
                                  ? const Color(0xFFFF5252)
                                  : const Color(0xFF4EFA9D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassMetricBox extends StatelessWidget {
  const _GlassMetricBox({
    required this.label,
    required this.amount,
    required this.isIncome,
    this.isHidden = false,
    this.onToggle,
  });

  final String label;
  final double amount;
  final bool isIncome;
  final bool isHidden;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final iconColor = isIncome
        ? const Color(0xFF5DFFB2)
        : const Color(0xFFFF9488);
    final circleBg = isIncome
        ? const Color(0xFF2ECC71).withOpacity(0.28)
        : const Color(0xFFE74C3C).withOpacity(0.28);
    final circleBorder = isIncome
        ? const Color(0xFF5DFFB2).withOpacity(0.45)
        : const Color(0xFFFF9488).withOpacity(0.45);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.20),
            Colors.white.withOpacity(0.11),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.28),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
              border: Border.all(color: circleBorder, width: 1.1),
            ),
            child: Center(
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: iconColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.92),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                    if (onToggle != null) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onToggle,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            isHidden
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 14,
                            color: isHidden
                                ? const Color(0xFFFFB3A7)
                                : Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    isHidden ? '••••••' : Fmt.money(amount),
                    style: TextStyle(
                      fontSize: isHidden ? 17.5 : 18.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: isHidden ? 1.5 : -0.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
