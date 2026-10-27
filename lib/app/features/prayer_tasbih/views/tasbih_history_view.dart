import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../routes/app_routes.dart';
import '../controllers/prayer_tasbih_controller.dart';

class TasbihHistoryView extends StatelessWidget {
  const TasbihHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';
    final searchQuery = ''.obs;

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
            title: 'Tasbih History & Filter'.tr,
            showBackButton: true,
            actions: [
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
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Filter Controls Section (Summary card, Time filter, Category chips, Search)
                Container(
                  color: p.card,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Overview Summary Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: p.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: p.income.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.query_stats_rounded, size: 22, color: p.income),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recitation Statistics'.tr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: p.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${c.getTimeFilterName(c.selectedTimeFilter)} · ${c.getCategoryName(c.selectedCategoryFilter)}',
                                    style: TextStyle(fontSize: 11.5, color: p.mute),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: p.income.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: p.income.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${NumberFormat('#,###').format(totalCount)} ${'Times'.tr}',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: p.income,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Time Filter Segment ("eim filer")
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
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: p.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          children: TasbihTimeFilter.values.map((filter) {
                            final isSelected = c.selectedTimeFilter == filter;
                            return Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(9),
                                onTap: () => c.setTimeFilter(filter),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? p.income : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: p.income.withOpacity(0.28),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      c.getTimeFilterName(filter),
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
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Prayer / Category Filter Section ("fyara filer")
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
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ZikirCategory.values.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (ctx, i) {
                            final cat = ZikirCategory.values[i];
                            final isSelected = c.selectedCategoryFilter == cat;

                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => c.setCategoryFilter(cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? p.income : p.bg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? p.income : p.line,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    c.getCategoryName(cat),
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
                      const SizedBox(height: 10),

                      // Search Box for Zikirs
                      TextField(
                        onChanged: (v) => searchQuery.value = v.trim().toLowerCase(),
                        decoration: InputDecoration(
                          hintText: 'Search zikir or meaning...'.tr,
                          prefixIcon: Icon(Icons.search, size: 18, color: p.mute),
                          isDense: true,
                          filled: true,
                          fillColor: p.bg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    ],
                  ),
                ),

                // List Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tap a zikir to start counting'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.mute),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(() {
                        final q = searchQuery.value;
                        final count = c.filteredZikirs.where((item) {
                          if (q.isEmpty) return true;
                          return item.titleBn.toLowerCase().contains(q) ||
                              item.titleEn.toLowerCase().contains(q) ||
                              item.arabic.contains(q) ||
                              item.meaningBn.toLowerCase().contains(q);
                        }).length;

                        return Text(
                          '$count ${'Items'.tr}',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.income),
                        );
                      }),
                    ],
                  ),
                ),

                // Zikirs Ranked List with Counters & Relative Progress
                Expanded(
                  child: Obx(() {
                    final q = searchQuery.value;
                    final list = c.getSortedZikirsByCount().where((item) {
                      if (q.isEmpty) return true;
                      return item.titleBn.toLowerCase().contains(q) ||
                          item.titleEn.toLowerCase().contains(q) ||
                          item.arabic.contains(q) ||
                          item.meaningBn.toLowerCase().contains(q);
                    }).toList();

                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'No zikir found'.tr,
                          style: TextStyle(color: p.mute),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final item = list[i];
                        final count = c.getZikirCount(item.id);
                        final isSelected = item.id == c.selectedZikir.id;
                        final ratio = maxCount > 0 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;

                        return Material(
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
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p.income.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          c.getCategoryName(item.category),
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
                                            fontSize: 14,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: count > 0 ? p.income : p.bg,
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
                                  const SizedBox(height: 5),
                                  // Arabic text
                                  Text(
                                    item.arabic,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: p.income,
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
                                  const SizedBox(height: 4),
                                  // Meaning
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
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
