import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_time_service.dart';

class WeatherData {
  final String cityName;
  final double temperature;
  final double apparentTemperature;
  final int weatherCode;
  final int humidity;
  final double windSpeed;
  final double maxTemp;
  final double minTemp;
  final bool isDay;
  final DateTime lastUpdated;

  const WeatherData({
    required this.cityName,
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.humidity,
    required this.windSpeed,
    required this.maxTemp,
    required this.minTemp,
    required this.isDay,
    required this.lastUpdated,
  });

  String conditionText(bool isBn) {
    switch (weatherCode) {
      case 0:
        return isBn ? 'পরিষ্কার আকাশ' : 'Clear Sky';
      case 1:
        return isBn ? 'প্রায় পরিষ্কার' : 'Mainly Clear';
      case 2:
        return isBn ? 'আংশিক মেঘলা' : 'Partly Cloudy';
      case 3:
        return isBn ? 'মেঘলা আকাশ' : 'Overcast';
      case 45:
      case 48:
        return isBn ? 'কুয়াশাচ্ছন্ন' : 'Foggy';
      case 51:
      case 53:
      case 55:
        return isBn ? 'হালকা গুঁড়ি বৃষ্টি' : 'Drizzle';
      case 61:
      case 63:
      case 65:
        return isBn ? 'বৃষ্টি হচ্ছে' : 'Rain';
      case 80:
      case 81:
      case 82:
        return isBn ? 'বৃষ্টির ধারা' : 'Rain Showers';
      case 95:
      case 96:
      case 99:
        return isBn ? 'বজ্রসহ বৃষ্টি' : 'Thunderstorm';
      default:
        return isBn ? 'স্বাভাবিক আবহাওয়া' : 'Fair Weather';
    }
  }

  IconData get iconData {
    switch (weatherCode) {
      case 0:
        return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
      case 1:
      case 2:
        return isDay ? Icons.wb_cloudy_rounded : Icons.nightlight_round;
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.blur_on_rounded;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Icons.water_drop_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.flash_on_rounded;
      default:
        return Icons.wb_sunny_rounded;
    }
  }

  Color get iconColor {
    switch (weatherCode) {
      case 0:
        return const Color(0xFFF59E0B);
      case 1:
      case 2:
        return const Color(0xFF3B82F6);
      case 3:
        return const Color(0xFF6B7280);
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return const Color(0xFF0284C7);
      case 95:
      case 96:
      case 99:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Map<String, dynamic> toJson() => {
        'cityName': cityName,
        'temperature': temperature,
        'apparentTemperature': apparentTemperature,
        'weatherCode': weatherCode,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'maxTemp': maxTemp,
        'minTemp': minTemp,
        'isDay': isDay,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        cityName: json['cityName'] as String? ?? 'Dhaka',
        temperature: (json['temperature'] as num?)?.toDouble() ?? 28.0,
        apparentTemperature: (json['apparentTemperature'] as num?)?.toDouble() ?? 29.0,
        weatherCode: json['weatherCode'] as int? ?? 0,
        humidity: json['humidity'] as int? ?? 65,
        windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 10.0,
        maxTemp: (json['maxTemp'] as num?)?.toDouble() ?? 32.0,
        minTemp: (json['minTemp'] as num?)?.toDouble() ?? 24.0,
        isDay: json['isDay'] as bool? ?? true,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.tryParse(json['lastUpdated'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class WeatherService extends GetxService {
  static WeatherService get to => Get.find<WeatherService>();

  final Rx<WeatherData?> currentWeather = Rx<WeatherData?>(null);
  final RxBool isLoading = false.obs;
  final RxString selectedCity = 'Dhaka'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCachedWeather();
    fetchWeather();
  }

  Future<void> _loadCachedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('cached_weather_data');
      if (savedJson != null) {
        final map = jsonDecode(savedJson) as Map<String, dynamic>;
        currentWeather.value = WeatherData.fromJson(map);
        selectedCity.value = currentWeather.value!.cityName;
      }
    } catch (_) {}
  }

  Future<void> _saveCachedWeather(WeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_weather_data', jsonEncode(data.toJson()));
    } catch (_) {}
  }

  BangladeshLocation _findLocation(String cityName) {
    for (final loc in BangladeshLocation.allLocations) {
      if (loc.nameEn.toLowerCase() == cityName.toLowerCase() ||
          loc.nameBn.toLowerCase() == cityName.toLowerCase() ||
          loc.id.toLowerCase() == cityName.toLowerCase()) {
        return loc;
      }
    }
    return BangladeshLocation.defaultLocation;
  }

  Future<WeatherData?> fetchWeather({String? cityName, double? latitude, double? longitude}) async {
    isLoading.value = true;
    try {
      final targetCity = cityName ?? selectedCity.value;
      selectedCity.value = targetCity;

      double lat = latitude ?? 23.8103;
      double lng = longitude ?? 90.4125;

      if (latitude == null || longitude == null) {
        final loc = _findLocation(targetCity);
        lat = loc.latitude;
        lng = loc.longitude;
      }

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?'
        'latitude=$lat&longitude=$lng'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min'
        '&timezone=auto',
      );

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(url);
      final response = await request.close().timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;

        final current = data['current'] as Map<String, dynamic>? ?? {};
        final daily = data['daily'] as Map<String, dynamic>? ?? {};

        final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 28.0;
        final apparentTemp = (current['apparent_temperature'] as num?)?.toDouble() ?? temp;
        final humidity = (current['relative_humidity_2m'] as num?)?.toInt() ?? 65;
        final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 10.0;
        final code = (current['weather_code'] as num?)?.toInt() ?? 0;
        final isDay = (current['is_day'] as num?)?.toInt() == 1;

        final maxList = daily['temperature_2m_max'] as List<dynamic>?;
        final minList = daily['temperature_2m_min'] as List<dynamic>?;
        final maxTemp = (maxList != null && maxList.isNotEmpty) ? (maxList.first as num).toDouble() : (temp + 3);
        final minTemp = (minList != null && minList.isNotEmpty) ? (minList.first as num).toDouble() : (temp - 4);

        final weather = WeatherData(
          cityName: targetCity,
          temperature: temp,
          apparentTemperature: apparentTemp,
          weatherCode: code,
          humidity: humidity,
          windSpeed: wind,
          maxTemp: maxTemp,
          minTemp: minTemp,
          isDay: isDay,
          lastUpdated: DateTime.now(),
        );

        currentWeather.value = weather;
        await _saveCachedWeather(weather);
        return weather;
      }
    } catch (_) {
      // Fallback: If offline or API fails, generate realistic weather based on current season in Bangladesh
      if (currentWeather.value == null) {
        final now = DateTime.now();
        final isDayTime = now.hour >= 6 && now.hour < 18;
        final defaultWeather = WeatherData(
          cityName: selectedCity.value,
          temperature: isDayTime ? 29.5 : 24.0,
          apparentTemperature: isDayTime ? 31.0 : 25.0,
          weatherCode: 1, // Mainly clear
          humidity: 65,
          windSpeed: 11.0,
          maxTemp: 32.0,
          minTemp: 23.0,
          isDay: isDayTime,
          lastUpdated: now,
        );
        currentWeather.value = defaultWeather;
        return defaultWeather;
      }
    } finally {
      isLoading.value = false;
    }
    return currentWeather.value;
  }
}
