import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../data/models/tasbih_entry_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/prayer_tasbih_controller.dart';

class TasbihHistoryView extends StatelessWidget {
  const TasbihHistoryView({super.key});

  static String formatDateLabel(String dateStr, bool isBn) {
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(parsed.year, parsed.month, parsed.day);
      final diffDays = today.difference(target).inDays;

      final formattedDate = isBn
          ? DateFormat('d MMMM yyyy', 'bn').format(parsed)
          : DateFormat('d MMMM yyyy').format(parsed);

      if (diffDays == 0) {
        return '${'Today'.tr} ($formattedDate)';
      } else if (diffDays == 1) {
        return '${'Yesterday'.tr} ($formattedDate)';
      } else {
        return formattedDate;
      }
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';
    final searchCtrl = TextEditingController();
    final searchQuery = ''.obs;
    final selectedTab = 0.obs; // 0 = Zikir Overview, 1 = Daily History Logs

    return GetBuilder<PrayerTasbihController>(
      init: Get.isRegistered<PrayerTasbihController>()
          ? Get.find<PrayerTasbihController>()
          : PrayerTasbihController(),
      builder: (c) {
        final totalCount = c.getTotalFilteredCount();
        final maxCount = c.getMaxZikirCount();

        return Scaffold(
          backgroundColor: p.bg,
          appBar: CustomAppBar(
            title: 'Tasbih History'.tr,
            showBackButton: true,
            showLanguageToggle: false,
            showThemeToggle: false,
            showLogout: false,
            actions: [
              // Count visibility toggle
              IconButton(
                icon: Icon(
                  c.isCountHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20,
                  color: c.isCountHidden ? p.mute : p.income,
                ),
                tooltip: c.isCountHidden ? 'Show count'.tr : 'Hide count'.tr,
                onPressed: c.toggleCountVisibility,
              ),
              // Shortcut to Tasbih Counter
              IconButton(
                icon: Icon(Icons.fingerprint_rounded, size: 22, color: p.income),
                tooltip: 'Digital Tasbih'.tr,
                onPressed: () {
                  if (Get.previousRoute == AppRoutes.tasbihCounter) {
                    Get.back();
                  } else {
                    Get.toNamed(AppRoutes.tasbihCounter);
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: Obx(() {
              return Column(
                children: [
                  // Top View Switcher (Zikir Overview vs Daily History Logs)
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => selectedTab.value = 0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 7.5),
                              decoration: BoxDecoration(
                                color: selectedTab.value == 0 ? p.income : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.format_list_bulleted_rounded,
                                    size: 14,
                                    color: selectedTab.value == 0 ? Colors.white : p.mute,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Zikir Overview'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: selectedTab.value == 0 ? Colors.white : p.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => selectedTab.value = 1,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 7.5),
                              decoration: BoxDecoration(
                                color: selectedTab.value == 1 ? p.income : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_sync_rounded,
                                    size: 14,
                                    color: selectedTab.value == 1 ? Colors.white : p.mute,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Daily History Logs'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: selectedTab.value == 1 ? Colors.white : p.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Body
                  Expanded(
                    child: selectedTab.value == 0
                        ? _buildZikirOverviewTab(
                            context: context,
                            c: c,
                            p: p,
                            isBn: isBn,
                            searchCtrl: searchCtrl,
                            searchQuery: searchQuery,
                            totalCount: totalCount,
                            maxCount: maxCount,
                          )
                        : _buildDailyHistoryLogsTab(
                            context: context,
                            c: c,
                            p: p,
                            isBn: isBn,
                            onSelectDate: (dateKey) {
                              c.selectHistoryDate(dateKey);
                              selectedTab.value = 0;
                            },
                          ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  // --- Tab 0: Zikir Overview with Current Date & Filters ---
  Widget _buildZikirOverviewTab({
    required BuildContext context,
    required PrayerTasbihController c,
    required AppPalette p,
    required bool isBn,
    required TextEditingController searchCtrl,
    required RxString searchQuery,
    required int totalCount,
    required int maxCount,
  }) {
    final q = searchQuery.value;
    final list = c.getSortedZikirsByCount().where((item) {
      if (q.isEmpty) return true;
      return item.titleBn.toLowerCase().contains(q) ||
          item.titleEn.toLowerCase().contains(q) ||
          item.arabic.contains(q) ||
          item.meaningBn.toLowerCase().contains(q);
    }).toList();

    return CustomScrollView(
      slivers: [
        // Sliver 1: Compact Filter & Search Panel
        SliverToBoxAdapter(
          child: Container(
            color: p.card,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Box with Total Counter Badge & Date Picker Button
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (v) => searchQuery.value = v.trim().toLowerCase(),
                          decoration: InputDecoration(
                            hintText: 'Search zikir or meaning...'.tr,
                            hintStyle: TextStyle(fontSize: 12.5, color: p.mute),
                            prefixIcon: Icon(Icons.search, size: 17, color: p.mute),
                            suffixIcon: searchQuery.value.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      searchCtrl.clear();
                                      searchQuery.value = '';
                                    },
                                    child: Icon(Icons.clear, size: 16, color: p.mute),
                                  )
                                : null,
                            isDense: true,
                            filled: true,
                            fillColor: p.bg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: p.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: p.line),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Calendar button to pick any specific date
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          final dateStr = DateFormat('yyyy-MM-dd').format(picked);
                          c.selectHistoryDate(dateStr);
                        }
                      },
                      child: Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: c.selectedHistoryDate != null
                              ? p.income
                              : p.income.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: c.selectedHistoryDate != null
                                ? p.income
                                : p.income.withOpacity(0.25),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: c.selectedHistoryDate != null ? Colors.white : p.income,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Total Recitations Badge
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.income.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.query_stats_rounded, size: 16, color: p.income),
                          const SizedBox(width: 4),
                          Text(
                            c.isCountHidden
                                ? '***'
                                : '${NumberFormat('#,###').format(totalCount)} ${'Times'.tr}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: p.income,
                              letterSpacing: c.isCountHidden ? 2 : 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Active Specific Date Banner (if chosen via calendar)
                if (c.selectedHistoryDate != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.income.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: p.income.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_available_rounded, size: 15, color: p.income),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${'Date:'.tr} ${formatDateLabel(c.selectedHistoryDate!, isBn)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: p.income,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => c.selectHistoryDate(null),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Reset Date'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: p.mute,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.close_rounded, size: 13, color: p.mute),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Time Filter Pills (Horizontal scrollable)
                  SizedBox(
                    height: 30,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: TasbihTimeFilter.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (ctx, i) {
                        final filter = TasbihTimeFilter.values[i];
                        final isSelected = c.selectedTimeFilter == filter;
                        return InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            c.selectHistoryDate(null);
                            c.setTimeFilter(filter);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? p.income : p.bg,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: isSelected ? p.income : p.line),
                            ),
                            child: Center(
                              child: Text(
                                c.getTimeFilterName(filter),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : p.ink,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 6),

                // Category Filter Chips (Horizontal scrollable)
                SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ZikirCategory.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) {
                      final cat = ZikirCategory.values[i];
                      final isSelected = c.selectedCategoryFilter == cat;
                      return InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () => c.setCategoryFilter(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? p.income : p.bg,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isSelected ? p.income : p.line),
                          ),
                          child: Center(
                            child: Text(
                              c.getCategoryName(cat),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : p.ink,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sliver 2: Filter Summary Sub-header
        SliverToBoxAdapter(
          child: Container(
            color: p.bg,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tap a zikir to start counting'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.mute),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${list.length} ${'Items'.tr}',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.income),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Sliver 3: Zikir Items List
        if (list.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No zikir found'.tr,
                style: TextStyle(color: p.mute),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final item = list[i];
                  final count = c.getZikirCount(item.id);
                  final isSelected = item.id == c.selectedZikir.id;
                  final ratio = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          c.selectZikir(item);
                          if (Get.previousRoute == AppRoutes.tasbihCounter) {
                            Get.back();
                          } else {
                            Get.toNamed(AppRoutes.tasbihCounter);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? p.income.withOpacity(0.08) : p.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? p.income : p.line,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: p.income.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      c.getCategoryName(item.category),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: p.income,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isBn ? item.titleBn : item.titleEn,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? p.income : p.ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Recitation count badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: count > 0 ? p.income : p.bg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: count > 0 ? p.income : p.line,
                                      ),
                                    ),
                                    child: Text(
                                      c.isCountHidden ? '***' : '$count ${'Times'.tr}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: count > 0 ? Colors.white : p.mute,
                                        letterSpacing: c.isCountHidden ? 2 : 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Arabic text (increased for clear tashkeel / harakat legibility)
                              Text(
                                item.arabic,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: p.income,
                                  height: 1.35,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Relative progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 5,
                                  backgroundColor: p.line.withOpacity(0.5),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    count > 0 ? p.income : p.mute.withOpacity(0.2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              // Meaning
                              Text(
                                isBn ? item.meaningBn : item.meaningEn,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: p.mute,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: list.length,
              ),
            ),
          ),
      ],
    );
  }

  // --- Tab 1: Day-Wise Chronological History Logs (Firebase Firestore) ---
  Widget _buildDailyHistoryLogsTab({
    required BuildContext context,
    required PrayerTasbihController c,
    required AppPalette p,
    required bool isBn,
    required ValueChanged<String> onSelectDate,
  }) {
    final grouped = c.groupedHistoryEntries;
    final dateKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: c.refreshHistoryFromFirestore,
      color: p.income,
      child: CustomScrollView(
        slivers: [
          // Header info banner
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: p.income.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.cloud_done_rounded, size: 18, color: p.income),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Synced with Firebase'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                        ),
                        Text(
                          'History from Firebase'.tr,
                          style: TextStyle(fontSize: 11, color: p.mute),
                        ),
                      ],
                    ),
                  ),
                  if (c.isSyncingHistory)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: p.income),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, size: 20, color: p.income),
                      tooltip: 'Refresh'.tr,
                      onPressed: c.refreshHistoryFromFirestore,
                    ),
                ],
              ),
            ),
          ),

          if (dateKeys.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 48, color: p.mute.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'No history recorded yet'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start counting tasbih today to record day-wise entries in Firebase.'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: p.mute),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final dateKey = dateKeys[i];
                    final entries = grouped[dateKey] ?? <TasbihEntryModel>[];
                    final dayTotal = c.dayTotals[dateKey] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.line),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Date Header Row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 14, color: p.income),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    formatDateLabel(dateKey, isBn),
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: p.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: p.income.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: p.income.withOpacity(0.25)),
                                  ),
                                  child: Text(
                                    c.isCountHidden
                                        ? '***'
                                        : '${'Total'.tr}: $dayTotal ${'Times'.tr}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: p.income,
                                      letterSpacing: c.isCountHidden ? 2 : 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: p.line),

                          // List of zikirs for this date
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => Divider(height: 10, color: p.line.withOpacity(0.5)),
                            itemBuilder: (context, idx) {
                              final entry = entries[idx];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isBn ? entry.jikirName : entry.jikirNameEn,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: p.ink,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (entry.arabic.isNotEmpty) ...[
                                          const SizedBox(height: 1),
                                          Text(
                                            entry.arabic,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: p.income,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: entry.jikirCount > 0 ? p.income : p.bg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: entry.jikirCount > 0 ? p.income : p.line,
                                      ),
                                    ),
                                    child: Text(
                                      c.isCountHidden ? '***' : '${entry.jikirCount} ${'Times'.tr}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: entry.jikirCount > 0 ? Colors.white : p.mute,
                                        letterSpacing: c.isCountHidden ? 2 : 0,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          // Quick inspect in Zikir Overview
                          InkWell(
                            onTap: () => onSelectDate(dateKey),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: p.bg,
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.filter_alt_outlined, size: 13, color: p.income),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${'View History'.tr} (${formatDateLabel(dateKey, isBn)})',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: p.income,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: dateKeys.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
