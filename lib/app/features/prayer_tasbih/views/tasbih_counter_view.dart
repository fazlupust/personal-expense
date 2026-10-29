import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../routes/app_routes.dart';
import '../controllers/prayer_tasbih_controller.dart';

class TasbihCounterView extends StatelessWidget {
  final bool isEmbedded;
  const TasbihCounterView({super.key, this.isEmbedded = false});

  void showAnalyticsSheet(BuildContext context, PrayerTasbihController c, AppPalette p) {
    Get.toNamed(AppRoutes.tasbihHistory);
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
    Get.toNamed(AppRoutes.tasbihHistory);
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
                Icon(Icons.auto_stories_rounded, size: 22, color: p.income),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All Zikirs & Duas'.tr,
                    style: TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: p.income.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${c.allZikirs.length} ${'Items'.tr}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: p.income,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: p.line.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 19, color: p.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchCtrl,
              onChanged: (v) => query.value = v.trim().toLowerCase(),
              style: TextStyle(fontSize: 14.5, color: p.ink),
              decoration: InputDecoration(
                hintText: 'Search zikir or meaning...'.tr,
                hintStyle: TextStyle(fontSize: 14, color: p.mute),
                prefixIcon: Icon(Icons.search, size: 20, color: p.mute),
                isDense: true,
                filled: true,
                fillColor: p.bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
              height: 36,
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
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => selectedCategory.value = cat,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? p.income : p.bg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isSel ? p.income : p.line),
                        ),
                        child: Center(
                          child: Text(
                            c.getCategoryName(cat),
                            style: TextStyle(
                              fontSize: 12.5,
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
                final filtered = c.sortedZikirs.where((item) {
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
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? p.income : p.ink,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: p.income.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${item.defaultTarget}x',
                                      style: TextStyle(
                                        fontSize: 11.5,
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
                              const SizedBox(height: 5),
                              Text(
                                item.arabic,
                                maxLines: item.id == 'post_prayer_sea_foam' ? 3 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: item.id == 'post_prayer_sea_foam' ? 19 : 22.5,
                                  fontWeight: FontWeight.w700,
                                  color: p.income,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 4),
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
        final cycleStep = (target > 0 && current > 0)
            ? (((current - 1) % target) + 1)
            : current;
        final progress = target > 0 ? (cycleStep / target).clamp(0.0, 1.0) : 0.0;
        final zikir = c.selectedZikir;
        final isBn = Get.locale?.languageCode == 'bn';

        final content = SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isEmbedded) ...[
                // Embedded top action bar (History/Stats, Catalog, Vibration, Reset)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(
                        c.isCountHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20,
                        color: c.isCountHidden ? p.mute : p.income,
                      ),
                      tooltip: c.isCountHidden ? 'Show count'.tr : 'Hide count'.tr,
                      onPressed: c.toggleCountVisibility,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(Icons.query_stats_rounded, size: 20, color: p.income),
                      tooltip: 'Tasbih History & Filter'.tr,
                      onPressed: () => _showTasbihAnalyticsSheet(context, c, p),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(Icons.auto_stories_rounded, size: 20, color: p.income),
                      tooltip: 'All Zikirs & Duas'.tr,
                      onPressed: () => _showAllZikirsSheet(context, c, p),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(
                        c.isVibrationEnabled ? Icons.vibration_rounded : Icons.smartphone_rounded,
                        size: 20,
                        color: c.isVibrationEnabled ? p.income : p.mute,
                      ),
                      tooltip: 'Vibration'.tr,
                      onPressed: c.toggleVibration,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showAllZikirsSheet(context, c, p),
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.income.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_stories_rounded, size: 17, color: p.income),
                          const SizedBox(width: 4),
                          Text(
                            'All'.tr,
                            style: TextStyle(
                              fontSize: 15,
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
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: c.sortedZikirs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (ctx, i) {
                          final item = c.sortedZikirs[i];
                          final isSelected = item.id == zikir.id;
                          const boroDuaIds = {
                            'durood_ibrahim',
                            'durood_sharif',
                            'ayatul_kursi',
                            'sayyidul_istighfar',
                            'dua_yunus',
                            'post_prayer_sea_foam',
                            'shifa_body_pain',
                            'four_kalimas',
                            'la_ilaha_wahdahu',
                            'adada_khalqihi',
                            'bismika_amootu_wa_ahya',
                            'alhamdulillah_alladhi_ahyana',
                            'allahumma_ajirni',
                          };
                          final isBoroDua = boroDuaIds.contains(item.id);

                          final title = (isBn || isBoroDua)
                              ? item.titleBn
                              : item.arabic.split('\n').first.replaceAll(RegExp(r'✦.*'), '').trim();

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(21),
                              onTap: () => c.selectZikir(item),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? p.income : p.card,
                                  borderRadius: BorderRadius.circular(21),
                                  border: Border.all(
                                    color: isSelected ? p.income : p.line,
                                    width: 1.1,
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
                                    title,
                                    style: TextStyle(
                                      fontSize: (isBn || isBoroDua) ? 16 : 17.5,
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

              const SizedBox(height: 10),

              // Selected Zikir Card (Arabic, Pronunciation, Meaning, Virtue)
              if (c.isZikirCardHidden || c.isCountHidden) ...[
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      if (c.isCountHidden) {
                        c.toggleCountVisibility();
                      }
                      c.setZikirCardHidden(false);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_outlined, size: 14, color: p.income),
                          const SizedBox(width: 5),
                          Text(
                            'Show zikir details'.tr,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: p.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else if (zikir.id == 'post_prayer_sea_foam') ...[
                _buildHisnulMuslimSeaFoamCard(c, zikir, cycleStep, p),
              ] else if (zikir.id == 'shifa_body_pain') ...[
                _buildShifaBodyPainCard(c, zikir, cycleStep, p),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header Row: Hide card button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: c.toggleZikirCardVisibility,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_off_outlined, size: 13, color: p.mute),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Hide'.tr,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: p.mute,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Arabic
                      Text(
                        zikir.arabic,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: zikir.arabic.length > 80
                              ? 20
                              : (zikir.arabic.length > 40 ? 24 : 29),
                          fontWeight: FontWeight.w700,
                          color: p.income,
                          height: zikir.arabic.length > 80 ? 1.45 : 1.38,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Bengali / English Title & Meaning
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            isBn ? zikir.titleBn : zikir.titleEn,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                          Text('•', style: TextStyle(color: p.mute, fontSize: 11)),
                          Text(
                            isBn ? zikir.meaningBn : zikir.meaningEn,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: p.mute,
                            ),
                          ),
                        ],
                      ),
                      if (zikir.benefitBn != null && zikir.benefitBn!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 60),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: p.income.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars_rounded, size: 13, color: p.income),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  zikir.benefitBn!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: p.income,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!c.isCountHidden) ...[
                        const SizedBox(height: 6),
                        // Compact Per-Zikir Recitation Count & Visibility Shortcut
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: c.toggleCountVisibility,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 60),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.income.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: p.income.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_off_rounded, size: 14, color: p.income),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${c.getZikirTodayCount(zikir.id)} ${'Times'.tr} (${'Today'.tr}) · ${c.getZikirLifetimeCount(zikir.id)} ${'Times'.tr} (${'All Time'.tr})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: p.income,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded, size: 14, color: p.income),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 12),

              // Interactive Digital Tasbih Counter Dial
              Center(
                child: GestureDetector(
                  onTap: c.increment,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.card,
                      boxShadow: [
                        BoxShadow(
                          color: p.income.withOpacity(0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Circular Progress Ring
                        SizedBox(
                          width: 186,
                          height: 186,
                          child: CircularProgressIndicator(
                            value: target > 0 ? progress : 1.0,
                            strokeWidth: 9,
                            backgroundColor: p.line,
                            valueColor: AlwaysStoppedAnimation<Color>(p.income),
                            strokeCap: StrokeCap.round,
                          ),
                        ),

                        // Inside Dial Info & Touch Surface
                        Container(
                          width: 164,
                          height: 164,
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
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Target Badge (Tap to change target)
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: InkWell(
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
                                    ),
                                    const SizedBox(height: 4),

                                    // Huge Counter Number
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          c.isCountHidden ? '***' : NumberFormat('#,###').format(current),
                                          style: TextStyle(
                                            fontSize: c.isCountHidden ? 44 : 48,
                                            fontWeight: FontWeight.w900,
                                            color: p.ink,
                                            letterSpacing: c.isCountHidden ? 4 : -1,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Completed cycles indicator
                                    if (c.completedCycles > 0) ...[
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          c.isCountHidden
                                              ? '${'Round:'.tr} ***'
                                              : '${'Round:'.tr} ${c.completedCycles}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: p.income,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 2),

                                    // Tap Hint (scaled down cleanly in any language)
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.touch_app_rounded, size: 12, color: p.mute),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Tap to count'.tr,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w500,
                                                color: p.mute,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Quick Action Buttons (Undo -1, +1 Count, Reset)
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
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Large Tap CTA button
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: c.increment,
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: Text(
                        '+1 ${'Count'.tr}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: p.income,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Reset
                  IconButton.filledTonal(
                    onPressed: () => _showResetConfirmDialog(context, c, p),
                    icon: const Icon(Icons.restart_alt_rounded, size: 20),
                    tooltip: 'Reset'.tr,
                    style: IconButton.styleFrom(
                      backgroundColor: p.card,
                      foregroundColor: p.expense,
                      side: BorderSide(color: p.line),
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Today & Lifetime Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.today_rounded, size: 15, color: p.income),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Today\'s Count'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: p.mute,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.isCountHidden ? '***' : NumberFormat('#,###').format(c.todayTotal),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: p.ink,
                              letterSpacing: c.isCountHidden ? 2 : 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.all_inclusive_rounded, size: 15, color: p.income),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Lifetime Total'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: p.mute,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.isCountHidden ? '***' : NumberFormat('#,###').format(c.lifetimeTotal),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: p.ink,
                              letterSpacing: c.isCountHidden ? 2 : 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Tasbih History & Filter Action Card
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showTasbihAnalyticsSheet(context, c, p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.income.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: p.income.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.query_stats_rounded, size: 18, color: p.income),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tasbih History & Filter'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Recitation Statistics'.tr,
                              style: TextStyle(fontSize: 10.5, color: p.mute),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 13, color: p.income),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Quick switch to Prayer Times
              OutlinedButton.icon(
                onPressed: () {
                  c.setActiveTab(0);
                  if (isEmbedded) {
                    // Already inside tabbed view, setActiveTab(0) is applied
                  } else if (Get.previousRoute == AppRoutes.prayerAndTasbih) {
                    Get.back();
                  } else {
                    Get.offNamed(AppRoutes.prayerAndTasbih);
                  }
                },
                icon: Icon(Icons.access_time_filled_rounded, size: 16, color: p.income),
                label: Text(
                  'View Prayer Times Schedule'.tr,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: p.income),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.income.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
              // Tasbih History & Analytics
              IconButton(
                icon: Icon(Icons.query_stats_rounded, size: 21, color: p.income),
                tooltip: 'Tasbih History & Filter'.tr,
                onPressed: () => _showTasbihAnalyticsSheet(context, c, p),
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
                icon: Icon(Icons.refresh_rounded, size: 21, color: p.expense),
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

  Widget _buildHisnulMuslimSeaFoamCard(
    PrayerTasbihController c,
    ZikirItem zikir,
    int cycleStep,
    AppPalette p,
  ) {
    // Current recitation phase (1..100)
    String currentPhaseText;
    if (cycleStep == 0) {
      currentPhaseText = 'শুরু করুন: ১ম পর্ব - সুবহানাল্লাহ (৩৩ বার)';
    } else if (cycleStep <= 33) {
      currentPhaseText = '১ম পর্ব: সুবহানাল্লাহ (${cycleStep}/৩৩ বার)';
    } else if (cycleStep <= 66) {
      currentPhaseText = '২য় পর্ব: আলহামদুলিল্লাহ (${cycleStep - 33}/৩৩ বার)';
    } else if (cycleStep <= 99) {
      currentPhaseText = '৩য় পর্ব: আল্লাহু আকবার (${cycleStep - 66}/৩৩ বার)';
    } else {
      currentPhaseText = '৪র্থ পর্ব (১০০তম দোয়া): ১ বার পাঠ করে সম্পূর্ণ করুন';
    }

    Widget buildStripeBox(String text) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: p.isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
          border: const Border(
            left: BorderSide(color: Color(0xFFEAB308), width: 3.5),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: p.ink,
            height: 1.45,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAB308).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Header Banner (হিসনুল মুসলিম ২৫.৪)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: p.isDark ? const Color(0xFF854D0E) : const Color(0xFFFDE68A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'হিসনুল মুসলিম ২৫.৪',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: p.isDark ? Colors.white : const Color(0xFF78350F),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: c.toggleZikirCardVisibility,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Icon(
                      Icons.visibility_off_outlined,
                      size: 16,
                      color: p.isDark ? Colors.white70 : const Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phase Tracker Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.income.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.income.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, size: 14, color: p.income),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            currentPhaseText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: p.income,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Part 1: Instruction
                Text(
                  'প্রত্যেকটি ৩৩ বার করে বলবে,',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 8),

                // Part 1: Arabic
                Center(
                  child: Text(
                    'سُبْحَانَ اللهِ، وَالْحَمْدُ لِلَّهِ، وَاللهُ أَكْبَرُ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: p.income,
                      height: 1.4,
                    ),
                  ),
                ),

                // Part 1: Meaning
                buildStripeBox('আল্লাহ কতই না পবিত্র-মহান। সকল প্রশংসা আল্লাহ্ জন্য। আল্লাহ সবচেয়ে বড়।'),

                // Part 1: Pronunciation
                buildStripeBox('সুবহা-নাল্লাহ, আলহামদুলিল্লাহ, আল্লা-হু আকবার'),

                const SizedBox(height: 16),

                // Part 2: Instruction
                Text(
                  'তারপর বলবে,',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 8),

                // Part 2: Arabic
                Center(
                  child: Text(
                    'لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: p.income,
                      height: 1.4,
                    ),
                  ),
                ),

                // Part 2: Meaning
                buildStripeBox(
                  'একমাত্র আল্লাহ ছাড়া কোনো হক্ব ইলাহ নেই, তাঁর কোনো শরীক নেই, রাজত্ব তাঁরই, সকল প্রশংসা তাঁরই এবং তিনি সবকিছুর উপর ক্ষমতাবান।',
                ),

                const SizedBox(height: 12),

                // Virtue / Benefit
                if (zikir.benefitBn != null && zikir.benefitBn!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.income.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: p.income),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            zikir.benefitBn!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: p.income,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (!c.isCountHidden) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: c.toggleCountVisibility,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.income.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_off_rounded, size: 14, color: p.income),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${c.getZikirTodayCount(zikir.id)} ${'Times'.tr} (${'Today'.tr}) · ${c.getZikirLifetimeCount(zikir.id)} ${'Times'.tr} (${'All Time'.tr})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: p.income,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 14, color: p.income),
                        ],
                      ),
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

  Widget _buildShifaBodyPainCard(
    PrayerTasbihController c,
    ZikirItem zikir,
    int cycleStep,
    AppPalette p,
  ) {
    // Current recitation phase (1..10)
    String currentPhaseText;
    if (cycleStep == 0 && c.currentCount > 0) {
      currentPhaseText = '১০ বার সম্পন্ন! পুনরায় শুরু করুন';
    } else if (cycleStep == 0) {
      currentPhaseText = 'শুরু: ব্যথার স্থানে হাত রেখে ৩ বার বলুন';
    } else if (cycleStep <= 3) {
      currentPhaseText = '১ম পর্ব: বিসমিল্লাহ (${cycleStep}/৩ বার)';
    } else {
      currentPhaseText = '২য় পর্ব: দোয়া (${cycleStep - 3}/৭ বার)';
    }

    Widget buildStripeBox(String text) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: p.isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
          border: const Border(
            left: BorderSide(color: Color(0xFFEAB308), width: 3.5),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: p.ink,
            height: 1.45,
          ),
        ),
      );
    }

    final isPhase1 = cycleStep > 0 && cycleStep <= 3;
    final isPhase2 = cycleStep > 3 && cycleStep <= 10;

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAB308).withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAB308).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Header Banner ([১২৪] শরীরে কোনো ব্যথা অনুভব করলে যা করবে ও বলবে)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: p.isDark ? const Color(0xFF854D0E) : const Color(0xFFFDE68A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '[১২৪] শরীরে কোনো ব্যথা অনুভব করলে যা করবে ও বলবে',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.isDark ? Colors.white : const Color(0xFF78350F),
                      letterSpacing: 0.3,
                      height: 1.3,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: c.toggleZikirCardVisibility,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Icon(
                      Icons.visibility_off_outlined,
                      size: 16,
                      color: p.isDark ? Colors.white70 : const Color(0xFF78350F),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phase Tracker Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.income.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.income.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, size: 14, color: p.income),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            currentPhaseText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: p.income,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Part 1: Instruction
                Text(
                  'আপনার দেহের যে স্থানে আপনি ব্যথা অনুভব করছেন, সেখানে আপনার হাত রেখে তিনবার বলুন,',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isPhase1 ? p.income : p.ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Part 1: Arabic
                Center(
                  child: Text(
                    'بِسْمِ اللَّهِ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: isPhase1 ? p.income : p.ink,
                      height: 1.4,
                    ),
                  ),
                ),

                // Part 1: Meaning
                buildStripeBox('আল্লাহর নামে।'),

                // Part 1: Pronunciation
                buildStripeBox('বিসমিল্লাহ'),

                const SizedBox(height: 16),

                // Part 2: Instruction
                Text(
                  'আর সাতবার বলুন,',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isPhase2 ? p.income : p.ink,
                  ),
                ),
                const SizedBox(height: 8),

                // Part 2: Arabic
                Center(
                  child: Text(
                    'أَعُوْذُ بِاللهِ وَقُدْرَتِهِ مِنْ شَرِّ مَا أَجِدُ وَأُحَاذِرُ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isPhase2 ? p.income : p.ink,
                      height: 1.5,
                    ),
                  ),
                ),

                // Part 2: Meaning
                buildStripeBox(
                  'এই যে ব্যথা আমি অনুভব করছি এবং যার আমি আশঙ্কা করছি, তা থেকে আমি আল্লাহ্ এবং তাঁর কুদরতের আশ্রয় প্রার্থনা করছি।',
                ),

                // Part 2: Pronunciation
                buildStripeBox(
                  'আ‘ঊযু বিল্লা-হি ওয়া ক্বুদরাতিহী মিন শাররি মা আজিদু ওয়া উহা-যিরু',
                ),

                const SizedBox(height: 14),

                // Hadith Reference
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.line.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'মুসলিম ৪/১৭২৮, নং ২২০২',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: p.mute,
                    ),
                  ),
                ),

                if (!c.isCountHidden) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: c.toggleCountVisibility,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.income.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_off_rounded, size: 14, color: p.income),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${c.getZikirTodayCount(zikir.id)} ${'Times'.tr} (${'Today'.tr}) · ${c.getZikirLifetimeCount(zikir.id)} ${'Times'.tr} (${'All Time'.tr})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: p.income,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, size: 14, color: p.income),
                        ],
                      ),
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
