import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../data/models/tasbih_entry_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/prayer_tasbih_controller.dart';

class TasbihHistoryView extends StatefulWidget {
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
  State<TasbihHistoryView> createState() => _TasbihHistoryViewState();
}

class _TasbihHistoryViewState extends State<TasbihHistoryView> {
  late final TextEditingController _searchCtrl;
  final RxString _searchQuery = ''.obs;
  final RxInt _selectedTab = 0.obs; // 0 = Zikir Overview, 1 = Daily History Logs

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String formatDateLabel(String dateStr, bool isBn) =>
      TasbihHistoryView.formatDateLabel(dateStr, isBn);

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';

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
                  if (Get.previousRoute == AppRoutes.tasbihCounter ||
                      Get.previousRoute == AppRoutes.prayerAndTasbih) {
                    c.setActiveTab(1);
                    Get.back();
                  } else {
                    c.setActiveTab(1);
                    Get.toNamed(AppRoutes.prayerAndTasbih);
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
                            onTap: () => _selectedTab.value = 0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 9.5),
                              decoration: BoxDecoration(
                                gradient: _selectedTab.value == 0
                                    ? const LinearGradient(
                                        colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _selectedTab.value == 0
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withOpacity(0.30),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.format_list_bulleted_rounded,
                                    size: 17,
                                    color: _selectedTab.value == 0 ? Colors.white : p.mute,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Zikir Overview'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedTab.value == 0 ? Colors.white : p.ink,
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
                            onTap: () => _selectedTab.value = 1,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 9.5),
                              decoration: BoxDecoration(
                                gradient: _selectedTab.value == 1
                                    ? const LinearGradient(
                                        colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: _selectedTab.value == 1
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF10B981).withOpacity(0.30),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_sync_rounded,
                                    size: 17,
                                    color: _selectedTab.value == 1 ? Colors.white : p.mute,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Daily History Logs'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedTab.value == 1 ? Colors.white : p.ink,
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
                    child: _selectedTab.value == 0
                        ? _buildZikirOverviewTab(
                            context: context,
                            c: c,
                            p: p,
                            isBn: isBn,
                            searchCtrl: _searchCtrl,
                            searchQuery: _searchQuery,
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
                              _selectedTab.value = 0;
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
                        height: 44,
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (v) => searchQuery.value = v.trim().toLowerCase(),
                          style: TextStyle(fontSize: 14.5, color: p.ink),
                          decoration: InputDecoration(
                            hintText: 'Search zikir or meaning...'.tr,
                            hintStyle: TextStyle(fontSize: 14.5, color: p.mute),
                            prefixIcon: Icon(Icons.search, size: 20, color: p.mute),
                            suffixIcon: searchQuery.value.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      searchCtrl.clear();
                                      searchQuery.value = '';
                                    },
                                    child: Icon(Icons.clear, size: 18, color: p.mute),
                                  )
                                : null,
                            isDense: true,
                            filled: true,
                            fillColor: p.bg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        height: 44,
                        width: 44,
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
                            size: 20,
                            color: c.selectedHistoryDate != null ? Colors.white : p.income,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Total Recitations Badge
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.income.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.query_stats_rounded, size: 18, color: p.income),
                          const SizedBox(width: 6),
                          Text(
                            c.isCountHidden
                                ? '***'
                                : '${NumberFormat('#,###').format(totalCount)} ${'Times'.tr}',
                            style: TextStyle(
                              fontSize: 14.5,
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
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: p.income.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: p.income.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_available_rounded, size: 16, color: p.income),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${'Date:'.tr} ${formatDateLabel(c.selectedHistoryDate!, isBn)}',
                            style: TextStyle(
                              fontSize: 14,
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: p.mute,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(Icons.close_rounded, size: 15, color: p.mute),
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
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: TasbihTimeFilter.values.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (ctx, i) {
                        final filter = TasbihTimeFilter.values[i];
                        final isSelected = c.selectedTimeFilter == filter;
                        return InkWell(
                          borderRadius: BorderRadius.circular(19),
                          onTap: () {
                            c.selectHistoryDate(null);
                            c.setTimeFilter(filter);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? p.income : p.bg,
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(color: isSelected ? p.income : p.line),
                            ),
                            child: Center(
                              child: Text(
                                c.getTimeFilterName(filter),
                                style: TextStyle(
                                  fontSize: 13.5,
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
                const SizedBox(height: 7),

                // Category Filter Chips (Horizontal scrollable)
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: ZikirCategory.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) {
                      final cat = ZikirCategory.values[i];
                      final isSelected = c.selectedCategoryFilter == cat;
                      return InkWell(
                        borderRadius: BorderRadius.circular(19),
                        onTap: () => c.setCategoryFilter(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? p.income : p.bg,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(color: isSelected ? p.income : p.line),
                          ),
                          child: Center(
                            child: Text(
                              c.getCategoryName(cat),
                              style: TextStyle(
                                fontSize: 13.5,
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
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: p.mute),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${list.length} ${'Items'.tr}',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: p.income),
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
                          if (Get.previousRoute == AppRoutes.tasbihCounter ||
                              Get.previousRoute == AppRoutes.prayerAndTasbih) {
                            c.setActiveTab(1);
                            Get.back();
                          } else {
                            c.setActiveTab(1);
                            Get.toNamed(AppRoutes.prayerAndTasbih);
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: p.income.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      c.getCategoryName(item.category),
                                      style: TextStyle(
                                        fontSize: 12.5,
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
                                        fontSize: 16.5,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                    decoration: BoxDecoration(
                                      gradient: count > 0
                                          ? const LinearGradient(
                                              colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: count > 0 ? null : p.bg,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: count > 0
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF10B981).withOpacity(0.30),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                      border: count > 0 ? null : Border.all(color: p.line),
                                    ),
                                    child: Text(
                                      c.isCountHidden ? '***' : '$count ${'Times'.tr}',
                                      style: TextStyle(
                                        fontSize: 15,
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
                                  fontSize: 22,
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
                                  fontSize: 13.5,
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

  void _showMonthYearPicker(
    BuildContext context,
    PrayerTasbihController c,
    AppPalette p,
    bool isBn,
  ) {
    final now = DateTime.now();
    int tempYear = c.selectedHistoryMonth?.year ?? now.year;
    int? tempMonth = c.selectedHistoryMonth?.month;

    // Available years: from 3 years ago to current year
    final years = List.generate(4, (i) => now.year - 3 + i).reversed.toList();

    const monthNamesEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const monthNamesBn = [
      'জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'
    ];

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setState) {
          final isAllTime = tempMonth == null;

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
                  // Drag Handle
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
                        'Filter by Month & Year'.tr,
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close_rounded, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // "All Time History" quick button
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      c.setHistoryMonth(null);
                      Get.back();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                      decoration: BoxDecoration(
                        color: isAllTime ? p.income : p.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isAllTime ? p.income : p.line),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.all_inclusive_rounded,
                            size: 19,
                            color: isAllTime ? Colors.white : p.income,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'All Time History'.tr,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isAllTime ? Colors.white : p.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Year selector row
                  Text(
                    'Select Year'.tr,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.mute),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: years.map((y) {
                        final isSel = !isAllTime && y == tempYear;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setState(() {
                                tempYear = y;
                                tempMonth ??= now.month;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel ? p.income : p.bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSel ? p.income : p.line),
                              ),
                              child: Text(
                                isBn ? NumberFormat('', 'bn').format(y) : '$y',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                                  color: isSel ? Colors.white : p.ink,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Month selector Grid
                  Text(
                    'Select Month'.tr,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.mute),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.1,
                    ),
                    itemCount: 12,
                    itemBuilder: (ctx, i) {
                      final monthIndex = i + 1;
                      final isFuture = tempYear == now.year && monthIndex > now.month;
                      final isSel = !isAllTime && tempMonth == monthIndex;
                      final name = isBn ? monthNamesBn[i] : monthNamesEn[i];

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: isFuture
                            ? null
                            : () {
                                c.setHistoryMonth(DateTime(tempYear, monthIndex));
                                Get.back();
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSel
                                ? p.income
                                : isFuture
                                    ? p.bg.withOpacity(0.4)
                                    : p.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel
                                  ? p.income
                                  : isFuture
                                      ? p.line.withOpacity(0.4)
                                      : p.line,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                color: isSel
                                    ? Colors.white
                                    : isFuture
                                        ? p.mute.withOpacity(0.4)
                                        : p.ink,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
          // Month & Year Filter Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              child: Row(
                children: [
                  // Prev Month Button
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: c.previousHistoryMonth,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.line),
                      ),
                      child: Icon(Icons.chevron_left_rounded, size: 24, color: p.ink),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Center Month & Year Tappable Button
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _showMonthYearPicker(context, c, p, isBn),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: p.bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month_rounded, size: 19, color: p.income),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                c.selectedHistoryMonth != null
                                    ? (isBn
                                        ? DateFormat('MMMM yyyy', 'bn').format(c.selectedHistoryMonth!)
                                        : DateFormat('MMMM yyyy').format(c.selectedHistoryMonth!))
                                    : 'All Time History'.tr,
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
                            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: p.mute),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Next Month Button
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: (c.selectedHistoryMonth != null &&
                            (c.selectedHistoryMonth!.year > DateTime.now().year ||
                             (c.selectedHistoryMonth!.year == DateTime.now().year &&
                              c.selectedHistoryMonth!.month >= DateTime.now().month)))
                        ? null
                        : c.nextHistoryMonth,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: p.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.line),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 24,
                        color: (c.selectedHistoryMonth != null &&
                                (c.selectedHistoryMonth!.year > DateTime.now().year ||
                                 (c.selectedHistoryMonth!.year == DateTime.now().year &&
                                  c.selectedHistoryMonth!.month >= DateTime.now().month)))
                            ? p.mute.withOpacity(0.3)
                            : p.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Total Recitations Badge for selected period
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    decoration: BoxDecoration(
                      color: p.income.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.income.withOpacity(0.25)),
                    ),
                    child: Center(
                      child: Text(
                        c.isCountHidden
                            ? '***'
                            : '${NumberFormat('#,###').format(c.selectedMonthTotal)} ${'Times'.tr}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: p.income,
                          letterSpacing: c.isCountHidden ? 2 : 0,
                        ),
                      ),
                    ),
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
                        c.selectedHistoryMonth != null
                            ? '${'No history recorded in'.tr} ${isBn ? DateFormat('MMMM yyyy', 'bn').format(c.selectedHistoryMonth!) : DateFormat('MMMM yyyy').format(c.selectedHistoryMonth!)}'
                            : 'No history recorded yet'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.ink),
                      ),
                      const SizedBox(height: 12),
                      if (c.selectedHistoryMonth != null)
                        OutlinedButton.icon(
                          onPressed: () => c.setHistoryMonth(null),
                          icon: const Icon(Icons.all_inclusive_rounded, size: 16),
                          label: Text('View All Time History'.tr),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: p.income,
                            side: BorderSide(color: p.income.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
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
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 16, color: p.income),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    formatDateLabel(dateKey, isBn),
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: p.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: p.income.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(color: p.income.withOpacity(0.25)),
                                  ),
                                  child: Text(
                                    c.isCountHidden
                                        ? '***'
                                        : '${'Total'.tr}: $dayTotal ${'Times'.tr}',
                                    style: TextStyle(
                                      fontSize: 12.5,
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => Divider(height: 12, color: p.line.withOpacity(0.5)),
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
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w700,
                                            color: p.ink,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (entry.arabic.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            entry.arabic,
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w700,
                                              color: p.income,
                                              height: 1.35,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                    decoration: BoxDecoration(
                                      gradient: entry.jikirCount > 0
                                          ? const LinearGradient(
                                              colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: entry.jikirCount > 0 ? null : p.bg,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: entry.jikirCount > 0
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF10B981).withOpacity(0.30),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                      border: entry.jikirCount > 0 ? null : Border.all(color: p.line),
                                    ),
                                    child: Text(
                                      c.isCountHidden ? '***' : '${entry.jikirCount} ${'Times'.tr}',
                                      style: TextStyle(
                                        fontSize: 15,
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
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: p.bg,
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.filter_alt_outlined, size: 15, color: p.income),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      '${'View History'.tr} (${formatDateLabel(dateKey, isBn)})',
                                      style: TextStyle(
                                        fontSize: 13,
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
