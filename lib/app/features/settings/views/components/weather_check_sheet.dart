import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/prayer_time_service.dart';
import '../../../../data/services/weather_service.dart';
import '../../controllers/settings_controller.dart';

void showWeatherCheckSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _WeatherCheckSheetContent(),
  );
}

class _WeatherCheckSheetContent extends StatefulWidget {
  const _WeatherCheckSheetContent();

  @override
  State<_WeatherCheckSheetContent> createState() => _WeatherCheckSheetContentState();
}

class _WeatherCheckSheetContentState extends State<_WeatherCheckSheetContent> {
  late String _selectedCity;

  @override
  void initState() {
    super.initState();
    final ws = WeatherService.to;
    _selectedCity = ws.selectedCity.value;
    // Trigger fresh check on open
    ws.fetchWeather(cityName: _selectedCity);
  }

  void _onCityChanged(String? newCity) {
    if (newCity == null || newCity == _selectedCity) return;
    setState(() => _selectedCity = newCity);
    WeatherService.to.fetchWeather(cityName: newCity);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';
    final ws = WeatherService.to;

    // Calculate sunrise / sunset for the selected city
    final loc = _findLocation(_selectedCity);
    final prayerSchedule = PrayerTimeCalculator.calculate(
      date: DateTime.now(),
      location: loc,
      isHanafi: true,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: p.mute.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_queue_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weather Check'.tr,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: p.ink,
                          ),
                        ),
                        Text(
                          'Live weather & forecast'.tr,
                          style: TextStyle(fontSize: 11.5, color: p.mute),
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  Obx(() {
                    final loading = ws.isLoading.value;
                    return IconButton(
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.refresh_rounded, color: p.ink),
                      tooltip: 'Refresh Weather'.tr,
                      onPressed: loading ? null : () => ws.fetchWeather(cityName: _selectedCity),
                    );
                  }),
                  // Close button
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: p.mute),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Location Selector dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: p.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.line),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 18, color: p.income),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _allCities.contains(_selectedCity) ? _selectedCity : 'Dhaka',
                                isExpanded: true,
                                icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.mute),
                                items: _allCities.map((city) {
                                  final cityLoc = _findLocation(city);
                                  final label = isBn ? cityLoc.nameBn : cityLoc.nameEn;
                                  return DropdownMenuItem<String>(
                                    value: city,
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: p.ink,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: _onCityChanged,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Weather Hero Card
                    Obx(() {
                      final weather = ws.currentWeather.value;
                      if (weather == null) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: p.bg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final cityNameDisplay = isBn ? loc.nameBn : loc.nameEn;
                      final conditionText = weather.conditionText(isBn);

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: weather.isDay
                                ? [
                                    const Color(0xFF0284C7),
                                    const Color(0xFF0369A1),
                                    const Color(0xFF075985),
                                  ]
                                : [
                                    const Color(0xFF1E293B),
                                    const Color(0xFF0F172A),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withOpacity(0.28),
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
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_city_rounded,
                                      size: 16,
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      cityNameDisplay,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    weather.isDay ? 'Daytime'.tr : 'Night'.tr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  weather.iconData,
                                  size: 54,
                                  color: Colors.amberAccent,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${weather.temperature.round()}°C',
                                        style: const TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -1,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        conditionText,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withOpacity(0.95),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Text(
                                  '${'Feels like'.tr} ${weather.apparentTemperature.round()}°C',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                                Text(
                                  ' · ',
                                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                ),
                                Text(
                                  '${'High'.tr}: ${weather.maxTemp.round()}°C · ${'Low'.tr}: ${weather.minTemp.round()}°C',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 14),

                    // Weather details grid
                    Obx(() {
                      final weather = ws.currentWeather.value;
                      if (weather == null) return const SizedBox.shrink();

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  p: p,
                                  icon: Icons.water_drop_rounded,
                                  iconColor: const Color(0xFF0284C7),
                                  title: 'Humidity'.tr,
                                  value: '${weather.humidity}%',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMetricTile(
                                  p: p,
                                  icon: Icons.air_rounded,
                                  iconColor: const Color(0xFF10B981),
                                  title: 'Wind Speed'.tr,
                                  value: '${weather.windSpeed.round()} km/h',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricTile(
                                  p: p,
                                  icon: Icons.wb_sunny_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                  title: 'Sunrise'.tr,
                                  value: DateFormat('h:mm a').format(prayerSchedule.sunrise),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMetricTile(
                                  p: p,
                                  icon: Icons.nights_stay_rounded,
                                  iconColor: const Color(0xFFE17055),
                                  title: 'Sunset'.tr,
                                  value: DateFormat('h:mm a').format(prayerSchedule.sunset),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 16),

                    // Quick Toggle: Show Weather on Dashboard
                    GetBuilder<SettingsController>(
                      builder: (s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: p.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: p.line),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.dashboard_customize_rounded, size: 20, color: p.income),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Show Weather on Dashboard'.tr,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: p.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Display quick weather summary card on dashboard'.tr,
                                    style: TextStyle(fontSize: 11, color: p.mute),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: s.showWeatherCard,
                              activeColor: p.income,
                              onChanged: s.setShowWeatherCard,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Done / Close Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: p.income,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close'.tr,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
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
  }

  Widget _buildMetricTile({
    required AppPalette p,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: p.mute, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static BangladeshLocation _findLocation(String cityName) {
    for (final loc in BangladeshLocation.allLocations) {
      if (loc.nameEn.toLowerCase() == cityName.toLowerCase() ||
          loc.nameBn.toLowerCase() == cityName.toLowerCase() ||
          loc.id.toLowerCase() == cityName.toLowerCase()) {
        return loc;
      }
    }
    return BangladeshLocation.defaultLocation;
  }

  static const List<String> _allCities = [
    'Dhaka',
    'Mirpur',
    'Uttara',
    'Farmgate',
    'Gazipur',
    'Lion / Lalbagh',
    'Chattogram',
    'Rajshahi',
    'Khulna',
    'Barishal',
    'Sylhet',
    'Rangpur',
    'Mymensingh',
    'Pabna',
    'Sirajganj',
    'Bogura',
    'Naogaon',
    'Natore',
    'Kushtia',
    'Jashore',
    'Cumilla',
  ];
}
