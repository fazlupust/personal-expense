import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/prayer_tasbih_controller.dart';

class TasbihCounterView extends StatelessWidget {
  final bool isEmbedded;
  const TasbihCounterView({super.key, this.isEmbedded = false});

  void showAnalyticsSheet(BuildContext context, PrayerTasbihController c, AppPalette p) {
    _showTasbihAnalyticsSheet(context, c, p);
  }

  void _showResetConfirmDialog(BuildContext context, PrayerTasbihController c, AppPalette p) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: p.expense.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.refresh_rounded, color: p.expense, size: 26),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Reset Tasbih Counter?'.tr,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This will reset your current count and cycles for this zikir.'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.mute, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.ink,
                        side: BorderSide(color: p.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Get.back();
                        c.reset();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: p.expense,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Reset'.tr),
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

  void _showTargetSelector(BuildContext context, PrayerTasbihController c, AppPalette p) {
    const targets = [33, 100, 1000, 0];
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: p.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: p.mute.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Select Target Count'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: targets.map((t) {
                final isSelected = c.targetCount == t;
                final label = t == 0 ? '∞ Unlimited'.tr : '$t ${'Times'.tr}';
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Get.back();
                    c.setTarget(t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? p.income : p.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? p.income : p.line),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : p.ink,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showTasbihAnalyticsSheet(BuildContext context, PrayerTasbihController c, AppPalette p) {
    final isBn = Get.locale?.languageCode == 'bn';

    Get.bottomSheet(
      GetBuilder<PrayerTasbihController>(
        builder: (ctrl) {
          final sortedZikirs = ctrl.getSortedZikirsByCount();
          final totalCount = ctrl.getTotalFilteredCount();
          final maxCount = ctrl.getMaxZikirCount();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(color: p.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: p.mute.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header with Title & Filtered Total Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.query_stats_rounded, size: 20, color: p.income),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tasbih History & Filter'.tr,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: p.ink,
                            ),
                          ),
                          Text(
                            'Recitation Statistics'.tr,
                            style: TextStyle(fontSize: 11.5, color: p.mute),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.income.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${NumberFormat('#,###').format(totalCount)} ${'Times'.tr}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: p.income,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Time Filter Section ("eim filer")
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 13, color: p.income),
                          const SizedBox(width: 5),
                          Text(
                            'Time Filter'.tr,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 4 segments: Today, This Week, This Month, All Time
                      Row(
                        children: TasbihTimeFilter.values.map((filter) {
                          final isSelected = ctrl.selectedTimeFilter == filter;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(9),
                                onTap: () => ctrl.setTimeFilter(filter),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSelected ? p.income : p.card,
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(
                                      color: isSelected ? p.income : p.line,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: p.income.withOpacity(0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      ctrl.getTimeFilterName(filter),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? Colors.white : p.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Prayer / Category Filter Section ("fyara filer")
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mosque_rounded, size: 14, color: p.income),
                          const SizedBox(width: 5),
                          Text(
                            'Prayer / Category'.tr,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Horizontal scrollable chips for Categories
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ZikirCategory.values.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (ctx, i) {
                            final cat = ZikirCategory.values[i];
                            final isSelected = ctrl.selectedCategoryFilter == cat;
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => ctrl.setCategoryFilter(cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected ? p.income : p.card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? p.income : p.line,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    ctrl.getCategoryName(cat),
                                    style: TextStyle(
                                      fontSize: 11.5,
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
                const SizedBox(height: 10),

                // List Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tap a zikir to start counting'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.mute),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${sortedZikirs.length} ${'Items'.tr}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.income),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Zikir Items List with Recitation Counters & Relative Bars
                Expanded(
                  child: sortedZikirs.isEmpty
                      ? Center(
                          child: Text(
                            'No zikir found'.tr,
                            style: TextStyle(color: p.mute),
                          ),
                        )
                      : ListView.separated(
                          itemCount: sortedZikirs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final item = sortedZikirs[i];
                            final count = ctrl.getZikirCount(item.id);
                            final isCurrentActive = item.id == ctrl.selectedZikir.id;
                            final ratio = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Get.back();
                                  ctrl.selectZikir(item);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isCurrentActive
                                        ? p.income.withOpacity(0.08)
                                        : p.bg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isCurrentActive ? p.income : p.line,
                                      width: isCurrentActive ? 1.4 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Category Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: p.income.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              ctrl.getCategoryName(item.category),
                                              style: TextStyle(
                                                fontSize: 10,
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
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: isCurrentActive ? p.income : p.ink,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // Recitation count badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: count > 0 ? p.income : p.card,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: count > 0 ? p.income : p.line,
                                              ),
                                            ),
                                            child: Text(
                                              '$count ${'Times'.tr}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: count > 0 ? Colors.white : p.mute,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Arabic snippet
                                      Text(
                                        item.arabic,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: p.income,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      // Progress bar relative to max
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
                                      const SizedBox(height: 4),
                                      // Meaning snippet
                                      Text(
                                        isBn ? item.meaningBn : item.meaningEn,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: p.mute,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  void _showAllZikirsSheet(BuildContext context, PrayerTasbihController c, AppPalette p) {
    final searchCtrl = TextEditingController();
    final isBn = Get.locale?.languageCode == 'bn';
    final query = ''.obs;
    final selectedCategory = ZikirCategory.all.obs;

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.82,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: p.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: p.mute.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.auto_stories_rounded, size: 20, color: p.income),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All Zikirs & Duas'.tr,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.income.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${c.allZikirs.length} ${'Items'.tr}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: p.income,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchCtrl,
              onChanged: (v) => query.value = v.trim().toLowerCase(),
              decoration: InputDecoration(
                hintText: 'Search zikir or meaning...'.tr,
                prefixIcon: Icon(Icons.search, size: 18, color: p.mute),
                isDense: true,
                filled: true,
                fillColor: p.bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: p.line),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Category filter chips in catalog
            SizedBox(
              height: 32,
              child: Obx(() {
                final currentCat = selectedCategory.value;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ZikirCategory.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final cat = ZikirCategory.values[i];
                    final isSel = currentCat == cat;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => selectedCategory.value = cat,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isSel ? p.income : p.bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSel ? p.income : p.line),
                        ),
                        child: Center(
                          child: Text(
                            c.getCategoryName(cat),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? Colors.white : p.ink,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() {
                final q = query.value;
                final cat = selectedCategory.value;
                final filtered = c.allZikirs.where((item) {
                  if (cat != ZikirCategory.all && item.category != cat) {
                    return false;
                  }
                  if (q.isEmpty) return true;
                  return item.titleBn.toLowerCase().contains(q) ||
                      item.titleEn.toLowerCase().contains(q) ||
                      item.arabic.contains(q) ||
                      item.meaningBn.toLowerCase().contains(q);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No zikir found'.tr, style: TextStyle(color: p.mute)),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    final isSelected = item.id == c.selectedZikir.id;
                    final todayCnt = c.getZikirTodayCount(item.id);
                    final lifetimeCnt = c.getZikirLifetimeCount(item.id);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Get.back();
                          c.selectZikir(item);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? p.income.withOpacity(0.08) : p.bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? p.income : p.line,
                              width: isSelected ? 1.4 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isBn ? item.titleBn : item.titleEn,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? p.income : p.ink,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: p.income.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.defaultTarget}x',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: p.income,
                                      ),
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    Icon(Icons.check_circle_rounded, size: 16, color: p.income),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.arabic,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: p.income,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isBn ? item.meaningBn : item.meaningEn,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: p.mute,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Recitation statistics for this zikir
                              Row(
                                children: [
                                  Icon(Icons.history_rounded, size: 13, color: p.income),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${'Today'.tr}: $todayCnt ${'Times'.tr}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: p.income,
                                    ),
                                  ),
                                  Text(
                                    ' · ',
                                    style: TextStyle(fontSize: 11, color: p.mute),
                                  ),
                                  Text(
                                    '${'All Time'.tr}: $lifetimeCnt ${'Times'.tr}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: p.mute,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return GetBuilder<PrayerTasbihController>(
      init: Get.isRegistered<PrayerTasbihController>()
          ? Get.find<PrayerTasbihController>()
          : PrayerTasbihController(),
      builder: (c) {
        final current = c.currentCount;
        final target = c.targetCount;
        final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
        final zikir = c.selectedZikir;

        final content = SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isEmbedded) ...[
                // Embedded top action bar (History/Stats, Catalog, Vibration, Reset)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.query_stats_rounded, size: 20, color: p.income),
                      tooltip: 'Tasbih History & Filter'.tr,
                      onPressed: () => _showTasbihAnalyticsSheet(context, c, p),
                    ),
                    IconButton(
                      icon: Icon(Icons.auto_stories_rounded, size: 20, color: p.income),
                      tooltip: 'All Zikirs & Duas'.tr,
                      onPressed: () => _showAllZikirsSheet(context, c, p),
                    ),
                    IconButton(
                      icon: Icon(
                        c.isVibrationEnabled ? Icons.vibration_rounded : Icons.smartphone_rounded,
                        size: 20,
                        color: c.isVibrationEnabled ? p.income : p.mute,
                      ),
                      tooltip: 'Vibration'.tr,
                      onPressed: c.toggleVibration,
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, size: 20, color: p.expense),
                      tooltip: 'Reset'.tr,
                      onPressed: () => _showResetConfirmDialog(context, c, p),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
                  // Zikir Selector Row (Browse All Button + Horizontal List)
                  Row(
                    children: [
                      // Browse All Button
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showAllZikirsSheet(context, c, p),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: p.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: p.income.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_stories_rounded, size: 16, color: p.income),
                              const SizedBox(width: 4),
                              Text(
                                'All'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: p.income,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Horizontal Scrollable Chips
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: c.allZikirs.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (ctx, i) {
                              final item = c.allZikirs[i];
                              final isSelected = item.id == zikir.id;
                              final isBn = Get.locale?.languageCode == 'bn';
                              final title = isBn ? item.titleBn : item.titleEn;

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => c.selectZikir(item),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? p.income : p.card,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? p.income : p.line,
                                        width: 1.2,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: p.income.withOpacity(0.28),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isSelected ? Colors.white : p.ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Selected Zikir Card (Arabic, Pronunciation, Meaning, Virtue)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Arabic
                        Text(
                          zikir.arabic,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: p.income,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Bengali Pronunciation
                        Text(
                          zikir.titleBn,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Meaning
                        Text(
                          Get.locale?.languageCode == 'bn' ? zikir.meaningBn : zikir.meaningEn,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: p.mute,
                            height: 1.3,
                          ),
                        ),
                        if (zikir.benefitBn != null && zikir.benefitBn!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.income.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stars_rounded, size: 14, color: p.income),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    zikir.benefitBn!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: p.income,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Per-Zikir Recitation Count & Filter Shortcut
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _showTasbihAnalyticsSheet(context, c, p),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: p.income.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: p.income.withOpacity(0.25)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.query_stats_rounded, size: 16, color: p.income),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${'This Zikir Recited'.tr}: ${c.getZikirTodayCount(zikir.id)} ${'Times'.tr} (${'Today'.tr}) · ${c.getZikirLifetimeCount(zikir.id)} ${'Times'.tr} (${'All Time'.tr})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: p.income,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded, size: 16, color: p.income),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Giant Interactive Digital Tasbih Counter Dial
                  Center(
                    child: GestureDetector(
                      onTap: c.increment,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.card,
                          boxShadow: [
                            BoxShadow(
                              color: p.income.withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Circular Progress Ring
                            SizedBox(
                              width: 204,
                              height: 204,
                              child: CircularProgressIndicator(
                                value: target > 0 ? progress : 1.0,
                                strokeWidth: 10,
                                backgroundColor: p.line,
                                valueColor: AlwaysStoppedAnimation<Color>(p.income),
                                strokeCap: StrokeCap.round,
                              ),
                            ),

                            // Inside Dial Info & Touch Surface
                            Container(
                              width: 175,
                              height: 175,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    p.income.withOpacity(0.12),
                                    p.card,
                                  ],
                                  center: Alignment.center,
                                  radius: 0.8,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Target Badge (Tap to change target)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => _showTargetSelector(context, c, p),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: p.income.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            target > 0 ? 'Target: $target'.tr : 'Target: ∞'.tr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: p.income,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Icon(Icons.arrow_drop_down, size: 14, color: p.income),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Huge Counter Number
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        NumberFormat('#,###').format(current),
                                        style: TextStyle(
                                          fontSize: 54,
                                          fontWeight: FontWeight.w900,
                                          color: p.ink,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Completed cycles indicator
                                  if (c.completedCycles > 0) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${'Round:'.tr} ${c.completedCycles}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: p.income,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),

                                  // Tap Hint
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.touch_app_rounded, size: 13, color: p.mute),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Tap to count'.tr,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: p.mute,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Action Buttons (Undo -1, Reset, Target switch)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Undo -1
                      IconButton.filledTonal(
                        onPressed: current > 0 ? c.decrement : null,
                        icon: const Icon(Icons.remove, size: 20),
                        tooltip: 'Undo -1'.tr,
                        style: IconButton.styleFrom(
                          backgroundColor: p.card,
                          foregroundColor: p.ink,
                          side: BorderSide(color: p.line),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Large Tap CTA button
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: c.increment,
                          icon: const Icon(Icons.add_rounded, size: 22),
                          label: Text(
                            '+1 ${'Count'.tr}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: p.income,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Reset
                      IconButton.filledTonal(
                        onPressed: () => _showResetConfirmDialog(context, c, p),
                        icon: const Icon(Icons.restart_alt_rounded, size: 20),
                        tooltip: 'Reset'.tr,
                        style: IconButton.styleFrom(
                          backgroundColor: p.card,
                          foregroundColor: p.expense,
                          side: BorderSide(color: p.line),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Today & Lifetime Statistics Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: p.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: p.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.today_rounded, size: 16, color: p.income),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Today\'s Count'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: p.mute,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                NumberFormat('#,###').format(c.todayTotal),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: p.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: p.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: p.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.all_inclusive_rounded, size: 16, color: p.income),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Lifetime Total'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: p.mute,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                NumberFormat('#,###').format(c.lifetimeTotal),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: p.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Tasbih History & Filter Action Card
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showTasbihAnalyticsSheet(context, c, p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.income.withOpacity(0.3)),
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: p.income.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.query_stats_rounded, size: 20, color: p.income),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tasbih History & Filter'.tr,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Recitation Statistics'.tr,
                                  style: TextStyle(fontSize: 11, color: p.mute),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: p.income),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick switch to Prayer Times
                  OutlinedButton.icon(
                    onPressed: () {
                      if (isEmbedded) {
                        c.setActiveTab(0);
                      } else {
                        Get.back();
                      }
                    },
                    icon: Icon(Icons.access_time_filled_rounded, size: 18, color: p.income),
                    label: Text(
                      'View Prayer Times Schedule'.tr,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.income),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: p.income.withOpacity(0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );

        if (isEmbedded) {
          return content;
        }

        return Scaffold(
          backgroundColor: p.bg,
          appBar: CustomAppBar(
            title: 'Digital Tasbih'.tr,
            showBackButton: true,
            actions: [
              // Tasbih History & Analytics
              IconButton(
                icon: Icon(Icons.query_stats_rounded, size: 22, color: p.income),
                tooltip: 'Tasbih History & Filter'.tr,
                onPressed: () => _showTasbihAnalyticsSheet(context, c, p),
              ),
              // All Zikirs Catalog Sheet
              IconButton(
                icon: Icon(Icons.auto_stories_rounded, size: 20, color: p.income),
                tooltip: 'All Zikirs & Duas'.tr,
                onPressed: () => _showAllZikirsSheet(context, c, p),
              ),
              // Vibration toggle
              IconButton(
                icon: Icon(
                  c.isVibrationEnabled ? Icons.vibration_rounded : Icons.smartphone_rounded,
                  size: 20,
                  color: c.isVibrationEnabled ? p.income : p.mute,
                ),
                tooltip: 'Vibration'.tr,
                onPressed: c.toggleVibration,
              ),
              // Reset button
              IconButton(
                icon: Icon(Icons.refresh_rounded, size: 22, color: p.expense),
                tooltip: 'Reset'.tr,
                onPressed: () => _showResetConfirmDialog(context, c, p),
              ),
            ],
          ),
          body: SafeArea(child: content),
        );
      },
    );
  }
}
