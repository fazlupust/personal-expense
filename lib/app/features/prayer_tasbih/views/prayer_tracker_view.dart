import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/prayer_tasbih_controller.dart';

class PrayerTrackerView extends StatefulWidget {
  final bool isEmbedded;
  const PrayerTrackerView({super.key, this.isEmbedded = false});

  @override
  State<PrayerTrackerView> createState() => _PrayerTrackerViewState();
}

class _PrayerTrackerViewState extends State<PrayerTrackerView> {
  void _showMonthPicker(BuildContext context, PrayerTasbihController c, AppPalette p) {
    final now = DateTime.now();
    final months = <DateTime>[];
    for (int i = 0; i < 12; i++) {
      months.add(DateTime(now.year, now.month - i));
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isBn = Get.locale?.languageCode == 'bn';
        return Material(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(color: p.income),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Select Month'.tr,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(ctx).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: months.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: p.line.withOpacity(0.5)),
                    itemBuilder: (context, index) {
                      final m = months[index];
                      final isSelected = c.selectedTrackerMonth.year == m.year &&
                          c.selectedTrackerMonth.month == m.month;
                      final label = isBn
                          ? DateFormat('MMMM yyyy', 'bn').format(m)
                          : DateFormat('MMMM yyyy').format(m);

                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.calendar_today_rounded,
                          color: isSelected ? p.income : p.mute,
                          size: 20,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? p.income : p.ink,
                          ),
                        ),
                        trailing: isSelected
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: p.income.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Active'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: p.income,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          c.setTrackerMonth(m);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';

    return GetBuilder<PrayerTasbihController>(
      init: Get.isRegistered<PrayerTasbihController>()
          ? Get.find<PrayerTasbihController>()
          : PrayerTasbihController(),
      builder: (c) {
        final content = _buildContent(context, c, p, isBn);
        if (widget.isEmbedded) {
          return content;
        }

        return Scaffold(
          backgroundColor: p.bg,
          appBar: CustomAppBar(
            title: 'Prayer Tracker'.tr,
            showBackButton: true,
            showLanguageToggle: false,
            showThemeToggle: false,
            showLogout: false,
            actions: [
              IconButton(
                icon: Icon(Icons.calendar_month_rounded, color: p.income, size: 21),
                tooltip: 'Select Month'.tr,
                onPressed: () => _showMonthPicker(context, c, p),
              ),
            ],
          ),
          body: SafeArea(child: content),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PrayerTasbihController c,
    AppPalette p,
    bool isBn,
  ) {
    final selMonth = c.selectedTrackerMonth;
    final now = DateTime.now();
    final isCurrentMonth = selMonth.year == now.year && selMonth.month == now.month;

    // Number of days in the month
    final daysInMonth = DateTime(selMonth.year, selMonth.month + 1, 0).day;
    final maxDay = isCurrentMonth ? now.day : daysInMonth;

    // Generate days list descending (latest day first)
    final days = <DateTime>[];
    for (int day = maxDay; day >= 1; day--) {
      days.add(DateTime(selMonth.year, selMonth.month, day));
    }

    // Apply active filter to days list
    final filteredDays = days.where((date) {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final completedCount = c.getCompletedCountForDate(dateKey);

      switch (c.selectedTrackerFilter) {
        case TrackerFilter.all:
          return true;
        case TrackerFilter.missing:
          return completedCount < kTrackerPrayers.length;
        case TrackerFilter.full5:
          return completedCount == kTrackerPrayers.length;
        case TrackerFilter.fajr:
          return c.isPrayerCompleted(dateKey, 'fajr');
        case TrackerFilter.dhuhr:
          return c.isPrayerCompleted(dateKey, 'dhuhr');
        case TrackerFilter.asr:
          return c.isPrayerCompleted(dateKey, 'asr');
        case TrackerFilter.maghrib:
          return c.isPrayerCompleted(dateKey, 'maghrib');
        case TrackerFilter.isha:
          return c.isPrayerCompleted(dateKey, 'isha');
      }
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Month Switcher Bar
          _buildMonthSwitcher(context, c, p, isBn, isCurrentMonth),
          const SizedBox(height: 12),

          // 2. Monthly Salat Analytics & Progress Card
          _buildMonthlyAnalyticsCard(c, p, isBn, selMonth),
          const SizedBox(height: 14),

          // 3. Filter Chips Bar
          _buildFilterChipsBar(c, p),
          const SizedBox(height: 14),

          // 4. Section Title & Summary Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  c.selectedTrackerFilter == TrackerFilter.missing
                      ? 'Missed Prayers Log'.tr
                      : 'Daily Prayer Log'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: p.income.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${isBn ? NumberFormat('', 'bn').format(filteredDays.length) : filteredDays.length} ${'Days'.tr}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.income,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 5. Day-by-Day Cards or Empty State
          if (filteredDays.isEmpty)
            _buildEmptyState(c, p)
          else
            ...filteredDays.map((date) => _buildDayCard(context, c, p, isBn, date)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMonthSwitcher(
    BuildContext context,
    PrayerTasbihController c,
    AppPalette p,
    bool isBn,
    bool isCurrentMonth,
  ) {
    final selMonth = c.selectedTrackerMonth;
    final now = DateTime.now();
    final monthLabel = isBn
        ? DateFormat('MMMM yyyy', 'bn').format(selMonth)
        : DateFormat('MMMM yyyy').format(selMonth);

    final canGoNext = !DateTime(selMonth.year, selMonth.month + 1).isAfter(DateTime(now.year, now.month));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: p.ink, size: 26),
            tooltip: 'Previous Month'.tr,
            onPressed: c.previousTrackerMonth,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showMonthPicker(context, c, p),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_rounded, color: p.income, size: 17),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        monthLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, color: p.mute, size: 19),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: canGoNext ? p.ink : p.mute.withOpacity(0.35),
              size: 26,
            ),
            tooltip: 'Next Month'.tr,
            onPressed: canGoNext ? c.nextTrackerMonth : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          if (!isCurrentMonth) ...[
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => c.setTrackerMonth(DateTime.now()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: p.income.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Today'.tr,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: p.income,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMonthlyAnalyticsCard(
    PrayerTasbihController c,
    AppPalette p,
    bool isBn,
    DateTime selMonth,
  ) {
    final completedTotal = c.getMonthlyCompletedPrayersCount(selMonth);
    final expectedTotal = c.getMonthlyExpectedPrayersCount(selMonth);
    final missedTotal = c.getMonthlyMissingPrayersCount(selMonth);
    final fullDays = c.getMonthlyFullSalatDaysCount(selMonth);
    final rate = c.getMonthlyCompletionRate(selMonth);
    final waqtCounts = c.getMonthlyWaqtCompletionCounts(selMonth);

    // Number of days tracked so far in the month
    final now = DateTime.now();
    final isCurrentMonth = selMonth.year == now.year && selMonth.month == now.month;
    final totalDaysTracked = isCurrentMonth ? now.day : DateTime(selMonth.year, selMonth.month + 1, 0).day;

    String formatNum(num n) => isBn ? NumberFormat('', 'bn').format(n) : n.toString();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF136444),
            const Color(0xFF1B8058),
            const Color(0xFF269D6E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF136444).withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fact_check_rounded, color: Colors.white, size: 17),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Monthly Salat Statistics'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${formatNum(rate.round())}% ${'Completed'.tr}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: expectedTotal > 0 ? (completedTotal / expectedTotal).clamp(0.0, 1.0) : 0.0,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5DFFB2)),
            ),
          ),
          const SizedBox(height: 14),

          // 4 Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Prayed'.tr,
                  value: '${formatNum(completedTotal)} / ${formatNum(expectedTotal)}',
                  valueColor: const Color(0xFF5DFFB2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.stars_rounded,
                  label: 'Full Salat Days'.tr,
                  value: '${formatNum(fullDays)} ${'Days'.tr}',
                  valueColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.cancel_outlined,
                  label: 'Total Missed'.tr,
                  value: '${formatNum(missedTotal)} ${'Waqts'.tr}',
                  valueColor: missedTotal > 0 ? const Color(0xFFFF9488) : const Color(0xFF5DFFB2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricBox(
                  icon: Icons.percent_rounded,
                  label: 'Success Rate'.tr,
                  value: '${formatNum(rate.round())}%',
                  valueColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Waqt-wise Completion Badges Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: kTrackerPrayers.map((prayer) {
                final count = waqtCounts[prayer.key] ?? 0;
                final isFull = count == totalDaysTracked && totalDaysTracked > 0;
                return Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isBn ? prayer.nameBn : prayer.nameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatNum(count),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: isFull ? const Color(0xFF5DFFB2) : Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: valueColor),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChipsBar(PrayerTasbihController c, AppPalette p) {
    final filters = [
      (TrackerFilter.all, 'All Prayers'.tr, Icons.checklist_rounded),
      (TrackerFilter.missing, 'Missing Only'.tr, Icons.warning_amber_rounded),
      (TrackerFilter.full5, 'Full 5 Waqt'.tr, Icons.verified_rounded),
      (TrackerFilter.fajr, 'Fajr'.tr, Icons.wb_twilight_rounded),
      (TrackerFilter.dhuhr, 'Dhuhr'.tr, Icons.wb_sunny_rounded),
      (TrackerFilter.asr, 'Asr'.tr, Icons.wb_sunny_outlined),
      (TrackerFilter.maghrib, 'Maghrib'.tr, Icons.nights_stay_outlined),
      (TrackerFilter.isha, 'Isha'.tr, Icons.bedtime_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((item) {
          final isSelected = c.selectedTrackerFilter == item.$1;
          final isMissingFilter = item.$1 == TrackerFilter.missing;

          Color activeColor = p.income;
          if (isMissingFilter) {
            activeColor = const Color(0xFFC2492F);
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => c.setTrackerFilter(item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : p.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? activeColor : p.line,
                    width: isSelected ? 1.4 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.$3,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : (isMissingFilter ? const Color(0xFFC2492F) : p.ink),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isMissingFilter ? const Color(0xFFC2492F) : p.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    PrayerTasbihController c,
    AppPalette p,
    bool isBn,
    DateTime date,
  ) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.subtract(const Duration(days: 1)).day;

    final completedCount = c.getCompletedCountForDate(dateKey);
    final isFull = completedCount == kTrackerPrayers.length;
    final missingPrayers = c.getMissingPrayerItemsForDate(dateKey);

    final dayName = isBn ? DateFormat('EEEE', 'bn').format(date) : DateFormat('EEEE').format(date);
    final dateFormatted = isBn ? DateFormat('d MMMM yyyy', 'bn').format(date) : DateFormat('d MMMM yyyy').format(date);

    String formatCount(int cnt) => isBn ? NumberFormat('', 'bn').format(cnt) : cnt.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? p.income.withOpacity(0.6)
              : (isFull ? p.income.withOpacity(0.3) : p.line),
          width: isToday ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$dayName, $dateFormatted',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: p.ink,
                            ),
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.income,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Today'.tr,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ] else if (isYesterday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.mute.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Yesterday'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: p.mute,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Missing prayers alert line
                    if (!isFull && missingPrayers.isNotEmpty) ...[
                      Text(
                        '${'Missing:'.tr} ${missingPrayers.map((pItem) => isBn ? pItem.nameBn : pItem.nameEn).join(', ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC2492F),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'All 5 prayers completed!'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: p.income,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isFull
                      ? p.income.withOpacity(0.12)
                      : (completedCount > 0 ? const Color(0xFFF39C12).withOpacity(0.12) : const Color(0xFFC2492F).withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isFull
                        ? p.income.withOpacity(0.3)
                        : (completedCount > 0 ? const Color(0xFFF39C12).withOpacity(0.3) : const Color(0xFFC2492F).withOpacity(0.3)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFull ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 13,
                      color: isFull
                          ? p.income
                          : (completedCount > 0 ? const Color(0xFFD68910) : const Color(0xFFC2492F)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${formatCount(completedCount)}/৫ ${'Completed'.tr}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isFull
                            ? p.income
                            : (completedCount > 0 ? const Color(0xFFD68910) : const Color(0xFFC2492F)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5 Interactive Waqt Buttons Row
          Row(
            children: kTrackerPrayers.map((prayer) {
              final isDone = c.isPrayerCompleted(dateKey, prayer.key);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        c.togglePrayer(dateKey, prayer.key);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isDone ? p.income : p.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDone ? p.income : p.line,
                            width: isDone ? 1.2 : 1.0,
                          ),
                          boxShadow: isDone
                              ? [
                                  BoxShadow(
                                    color: p.income.withOpacity(0.22),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDone ? Icons.check_rounded : prayer.icon,
                              size: 16,
                              color: isDone ? Colors.white : p.mute,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isBn ? prayer.nameBn : prayer.nameEn,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDone ? Colors.white : p.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (!isFull) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  c.setDayAllPrayers(dateKey, true);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_all_rounded, size: 14, color: p.income),
                      const SizedBox(width: 4),
                      Text(
                        'Mark All 5'.tr,
                        style: TextStyle(
                          fontSize: 11.5,
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
        ],
      ),
    );
  }

  Widget _buildEmptyState(PrayerTasbihController c, AppPalette p) {
    final isMissing = c.selectedTrackerFilter == TrackerFilter.missing;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isMissing ? p.income : p.mute).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isMissing ? Icons.celebration_rounded : Icons.info_outline_rounded,
                size: 36,
                color: isMissing ? p.income : p.mute,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              isMissing
                  ? 'MashaAllah! No Missed Prayers!'.tr
                  : 'No Prayer Records Found'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isMissing
                  ? 'All prayers for the selected days were completed successfully.'.tr
                  : 'Tap the prayer buttons above to start tracking your daily prayers.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.mute, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
