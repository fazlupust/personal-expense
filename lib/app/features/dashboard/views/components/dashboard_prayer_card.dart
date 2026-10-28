import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/prayer_time_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../prayer_tasbih/controllers/prayer_tasbih_controller.dart';

class DashboardPrayerCard extends StatelessWidget {
  const DashboardPrayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final now = DateTime.now();
    final isBn = Get.locale?.languageCode == 'bn';

    // Calculate prayer schedule with default location (Dhaka or user selected)
    final schedule = PrayerTimeCalculator.calculate(
      date: now,
      location: BangladeshLocation.defaultLocation,
      isHanafi: true,
    );
    final currentWaqt = schedule.getCurrentWaqt(now);
    final nextPrayer = schedule.getNextPrayer(now);
    final activeProhibited = schedule.getActiveProhibitedTime(now);

    var targetTime = nextPrayer.time;
    if (targetTime.isBefore(now)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }
    final diff = targetTime.difference(now);
    final countdownStr = PrayerTimeCalculator.formatRemainingTime(diff);

    final currentWaqtName = isBn ? currentWaqt.nameBn : currentWaqt.nameEn;
    final nextPrayerName = isBn ? nextPrayer.nameBn : nextPrayer.nameEn;
    final nextPrayerTime = DateFormat('h:mm a').format(nextPrayer.time);

    final isNextSoon = schedule.isNextPrayerSoon(now, thresholdMinutes: 40);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (Get.isRegistered<PrayerTasbihController>()) {
              Get.find<PrayerTasbihController>().setActiveTab(0);
            }
            Get.toNamed(AppRoutes.prayerAndTasbih);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Crescent / Mosque Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.18),
                        const Color(0xFF0D9488).withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.nightlight_round, color: Color(0xFF0D9488), size: 21),
                  ),
                ),
                const SizedBox(width: 12),

                // Prayer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              currentWaqt.isWaqt ? '$currentWaqtName ${'Waqt'.tr}' : currentWaqtName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: currentWaqt.isWaqt
                                  ? const Color(0xFF10B981).withOpacity(0.15)
                                  : const Color(0xFFF59E0B).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              currentWaqt.isWaqt ? 'Now'.tr : 'Sunnah'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: currentWaqt.isWaqt ? const Color(0xFF059669) : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                          if (activeProhibited != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD63031).withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Prohibited'.tr,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD63031),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF0D9488)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              currentWaqt.formatRange(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (activeProhibited != null) ...[
                        Text(
                          '${'Prohibited prayer time now'.tr} (${activeProhibited.formatRange()})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD63031),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (isNextSoon)
                        Text(
                          '${'Next:'.tr} $nextPrayerName ($nextPrayerTime) · $countdownStr ${'left'.tr}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Dedicated Vibrant Gradient Zikir Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      final c = Get.isRegistered<PrayerTasbihController>()
                          ? Get.find<PrayerTasbihController>()
                          : Get.put(PrayerTasbihController());
                      c.setActiveTab(1);
                      Get.toNamed(AppRoutes.prayerAndTasbih);
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0D9488), // Modern vibrant teal
                            Color(0xFF10B981), // Luminous emerald
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.32),
                            blurRadius: 7,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fingerprint_rounded, size: 15, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Zikir'.tr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
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
        ),
      ),
    );
  }
}
