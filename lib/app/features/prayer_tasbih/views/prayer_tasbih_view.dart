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
    String searchQuery = '';

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      StatefulBuilder(
        builder: (context, setState) {
          final isBn = Get.locale?.languageCode == 'bn';
          final query = searchQuery.trim().toLowerCase();

          final filteredDivisions = BangladeshLocation.divisions.where((loc) {
            if (query.isEmpty) return true;
            return loc.nameEn.toLowerCase().contains(query) ||
                loc.nameBn.toLowerCase().contains(query);
          }).toList();

          final filteredAreas = BangladeshLocation.dhakaAreas.where((loc) {
            if (query.isEmpty) return true;
            return loc.nameEn.toLowerCase().contains(query) ||
                loc.nameBn.toLowerCase().contains(query);
          }).toList();

          final filteredDistricts = BangladeshLocation.districts.where((loc) {
            if (query.isEmpty) return true;
            return loc.nameEn.toLowerCase().contains(query) ||
                loc.nameBn.toLowerCase().contains(query);
          }).toList();

          return Material(
            color: p.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Primary Color Header Bar with Close Button (Frozen)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(color: p.income),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select Division / Location'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Prayer times are calculated accurately based on geographic coordinates.'.tr,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Body
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        14,
                        18,
                        MediaQuery.of(context).viewInsets.bottom + 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Search box
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: p.bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: p.line),
                            ),
                            child: TextField(
                              onChanged: (val) => setState(() => searchQuery = val),
                              style: TextStyle(fontSize: 14.5, color: p.ink),
                              decoration: InputDecoration(
                                hintText: 'Search location...'.tr,
                                hintStyle: TextStyle(fontSize: 13.5, color: p.mute),
                                prefixIcon: Icon(Icons.search_rounded, size: 20, color: p.mute),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (filteredAreas.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_rounded, size: 16, color: p.income),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Dhaka & Areas'.tr,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: p.income,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: filteredAreas.map((loc) {
                                        return _buildLocationChip(loc, c, p, isBn);
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (filteredDivisions.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Icon(Icons.map_rounded, size: 16, color: p.income),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Divisions'.tr,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: p.income,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: filteredDivisions.map((loc) {
                                        return _buildLocationChip(loc, c, p, isBn);
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  if (filteredDistricts.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Icon(Icons.location_city_rounded, size: 16, color: p.income),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Districts'.tr,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: p.income,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: filteredDistricts.map((loc) {
                                        return _buildLocationChip(loc, c, p, isBn);
                                      }).toList(),
                                    ),
                                  ],
                                  if (filteredDivisions.isEmpty && filteredAreas.isEmpty && filteredDistricts.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Text(
                                        'No location found'.tr,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, color: p.mute),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationChip(
    BangladeshLocation loc,
    PrayerTasbihController c,
    AppPalette p,
    bool isBn,
  ) {
    final isSelected = c.selectedLocation.id == loc.id;
    final name = isBn ? loc.nameBn : loc.nameEn;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Get.back();
        c.setLocation(loc);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
        decoration: BoxDecoration(
          color: isSelected ? p.income : p.bg,
          borderRadius: BorderRadius.circular(10),
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
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : p.ink,
              ),
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

    final gregorianDateStr = DateFormat('EEEE, d MMMM yyyy', isBn ? 'bn' : 'en').format(now);

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
                          Icon(Icons.location_on_rounded, size: 17, color: p.income),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: p.mute),
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
                          style: TextStyle(fontSize: 13, color: p.mute, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          c.isHanafi ? 'Hanafi'.tr : 'Shafi'.tr,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
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
                  child: Icon(Icons.nightlight_round, color: p.income, size: 24),
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
                              isBn ? schedule.hijriDateBn : schedule.hijriDateEn,
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: p.income,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (schedule.isOnlineSynced) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.income.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: p.income.withOpacity(0.3), width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_done_rounded, size: 12, color: p.income),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Live'.tr,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: p.income,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        gregorianDateStr,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: p.mute,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<int>(
                  tooltip: isBn ? 'হিজরি তারিখ সমন্বয়' : 'Adjust Hijri Date',
                  icon: Icon(Icons.tune_rounded, color: p.income, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: p.card,
                  onSelected: (val) {
                    if (val == 99) {
                      c.syncOnlineHijriDate(force: true);
                    } else {
                      c.setHijriOffset(val);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 99,
                      child: Row(
                        children: [
                          Icon(Icons.sync_rounded, size: 16, color: p.income),
                          const SizedBox(width: 8),
                          Text(
                            isBn ? 'অনলাইন থেকে রি-সিঙ্ক' : 'Re-sync Online',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: p.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: -2,
                      child: Text(
                        isBn ? 'সমন্বয়: -২ দিন' : 'Offset: -2 days',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: c.hijriOffsetDays == -2 ? FontWeight.w800 : FontWeight.w500,
                          color: c.hijriOffsetDays == -2 ? p.income : p.ink,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: -1,
                      child: Text(
                        isBn ? 'সমন্বয়: -১ দিন (বাংলাদেশ)' : 'Offset: -1 day (Bangladesh)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: c.hijriOffsetDays == -1 ? FontWeight.w800 : FontWeight.w500,
                          color: c.hijriOffsetDays == -1 ? p.income : p.ink,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 0,
                      child: Text(
                        isBn ? 'সমন্বয়: ০ দিন (সৌদি / গ্লোবাল)' : 'Offset: 0 days (Saudi / Global)',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: c.hijriOffsetDays == 0 ? FontWeight.w800 : FontWeight.w500,
                          color: c.hijriOffsetDays == 0 ? p.income : p.ink,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 1,
                      child: Text(
                        isBn ? 'সমন্বয়: +১ দিন' : 'Offset: +1 day',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: c.hijriOffsetDays == 1 ? FontWeight.w800 : FontWeight.w500,
                          color: c.hijriOffsetDays == 1 ? p.income : p.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Active Prohibited Prayer Time Alert (if current time is prohibited & alert enabled)
          Builder(
            builder: (context) {
              final activeProhibited = c.isProhibitedAlertOn
                  ? schedule.getActiveProhibitedTime(
                      DateTime.now(),
                      bufferMinutes: c.prohibitedBufferMinutes,
                    )
                  : null;
              if (activeProhibited == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD63031).withOpacity(0.09),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD63031).withOpacity(0.35), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD63031).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.block_rounded, size: 18, color: Color(0xFFD63031)),
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
                                  'Prohibited prayer time now'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD63031),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD63031),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  'Haram'.tr,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${isBn ? activeProhibited.nameBn : activeProhibited.nameEn} (${activeProhibited.formatRange()}) · ${'Any prayer is forbidden now'.tr}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: p.ink.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                            decoration: BoxDecoration(
                              color: currentWaqt.isWaqt ? const Color(0xFF55EFC4) : const Color(0xFFFFEAA7),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            currentWaqt.isWaqt ? 'Active Waqt'.tr : 'Sunnah / Nafl'.tr,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        currentWaqt.arabicName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isBn ? currentWaqt.nameBn : currentWaqt.nameEn,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 16, color: Colors.white70),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        currentWaqt.formatRange(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (schedule.isNextPrayerSoon(now, thresholdMinutes: 40)) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${'Next:'.tr} ${isBn ? nextPrayer.nameBn : nextPrayer.nameEn} (${DateFormat('h:mm a').format(nextPrayer.time)}) · ${c.timeUntilNextPrayer} ${'left'.tr}',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Button to open Digital Tasbih
                FilledButton.icon(
                  onPressed: () => c.setActiveTab(1),
                  icon: const Icon(Icons.fingerprint_rounded, size: 22),
                  label: Text(
                    'Open Digital Tasbih Counter'.tr,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF135A3B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
                          Icon(Icons.alarm_on_rounded, size: 17, color: p.income),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sehri Ends'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.mute),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(schedule.sehriEnd),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
                          Icon(Icons.wb_twilight_rounded, size: 17, color: const Color(0xFFE67E22)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Iftar Time'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.mute),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(schedule.iftar),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Sunrise & Sunset Card Row (সূর্যোদয় ও সূর্যাস্ত - নামাজের তালিকা থেকে আলাদা)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
                          const Icon(Icons.wb_sunny_rounded, size: 17, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sunrise'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.mute),
                            ),
                          ),
                          Text(
                            'الشروق',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.mute.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(schedule.sunrise),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
                          const Icon(Icons.nights_stay_rounded, size: 17, color: Color(0xFFE17055)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Sunset'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: p.mute),
                            ),
                          ),
                          Text(
                            'الغروب',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.mute.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(schedule.sunset),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
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

          // All 5 Waqt Prayer Times List (Excludes Sunrise / Sunset)
          Text(
            'Daily Prayer Times'.tr,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 8),

          ...schedule.waqtItems.map((item) {
            final isCurrent = item.prayer == currentWaqt.prayer && item.isWaqt;
            final isNext = item.prayer == nextPrayer.prayer && schedule.isNextPrayerSoon(now, thresholdMinutes: 40);
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
                    style: const TextStyle(fontSize: 24),
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
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: isCurrent ? p.income : p.ink,
                                ),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.income,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Current'.tr,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ] else if (isNext) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.mute.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Next'.tr,
                                  style: TextStyle(
                                    fontSize: 11,
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
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: p.mute,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: isCurrent ? p.income : p.mute,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.formatRange(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                  color: isCurrent ? p.income : p.mute,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    timeFormatted,
                    style: TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w900,
                      color: isCurrent ? p.income : p.ink,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Prohibited Prayer Times Section (নামাজের নিষিদ্ধ সময়সূচি)
          Row(
            children: [
              const Icon(Icons.block_rounded, size: 16, color: Color(0xFFD63031)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Prohibited Prayer Times'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFD63031).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Haram'.tr,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD63031),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3 times when praying Salah is forbidden (Sahih Muslim 831)'.tr,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: p.mute,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cautionary solar window (varies daily)'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD63031).withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Alert On/Off Toggle
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: c.toggleProhibitedAlert,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.isProhibitedAlertOn
                        ? const Color(0xFFD63031).withOpacity(0.12)
                        : p.mute.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: c.isProhibitedAlertOn
                          ? const Color(0xFFD63031).withOpacity(0.35)
                          : p.line,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.isProhibitedAlertOn
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        size: 13,
                        color: c.isProhibitedAlertOn ? const Color(0xFFD63031) : p.mute,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        c.isProhibitedAlertOn ? 'Alert On'.tr : 'Alert Off'.tr,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: c.isProhibitedAlertOn ? const Color(0xFFD63031) : p.mute,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.line),
            ),
            child: Column(
              children: schedule
                  .getProhibitedTimes(bufferMinutes: c.prohibitedBufferMinutes)
                  .asMap()
                  .entries
                  .map((entry) {
                final idx = entry.key;
                final item = entry.value;
                final isProhibitedNow = item.contains(DateTime.now());

                return Column(
                  children: [
                    if (idx > 0)
                      Divider(color: p.line.withOpacity(0.6), height: 16),
                    Row(
                      children: [
                        Text(item.icon, style: const TextStyle(fontSize: 20)),
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
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isProhibitedNow ? const Color(0xFFD63031) : p.ink,
                                      ),
                                    ),
                                  ),
                                  if (isProhibitedNow) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD63031),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        'Now'.tr,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isBn ? item.noteBn : item.noteEn,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: p.mute,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.formatRange(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isProhibitedNow ? const Color(0xFFD63031) : p.ink,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Explanatory Note on Solar Variance & Cautionary Window
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD63031).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD63031).withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFD63031)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Prohibited times change daily based on sunrise, midday (zawal) and sunset. Islamic scholars recommend a 15–20 minute cautionary window.'.tr,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: p.ink.withOpacity(0.85),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
            showLanguageToggle: false,
            showThemeToggle: false,
            showLogout: false,
            actions: [
              if (c.activeTab == 1) ...[
                IconButton(
                  icon: Icon(
                    c.isCountHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: c.isCountHidden ? p.mute : p.income,
                    size: 21,
                  ),
                  tooltip: c.isCountHidden ? 'Show count'.tr : 'Hide count'.tr,
                  onPressed: c.toggleCountVisibility,
                ),
                IconButton(
                  icon: Icon(Icons.query_stats_rounded, color: p.income, size: 21),
                  tooltip: 'Tasbih History & Filter'.tr,
                  onPressed: () => Get.toNamed(AppRoutes.tasbihHistory),
                ),
              ] else ...[
                IconButton(
                  icon: Icon(Icons.location_on_rounded, color: p.income, size: 20),
                  tooltip: 'Select Division / Location'.tr,
                  onPressed: () => _showLocationPicker(context, c, p),
                ),
              ],
              // Shortcut to toggle between Tasbih and Prayer Times
              if (c.activeTab == 0)
                IconButton(
                  icon: Icon(Icons.fingerprint_rounded, color: p.income, size: 22),
                  tooltip: 'Digital Tasbih'.tr,
                  onPressed: () => c.setActiveTab(1),
                )
              else
                IconButton(
                  icon: Icon(Icons.access_time_filled_rounded, color: p.income, size: 21),
                  tooltip: 'Prayer Times'.tr,
                  onPressed: () => c.setActiveTab(0),
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
                                gradient: c.activeTab == 0
                                    ? const LinearGradient(
                                        colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: c.activeTab == 0
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
                                gradient: c.activeTab == 1
                                    ? const LinearGradient(
                                        colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: c.activeTab == 1
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
