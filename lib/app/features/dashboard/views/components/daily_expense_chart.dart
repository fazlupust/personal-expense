import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';

class DailyExpenseChart extends StatefulWidget {
  const DailyExpenseChart({
    super.key,
    required this.values,
    this.month,
    this.isExpenseHidden = false,
  });

  final List<double> values;
  final DateTime? month;
  final bool isExpenseHidden;

  @override
  State<DailyExpenseChart> createState() => _DailyExpenseChartState();
}

class _DailyExpenseChartState extends State<DailyExpenseChart> {
  int? _selectedDayIndex;

  @override
  void didUpdateWidget(covariant DailyExpenseChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values.length != widget.values.length) {
      _selectedDayIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final values = widget.values;
    final totalDays = values.length;
    final currentMonth = widget.month ?? DateTime.now();
    final isBn = Get.locale?.languageCode == 'bn';

    if (totalDays == 0) {
      return const SizedBox.shrink();
    }

    // Find max expense and peak day
    double max = 0.0;
    int peakDayIndex = -1;
    double totalExpense = 0.0;
    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      totalExpense += v;
      if (v > max) {
        max = v;
        peakDayIndex = i;
      }
    }

    final today = DateTime.now();
    final isCurrentMonth = today.year == currentMonth.year && today.month == currentMonth.month;
    final todayDay = isCurrentMonth ? today.day : -1;

    // Determine what to display in the inspect header
    String infoTitle;
    String infoAmount;
    bool hasSelection = _selectedDayIndex != null && _selectedDayIndex! < totalDays;

    if (widget.isExpenseHidden) {
      infoTitle = 'Daily Expense (This Month)'.tr;
      infoAmount = '••••••';
    } else if (hasSelection) {
      final day = _selectedDayIndex! + 1;
      final val = values[_selectedDayIndex!];
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      final dateStr = DateFormat('d MMMM').format(date);
      infoTitle = '$dateStr (${'Day'.tr} $day)';
      infoAmount = val > 0 ? '${AppConstants.currency}${Fmt.money(val)}' : '${AppConstants.currency}0 (${'No expense'.tr})';
    } else if (max > 0 && peakDayIndex >= 0) {
      final peakDay = peakDayIndex + 1;
      infoTitle = '${'Highest Day:'.tr} $peakDay ${DateFormat('MMM').format(currentMonth)}';
      infoAmount = '${AppConstants.currency}${Fmt.money(max)}';
    } else {
      infoTitle = 'Daily Expense (This Month)'.tr;
      infoAmount = '${AppConstants.currency}0';
    }

    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header: Chart Title & Inspection info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: p.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.line.withOpacity(0.7)),
            ),
            child: Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 16, color: p.expense),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Expense Graph'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: p.mute,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        infoTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      infoAmount,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: hasSelection && values[_selectedDayIndex!] > 0
                            ? p.expense
                            : (max > 0 ? p.expense : p.mute),
                      ),
                    ),
                    if (hasSelection)
                      GestureDetector(
                        onTap: () => setState(() => _selectedDayIndex = null),
                        child: Text(
                          'Reset view'.tr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: p.mute,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    else
                      Text(
                        'Tap bar to inspect'.tr,
                        style: TextStyle(fontSize: 10, color: p.mute),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Chart Display Area with Axis Guide
          SizedBox(
            height: 95,
            child: totalExpense == 0
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 15, color: p.mute),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'No expense recorded yet this month'.tr,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: p.mute),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      // Background Max Guide Line
                      Positioned(
                        top: 4,
                        left: 0,
                        right: 0,
                        child: Row(
                          children: [
                            Text(
                              widget.isExpenseHidden
                                  ? '•••'
                                  : 'max ${AppConstants.currency}${Fmt.money(max)}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: p.mute.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: p.line.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Baseline
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 1.2,
                          color: p.line,
                        ),
                      ),

                      // Interactive Daily Bars
                      Positioned.fill(
                        top: 18,
                        bottom: 1.5,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(totalDays, (i) {
                            final v = values[i];
                            final isSelected = _selectedDayIndex == i;
                            final isToday = todayDay == (i + 1);
                            final hasVal = v > 0;

                            // Calculate height percentage (minimum 4px for non-zero, 2px faint dot for zero)
                            final availableHeight = 75.0;
                            final barHeight = hasVal
                                ? math.max(6.0, (v / max) * availableHeight)
                                : 2.5;

                            return Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    if (_selectedDayIndex == i) {
                                      _selectedDayIndex = null;
                                    } else {
                                      _selectedDayIndex = i;
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isSelected)
                                        Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.only(bottom: 2),
                                          decoration: BoxDecoration(
                                            color: p.expense,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        height: barHeight,
                                        decoration: BoxDecoration(
                                          color: hasVal
                                              ? (isSelected
                                                  ? p.expense
                                                  : p.expense.withOpacity(0.85))
                                              : (isToday
                                                  ? p.income.withOpacity(0.5)
                                                  : p.line.withOpacity(0.5)),
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(3),
                                          ),
                                          border: isSelected
                                              ? Border.all(color: p.ink, width: 1.2)
                                              : (isToday && !hasVal
                                                  ? Border.all(color: p.income, width: 0.8)
                                                  : null),
                                          boxShadow: isSelected && hasVal
                                              ? [
                                                  BoxShadow(
                                                    color: p.expense.withOpacity(0.4),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
          ),

          // X-Axis Date Markers: 1, 5, 10, 15, 20, 25, (end of month)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAxisDayLabel('1', isBn),
                _buildAxisDayLabel('5', isBn),
                _buildAxisDayLabel('10', isBn),
                _buildAxisDayLabel('15', isBn),
                _buildAxisDayLabel('20', isBn),
                _buildAxisDayLabel('25', isBn),
                _buildAxisDayLabel('$totalDays', isBn),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxisDayLabel(String day, bool isBn) {
    final label = isBn ? Fmt.count(int.tryParse(day) ?? 0) : day;
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8FA097),
      ),
    );
  }
}
