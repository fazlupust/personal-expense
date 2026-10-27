import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/prayer_tasbih_controller.dart';

class TasbihCounterView extends StatelessWidget {
  const TasbihCounterView({super.key});

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

        return Scaffold(
          backgroundColor: p.bg,
          appBar: CustomAppBar(
            title: 'Digital Tasbih'.tr,
            showBackButton: true,
            actions: [
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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Zikir Selector Carousel / Horizontal List
                  SizedBox(
                    height: 42,
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
                                    fontSize: 13,
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

                  const SizedBox(height: 16),

                  // Quick switch to Prayer Times
                  OutlinedButton.icon(
                    onPressed: () => Get.back(),
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
            ),
          ),
        );
      },
    );
  }
}
