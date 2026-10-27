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
  // 0 = Last 7 Days (বিগত ৭ দিন), 1 = Weekly Breakdown (সাপ্তাহিক)
  int _viewMode = 0;
  int? _selectedBarIndex;

  static const _bnMonths = [
    'জানু',
    'ফেব্রু',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টে',
    'অক্টো',
    'নভে',
    'ডিসে'
  ];

  static const _bnFullDays = [
    'সোমবার',
    'মঙ্গলবার',
    'বুধবার',
    'বৃহস্পতিবার',
    'শুক্রবার',
    'শনিবার',
    'রবিবার',
  ];

  String _formatShortDate(DateTime date, bool isBn) {
    if (isBn) {
      final dayStr = Fmt.count(date.day);
      final mStr = _bnMonths[(date.month - 1).clamp(0, 11)];
      return '$dayStr $mStr';
    } else {
      return DateFormat('d MMM').format(date);
    }
  }

  String _getDayName(DateTime date, bool isToday, bool isYesterday, bool isBn) {
    if (isToday) return isBn ? 'আজ' : 'Today';
    if (isYesterday) return isBn ? 'গতকাল' : 'Yest';
    if (isBn) {
      switch (date.weekday) {
        case DateTime.saturday:
          return 'শনি';
        case DateTime.sunday:
          return 'রবি';
        case DateTime.monday:
          return 'সোম';
        case DateTime.tuesday:
          return 'মঙ্গল';
        case DateTime.wednesday:
          return 'বুধ';
        case DateTime.thursday:
          return 'বৃহঃ';
        case DateTime.friday:
          return 'শুক্র';
        default:
          return '';
      }
    } else {
      switch (date.weekday) {
        case DateTime.saturday:
          return 'Sat';
        case DateTime.sunday:
          return 'Sun';
        case DateTime.monday:
          return 'Mon';
        case DateTime.tuesday:
          return 'Tue';
        case DateTime.wednesday:
          return 'Wed';
        case DateTime.thursday:
          return 'Thu';
        case DateTime.friday:
          return 'Fri';
        default:
          return '';
      }
    }
  }

  String _getFullDayName(DateTime date, bool isBn) {
    if (isBn) {
      return _bnFullDays[(date.weekday - 1).clamp(0, 6)];
    } else {
      return DateFormat('EEEE').format(date);
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

    final today = DateTime.now();
    final isCurrentMonth = today.year == currentMonth.year && today.month == currentMonth.month;
    final anchorDay = isCurrentMonth ? today.day : totalDays;

    // --- Prepare Last 7 Days Data ---
    final last7DaysList = <_DayChartItem>[];
    final startDay = math.max(1, anchorDay - 6);
    final endDay = math.min(totalDays, startDay + 6);

    for (int day = startDay; day <= endDay; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      final isToday = isCurrentMonth && day == today.day;
      final isYesterday = isCurrentMonth && day == today.day - 1;
      final dayName = _getDayName(date, isToday, isYesterday, isBn);
      final fullDayName = _getFullDayName(date, isBn);
      final shortDate = _formatShortDate(date, isBn);
      final amount = (day - 1 < values.length) ? values[day - 1] : 0.0;

      last7DaysList.add(_DayChartItem(
        dayNumber: day,
        date: date,
        dayName: dayName,
        fullDayName: fullDayName,
        shortDate: shortDate,
        amount: amount,
        isToday: isToday,
      ));
    }

    // --- Prepare Weekly Breakdown Data ---
    final weeklyList = <_WeekChartItem>[];
    // Week 1: 1-7
    // Week 2: 8-14
    // Week 3: 15-21
    // Week 4: 22-28
    // Week 5: 29-end
    final weekRanges = [
      {'start': 1, 'end': 7, 'labelBn': '১ম সপ্তাহ', 'labelEn': 'Week 1', 'subBn': '১-৭ তারিখ', 'subEn': '1-7'},
      {'start': 8, 'end': 14, 'labelBn': '২য় সপ্তাহ', 'labelEn': 'Week 2', 'subBn': '৮-১৪ তারিখ', 'subEn': '8-14'},
      {'start': 15, 'end': 21, 'labelBn': '৩য় সপ্তাহ', 'labelEn': 'Week 3', 'subBn': '১৫-২১ তারিখ', 'subEn': '15-21'},
      {'start': 22, 'end': 28, 'labelBn': '৪র্থ সপ্তাহ', 'labelEn': 'Week 4', 'subBn': '২২-২৮ তারিখ', 'subEn': '22-28'},
      if (totalDays > 28)
        {
          'start': 29,
          'end': totalDays,
          'labelBn': '৫ম সপ্তাহ',
          'labelEn': 'Week 5',
          'subBn': '২৯-$totalDays তারিখ',
          'subEn': '29-$totalDays'
        },
    ];

    for (int i = 0; i < weekRanges.length; i++) {
      final r = weekRanges[i];
      final s = r['start'] as int;
      final e = math.min(totalDays, r['end'] as int);
      double sum = 0.0;
      for (int d = s; d <= e; d++) {
        if (d - 1 < values.length) {
          sum += values[d - 1];
        }
      }
      weeklyList.add(_WeekChartItem(
        label: isBn ? (r['labelBn'] as String) : (r['labelEn'] as String),
        rangeText: isBn ? (r['subBn'] as String) : (r['subEn'] as String),
        amount: sum,
      ));
    }

    // Determine selected item inspection info
    String bannerTitle;
    String bannerAmount;

    if (widget.isExpenseHidden) {
      bannerTitle = _viewMode == 0 ? 'Last 7 Days Expense'.tr : 'Weekly Expense Breakdown'.tr;
      bannerAmount = '••••••';
    } else if (_viewMode == 0) {
      // Last 7 days inspect
      if (_selectedBarIndex != null && _selectedBarIndex! < last7DaysList.length) {
        final item = last7DaysList[_selectedBarIndex!];
        bannerTitle = '${item.fullDayName}, ${item.shortDate}';
        bannerAmount = item.amount > 0 ? '${AppConstants.currency}${Fmt.money(item.amount)}' : 'No expense'.tr;
      } else {
        // Find highest day in the 7 days or total
        final highest = last7DaysList.reduce((a, b) => a.amount >= b.amount ? a : b);
        if (highest.amount > 0) {
          bannerTitle = '${'Highest:'.tr} ${highest.dayName} (${highest.shortDate})';
          bannerAmount = '${AppConstants.currency}${Fmt.money(highest.amount)}';
        } else {
          bannerTitle = 'Last 7 Days Expense'.tr;
          bannerAmount = '${AppConstants.currency}0';
        }
      }
    } else {
      // Weekly inspect
      if (_selectedBarIndex != null && _selectedBarIndex! < weeklyList.length) {
        final item = weeklyList[_selectedBarIndex!];
        bannerTitle = '${item.label} (${item.rangeText})';
        bannerAmount = item.amount > 0 ? '${AppConstants.currency}${Fmt.money(item.amount)}' : 'No expense'.tr;
      } else {
        final highestWeek = weeklyList.reduce((a, b) => a.amount >= b.amount ? a : b);
        if (highestWeek.amount > 0) {
          bannerTitle = '${'Highest:'.tr} ${highestWeek.label}';
          bannerAmount = '${AppConstants.currency}${Fmt.money(highestWeek.amount)}';
        } else {
          bannerTitle = 'Weekly Expense Breakdown'.tr;
          bannerAmount = '${AppConstants.currency}0';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Title & View Mode Switcher [Last 7 Days | Weekly]
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 17, color: p.expense),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Expense Chart'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Segment Switcher: [Last 7 Days | Weekly]
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: p.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(0, 'Last 7 Days'.tr, p),
                    _buildModeButton(1, 'Weekly'.tr, p),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Informative Banner showing Date/Day name and Amount
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: p.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.line.withOpacity(0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bannerTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _selectedBarIndex != null ? 'Tap again to reset'.tr : 'Tap bar to see details'.tr,
                        style: TextStyle(fontSize: 10, color: p.mute),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  bannerAmount,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: p.expense,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Main Chart rendering based on selected view mode
          _viewMode == 0
              ? _buildLast7DaysChart(context, last7DaysList, p)
              : _buildWeeklyChart(context, weeklyList, p),
        ],
      ),
    );
  }

  Widget _buildModeButton(int index, String label, AppPalette p) {
    final isSelected = _viewMode == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = index;
          _selectedBarIndex = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected ? p.income : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : p.mute,
          ),
        ),
      ),
    );
  }

  Widget _buildLast7DaysChart(
    BuildContext context,
    List<_DayChartItem> items,
    AppPalette p,
  ) {
    double max = 1.0;
    for (final it in items) {
      if (it.amount > max) max = it.amount;
    }

    return Column(
      children: [
        // Bars Row with amount on top and rounded bars
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(items.length, (i) {
              final it = items[i];
              final isSelected = _selectedBarIndex == i;
              final hasExpense = it.amount > 0;
              final double heightRatio = hasExpense ? (it.amount / max).clamp(0.12, 1.0) : 0.05;
              final barHeight = heightRatio * 64.0;

              String amountLabel;
              if (widget.isExpenseHidden) {
                amountLabel = '••';
              } else if (!hasExpense) {
                amountLabel = '—';
              } else if (it.amount >= 1000) {
                amountLabel = '${(it.amount / 1000).toStringAsFixed(1)}k';
              } else {
                amountLabel = Fmt.money(it.amount);
              }

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedBarIndex = (_selectedBarIndex == i) ? null : i;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Amount Label
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            amountLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected || hasExpense ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? p.expense : (hasExpense ? p.ink : p.mute.withOpacity(0.6)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // The Bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: hasExpense
                                ? LinearGradient(
                                    colors: isSelected
                                        ? [p.expense, const Color(0xFFD63031)]
                                        : [p.expense, p.expense.withOpacity(0.75)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: hasExpense
                                ? null
                                : (it.isToday ? p.income.withOpacity(0.25) : p.line.withOpacity(0.6)),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                            border: isSelected
                                ? Border.all(color: p.ink, width: 1.5)
                                : (it.isToday && !hasExpense
                                    ? Border.all(color: p.income, width: 1)
                                    : null),
                            boxShadow: isSelected && hasExpense
                                ? [
                                    BoxShadow(
                                      color: p.expense.withOpacity(0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
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

        // Bottom Baseline
        Container(
          height: 1.2,
          color: p.line,
        ),
        const SizedBox(height: 6),

        // Day Name & Short Date Row
        Row(
          children: List.generate(items.length, (i) {
            final it = items[i];
            final isSelected = _selectedBarIndex == i;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedBarIndex = (_selectedBarIndex == i) ? null : i;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Day Name (e.g. 'আজ', 'গতকাল', 'বৃহঃ', 'শুক্র')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: it.isToday
                          ? BoxDecoration(
                              color: p.income.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: Text(
                        it.dayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: it.isToday || isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: it.isToday ? p.income : (isSelected ? p.ink : p.mute),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    // Short Date (e.g. '২৪ অক্টো')
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        it.shortDate,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: p.mute.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(
    BuildContext context,
    List<_WeekChartItem> weeks,
    AppPalette p,
  ) {
    double max = 1.0;
    for (final w in weeks) {
      if (w.amount > max) max = w.amount;
    }

    return Column(
      children: [
        // Weekly Bars
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(weeks.length, (i) {
              final w = weeks[i];
              final isSelected = _selectedBarIndex == i;
              final hasExpense = w.amount > 0;
              final double heightRatio = hasExpense ? (w.amount / max).clamp(0.15, 1.0) : 0.06;
              final barHeight = heightRatio * 64.0;

              String amountLabel;
              if (widget.isExpenseHidden) {
                amountLabel = '••';
              } else if (!hasExpense) {
                amountLabel = '—';
              } else if (w.amount >= 1000) {
                amountLabel = '${(w.amount / 1000).toStringAsFixed(1)}k';
              } else {
                amountLabel = Fmt.money(w.amount);
              }

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedBarIndex = (_selectedBarIndex == i) ? null : i;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            amountLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected || hasExpense ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? p.expense : (hasExpense ? p.ink : p.mute.withOpacity(0.6)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: hasExpense
                                ? LinearGradient(
                                    colors: isSelected
                                        ? [p.expense, const Color(0xFFD63031)]
                                        : [p.expense, p.expense.withOpacity(0.75)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: hasExpense ? null : p.line.withOpacity(0.6),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            border: isSelected ? Border.all(color: p.ink, width: 1.5) : null,
                            boxShadow: isSelected && hasExpense
                                ? [
                                    BoxShadow(
                                      color: p.expense.withOpacity(0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
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

        // Baseline
        Container(
          height: 1.2,
          color: p.line,
        ),
        const SizedBox(height: 6),

        // Week Label & Date Range Row
        Row(
          children: List.generate(weeks.length, (i) {
            final w = weeks[i];
            final isSelected = _selectedBarIndex == i;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _selectedBarIndex = (_selectedBarIndex == i) ? null : i;
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      w.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? p.ink : p.mute,
                      ),
                    ),
                    const SizedBox(height: 1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        w.rangeText,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: p.mute.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DayChartItem {
  final int dayNumber;
  final DateTime date;
  final String dayName;
  final String fullDayName;
  final String shortDate;
  final double amount;
  final bool isToday;

  _DayChartItem({
    required this.dayNumber,
    required this.date,
    required this.dayName,
    required this.fullDayName,
    required this.shortDate,
    required this.amount,
    required this.isToday,
  });
}

class _WeekChartItem {
  final String label;
  final String rangeText;
  final double amount;

  _WeekChartItem({
    required this.label,
    required this.rangeText,
    required this.amount,
  });
}
