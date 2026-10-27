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
    final searchCtrl = TextEditingController();
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
                  // Sliver 1: Compact Filter & Search Panel (scrolls with content)
                  SliverToBoxAdapter(
                    child: Container(
                      color: p.card,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Search Box with Total Counter Badge
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
                                  onTap: () => c.setTimeFilter(filter),
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

                  // Sliver 2: List Header Info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
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
                          Text(
                            '${list.length} ${'Items'.tr}',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.income),
                          ),
                        ],
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
                                                c.isCountHidden ? '***' : '$count ${'Times'.tr}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: count > 0 ? Colors.white : p.mute,
                                                  letterSpacing: c.isCountHidden ? 2 : 0,
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
                              ),
                            );
                          },
                          childCount: list.length,
                        ),
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
}
