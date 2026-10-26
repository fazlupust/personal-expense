import 'package:cloud_firestore/cloud_firestore.dart';

class AppUpdateModel {
  final bool isActive;
  final bool isForceUpdate;
  final String latestVersion;
  final String minVersion;
  final String title;
  final String message;
  final String playStoreUrl;

  const AppUpdateModel({
    required this.isActive,
    required this.isForceUpdate,
    required this.latestVersion,
    required this.minVersion,
    required this.title,
    required this.message,
    required this.playStoreUrl,
  });

  factory AppUpdateModel.fromMap(Map<String, dynamic> data) {
    // Gracefully handle various possible field names from Firebase / admin
    final active = data['is_active'] == true ||
        data['active_is'] == true ||
        data['isActive'] == true;
    final force = data['is_force_update'] == true ||
        data['is_force'] == true ||
        data['isForceUpdate'] == true;

    return AppUpdateModel(
      isActive: active,
      isForceUpdate: force,
      latestVersion: (data['latest_version'] ?? data['version'] ?? '1.0.0').toString().trim(),
      minVersion: (data['min_version'] ?? '1.0.0').toString().trim(),
      title: (data['title'] ?? 'Update Available').toString().trim(),
      message: (data['message'] ??
              'A new version of Personal Expense is available with new features and improvements. Please update now to get the best experience.')
          .toString()
          .trim(),
      playStoreUrl: (data['play_store_url'] ??
              data['play_store_urls'] ??
              data['paly_stoerl_urpsl'] ??
              data['playStoreUrl'] ??
              'https://play.google.com/store/apps')
          .toString()
          .trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_active': isActive,
      'is_force_update': isForceUpdate,
      'latest_version': latestVersion,
      'min_version': minVersion,
      'title': title,
      'message': message,
      'play_store_url': playStoreUrl,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }
}
