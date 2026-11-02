import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult({this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
      };
}

class DeviceLocationService {
  DeviceLocationService._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static String? _cachedSummary;

  /// Safely fetches the current device location.
  /// If location service is disabled, or permission is not granted, it safely returns null
  /// without popping blocking system dialogs or blocking the user flow.
  static Future<LocationResult> getCurrentLocation({bool requestIfNotGranted = false}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(milliseconds: 600),
        onTimeout: () => false,
      );
      if (!serviceEnabled) {
        return const LocationResult();
      }

      var permission = await Geolocator.checkPermission().timeout(
        const Duration(milliseconds: 600),
        onTimeout: () => LocationPermission.denied,
      );

      if (permission == LocationPermission.denied) {
        if (!requestIfNotGranted) {
          // Do not pop permission dialog or block user transaction creation
          return const LocationResult();
        }
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return const LocationResult();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult();
      }

      // Fast path: Try last known position first (instant from OS cache)
      try {
        final lastKnown = await Geolocator.getLastKnownPosition().timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => null,
        );
        if (lastKnown != null) {
          return LocationResult(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
          );
        }
      } catch (_) {}

      // Fallback: Fetch location with a tight 1.5-second timeout so saving never hangs
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(milliseconds: 1500),
        ),
      ).timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () => throw TimeoutException('Location timeout'),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('Location fetch error (silently ignored): $e');
      return const LocationResult();
    }
  }

  /// Safely gets detailed device information across Web, Android, iOS, and macOS.
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return {
          'platform': 'Web',
          'device_name': '${webInfo.browserName.name} (${webInfo.platform ?? 'Web'})',
          'user_agent': webInfo.userAgent,
          'vendor': webInfo.vendor,
        };
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final androidInfo = await _deviceInfo.androidInfo;
          return {
            'platform': 'Android',
            'device_name': '${androidInfo.brand} ${androidInfo.model}',
            'manufacturer': androidInfo.manufacturer,
            'os_version': 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})',
            'is_physical': androidInfo.isPhysicalDevice,
          };
        case TargetPlatform.iOS:
          final iosInfo = await _deviceInfo.iosInfo;
          return {
            'platform': 'iOS',
            'device_name': iosInfo.name,
            'model': iosInfo.model,
            'os_version': '${iosInfo.systemName} ${iosInfo.systemVersion}',
            'is_physical': iosInfo.isPhysicalDevice,
          };
        case TargetPlatform.macOS:
          final macInfo = await _deviceInfo.macOsInfo;
          return {
            'platform': 'macOS',
            'device_name': macInfo.computerName,
            'model': macInfo.model,
            'os_version': macInfo.osRelease,
          };
        case TargetPlatform.windows:
          final winInfo = await _deviceInfo.windowsInfo;
          return {
            'platform': 'Windows',
            'device_name': winInfo.computerName,
            'os_version': winInfo.displayVersion,
          };
        case TargetPlatform.linux:
          final linuxInfo = await _deviceInfo.linuxInfo;
          return {
            'platform': 'Linux',
            'device_name': linuxInfo.name,
            'os_version': linuxInfo.version,
          };
        case TargetPlatform.fuchsia:
          return {
            'platform': 'Fuchsia',
            'device_name': 'Fuchsia device',
          };
      }
    } catch (e) {
      debugPrint('Device info fetch error: $e');
      return {'platform': defaultTargetPlatform.name};
    }
  }

  /// Returns a clean one-line device description e.g. "Google Pixel 9 (Android 15)" or "Chrome (macOS)"
  static Future<String> getDeviceSummary() async {
    if (_cachedSummary != null) return _cachedSummary!;
    try {
      final info = await getDeviceInfo();
      final name = info['device_name'] ?? info['model'] ?? info['platform'] ?? 'Unknown device';
      _cachedSummary = name.toString();
      return _cachedSummary!;
    } catch (_) {
      return 'Unknown Device';
    }
  }
}
