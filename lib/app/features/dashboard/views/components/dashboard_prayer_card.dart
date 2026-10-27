import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/prayer_time_service.dart';
import '../../../../routes/app_routes.dart';

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

    var targetTime = nextPrayer.time;
    if (targetTime.isBefore(now)) {
      targetTime = targetTime.add(const Duration(days: 1));
    }
    final diff = targetTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    final countdownStr = hours > 0 ? '$hours h $minutes m' : '$minutes m';

    final currentWaqtName = isBn ? currentWaqt.nameBn : currentWaqt.nameEn;
    final nextPrayerName = isBn ? nextPrayer.nameBn : nextPrayer.nameEn;
    final nextPrayerTime = DateFormat('h:mm a').format(nextPrayer.time);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.income.withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: p.income.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.toNamed(AppRoutes.prayerAndTasbih),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Crescent / Mosque Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: p.income.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(Icons.nightlight_round, color: p.income, size: 22),
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
                              '$currentWaqtName ${'Waqt'.tr}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: p.income,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: p.income.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Now'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: p.income,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${'Next:'.tr} $nextPrayerName ($nextPrayerTime) · $countdownStr ${'left'.tr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: p.mute,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Dedicated Zikir Button
                FilledButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.tasbihCounter),
                  icon: const Icon(Icons.fingerprint_rounded, size: 16),
                  label: Text(
                    'Zikir'.tr,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: p.income,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
