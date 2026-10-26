import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../routes/app_routes.dart';
import '../../controllers/transactions_controller.dart';

class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({super.key});

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  void _openMonthYearPicker(BuildContext context, TransactionsController tc) {
    final p = context.pal;
    final now = DateTime.now();
    int tempYear = tc.month.year;
    int tempMonth = tc.month.month;
    bool tempYearOnly = tc.isYearOnly;

    // Available years from 3 years ago to next year
    final years = List.generate(5, (i) => now.year - 3 + i);

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: p.line),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Month & Year'.tr,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Year selector row
                  Text(
                    'Select Year'.tr,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.mute),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: years.map((y) {
                        final isSel = y == tempYear;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              '$y',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? Colors.white : p.ink,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: p.income,
                            backgroundColor: p.bg,
                            side: BorderSide(color: isSel ? p.income : p.line),
                            onSelected: (_) {
                              setState(() {
                                tempYear = y;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Month selection grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Month'.tr,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.mute),
                      ),
                      // Whole Year Toggle
                      InkWell(
                        onTap: () {
                          setState(() {
                            tempYearOnly = !tempYearOnly;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tempYearOnly ? Icons.check_circle : Icons.circle_outlined,
                                size: 16,
                                color: tempYearOnly ? p.income : p.mute,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'All Year'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tempYearOnly ? p.income : p.mute,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 12 Months Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: 12,
                    itemBuilder: (ctx, i) {
                      final m = i + 1;
                      final isSel = !tempYearOnly && m == tempMonth;
                      return Material(
                        color: isSel ? p.income : (tempYearOnly ? p.bg.withOpacity(0.5) : p.bg),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              tempMonth = m;
                              tempYearOnly = false;
                            });
                          },
                          child: Center(
                            child: Text(
                              _monthNames[i].tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isSel ? Colors.white : (tempYearOnly ? p.mute : p.ink),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Actions: Current Month and Apply
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            tc.resetToCurrentMonth();
                            Get.back();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: p.ink,
                            side: BorderSide(color: p.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Current month'.tr),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (tempYearOnly) {
                              tc.setYearOnly(tempYear);
                            } else {
                              tc.setYearAndMonth(tempYear, tempMonth);
                            }
                            Get.back();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: p.income,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Apply'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return GetBuilder<TransactionsController>(
      builder: (tc) {
        final label = tc.isYearOnly
            ? '${tc.month.year} (${'All Year'.tr})'
            : Fmt.date(tc.month, 'MMMM yyyy');

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // 1. Month / Year Selector Button (NO ARROWS)
              Expanded(
                child: Material(
                  color: p.card,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openMonthYearPicker(context, tc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.line),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: p.income,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: p.mute,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Generate Report Button
              Material(
                color: p.income.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Get.toNamed(AppRoutes.generateReport),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.income.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.analytics_rounded,
                          size: 18,
                          color: p.income,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Generate Report'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: p.income,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
