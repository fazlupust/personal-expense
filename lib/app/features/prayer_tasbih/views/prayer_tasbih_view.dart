import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../data/services/prayer_time_service.dart';
import '../../../routes/app_routes.dart';
import '../controllers/prayer_tasbih_controller.dart';
import 'tasbih_counter_view.dart';

class PrayerTasbihView extends StatelessWidget {
  const PrayerTasbihView({super.key});

  void _showLocationPicker(BuildContext context, PrayerTasbihController c, AppPalette p) {
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
              'Select Division / Location'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink),
            ),
            const SizedBox(height: 6),
            Text(
              'Prayer times are calculated accurately based on geographic coordinates.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: p.mute),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: BangladeshLocation.divisions.map((loc) {
                final isSelected = c.selectedLocation.id == loc.id;
                final isBn = Get.locale?.languageCode == 'bn';
                final name = isBn ? loc.nameBn : loc.nameEn;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Get.back();
                    c.setLocation(loc);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? p.income : p.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? p.income : p.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 15,
                          color: isSelected ? Colors.white : p.income,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : p.ink,
                          ),
                        ),
                      ],
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

  Widget _buildPrayerTimesTab(BuildContext context, PrayerTasbihController c, AppPalette p) {
    final schedule = c.schedule;
    final now = DateTime.now();
    final isBn = Get.locale?.languageCode == 'bn';
    final locationName = isBn ? c.selectedLocation.nameBn : c.selectedLocation.nameEn;
    final currentWaqt = c.currentWaqt ?? schedule.getCurrentWaqt(now);
    final nextPrayer = c.nextPrayer ?? schedule.getNextPrayer(now);

    final gregorianDateStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Location bar & Asr Method Toggle
          Row(
            children: [
              // Location Selector Chip
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showLocationPicker(context, c, p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.line),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 16, color: p.income),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: p.mute),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Hanafi / Shafi Toggle
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: c.toggleAsrMethod,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Asr:'.tr,
                          style: TextStyle(fontSize: 12, color: p.mute),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          c.isHanafi ? 'Hanafi'.tr : 'Shafi'.tr,
                          style: TextStyle(
                            fontSize: 12.5,
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
          ),

          const SizedBox(height: 12),

          // Date & Islamic Hijri Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.income.withOpacity(0.12),
                  p.card,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.income.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: p.income.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.nightlight_round, color: p.income, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.hijriDate,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: p.income,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gregorianDateStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: p.mute,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Hero Active Waqt Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.income,
                  const Color(0xFF135A3B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: p.income.withOpacity(0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF55EFC4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active Waqt'.tr,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currentWaqt.arabicName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isBn ? currentWaqt.nameBn : currentWaqt.nameEn,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('h:mm a').format(currentWaqt.time),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${'Next:'.tr} ${isBn ? nextPrayer.nameBn : nextPrayer.nameEn} (${DateFormat('h:mm a').format(nextPrayer.time)}) · ${c.timeUntilNextPrayer} ${'left'.tr}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 14),

                // Button to open Digital Tasbih
                FilledButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.tasbihCounter),
                  icon: const Icon(Icons.fingerprint_rounded, size: 20),
                  label: Text(
                    'Open Digital Tasbih Counter'.tr,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF135A3B),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Sehri End & Iftar Card Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          Icon(Icons.alarm_on_rounded, size: 15, color: p.income),
                          const SizedBox(width: 5),
                          Text(
                            'Sehri Ends'.tr,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.mute),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(schedule.sehriEnd),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                          Icon(Icons.wb_twilight_rounded, size: 15, color: const Color(0xFFE67E22)),
                          const SizedBox(width: 5),
                          Text(
                            'Iftar Time'.tr,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.mute),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(schedule.iftar),
                        style: TextStyle(
                          fontSize: 15,
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

          // All 5 Waqt & Sunrise Prayer Times List
          Text(
            'Daily Prayer Times'.tr,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 8),

          ...schedule.items.map((item) {
            final isCurrent = item.prayer == currentWaqt.prayer && item.isWaqt;
            final isNext = item.prayer == nextPrayer.prayer;
            final timeFormatted = DateFormat('h:mm a').format(item.time);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrent ? p.income.withOpacity(0.08) : p.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCurrent ? p.income : p.line,
                  width: isCurrent ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    item.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                isBn ? item.nameBn : item.nameEn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrent ? p.income : p.ink,
                                ),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.income,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Current'.tr,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ] else if (isNext) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.mute.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Next'.tr,
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
                        Text(
                          item.arabicName,
                          style: TextStyle(
                            fontSize: 12,
                            color: p.mute,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    timeFormatted,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isCurrent ? p.income : p.ink,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 12),

          // Tahajjud & Ishraq prayer guidance note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: p.mute),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tahajjud best time starts at 1/3 of the night before Fajr. Ishraq starts 15 minutes after sunrise.'.tr,
                    style: TextStyle(fontSize: 11.5, color: p.mute, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
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
        return Scaffold(
          backgroundColor: p.bg,
          appBar: CustomAppBar(
            title: 'Prayer & Tasbih'.tr,
            showBackButton: true,
            actions: [
              if (c.activeTab == 1) ...[
                IconButton(
                  icon: Icon(Icons.query_stats_rounded, color: p.income, size: 22),
                  tooltip: 'Tasbih History & Filter'.tr,
                  onPressed: () => const TasbihCounterView().showAnalyticsSheet(context, c, p),
                ),
              ] else ...[
                IconButton(
                  icon: Icon(Icons.location_on_rounded, color: p.income, size: 20),
                  tooltip: 'Select Division / Location'.tr,
                  onPressed: () => _showLocationPicker(context, c, p),
                ),
              ],
              // Shortcut to open Tasbih directly
              IconButton(
                icon: Icon(Icons.fingerprint_rounded, color: p.income, size: 22),
                tooltip: 'Digital Tasbih'.tr,
                onPressed: () => Get.toNamed(AppRoutes.tasbihCounter),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top Segment Bar to switch between Prayer Times & Digital Tasbih
                Container(
                  color: p.card,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: p.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => c.setActiveTab(0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: c.activeTab == 0 ? p.income : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time_filled_rounded,
                                    size: 15,
                                    color: c.activeTab == 0 ? Colors.white : p.mute,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Prayer Times'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: c.activeTab == 0 ? Colors.white : p.mute,
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
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => c.setActiveTab(1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: c.activeTab == 1 ? p.income : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fingerprint_rounded,
                                    size: 15,
                                    color: c.activeTab == 1 ? Colors.white : p.mute,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Digital Tasbih'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: c.activeTab == 1 ? Colors.white : p.mute,
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
                ),

                // Body content based on tab
                Expanded(
                  child: c.activeTab == 0
                      ? _buildPrayerTimesTab(context, c, p)
                      : const TasbihCounterView(isEmbedded: true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
