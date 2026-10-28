import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/weather_service.dart';
import '../../../settings/views/components/weather_check_sheet.dart';

class DashboardWeatherCard extends StatelessWidget {
  const DashboardWeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';
    final ws = WeatherService.to;

    return Obx(() {
      final weather = ws.currentWeather.value;
      if (weather == null) return const SizedBox.shrink();

      final condition = weather.conditionText(isBn);

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
            onTap: () => showWeatherCheckSheet(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Weather Icon container with vibrant gradient
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          weather.iconColor.withOpacity(0.2),
                          weather.iconColor.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        weather.iconData,
                        color: weather.iconColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Weather Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${weather.temperature.round()}°C · $condition',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: p.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: p.mute),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '${weather.cityName} · ${'Humidity'.tr} ${weather.humidity}%',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: p.mute,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Check Button badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Check'.tr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF0284C7)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
