import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../features/settings/controllers/settings_controller.dart';

class VoiceService {
  VoiceService._();

  static final SpeechToText _speech = SpeechToText();
  static bool _initialized = false;
  static bool _available = false;

  static bool get isListening => _speech.isListening;

  /// Initializes the speech recognition engine safely.
  static Future<bool> init() async {
    if (_initialized) return _available;
    try {
      _available = await _speech.initialize(
        onError: (SpeechRecognitionError error) {
          debugPrint('Speech recognition error: ${error.errorMsg}');
        },
        onStatus: (String status) {
          debugPrint('Speech recognition status: $status');
        },
      );
      _initialized = true;
      return _available;
    } catch (e) {
      debugPrint('Speech initialize exception: $e');
      _initialized = true;
      _available = false;
      return false;
    }
  }

  /// Starts listening and streams transcribed text back via [onResult].
  /// Automatically uses app locale (bn_BD or en_US).
  static Future<bool> startListening({
    required void Function(String text) onResult,
    required void Function(bool listening) onListeningChange,
  }) async {
    try {
      final hasInit = await init();
      if (!hasInit) {
        onListeningChange(false);
        Get.snackbar(
          'Voice Input'.tr,
          'Microphone not available or permission denied'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return false;
      }

      if (_speech.isListening) {
        await _speech.stop();
        onListeningChange(false);
        return false;
      }

      // Determine locale based on settings
      String localeId = 'en_US';
      if (Get.isRegistered<SettingsController>()) {
        final lang = Get.find<SettingsController>().langCode;
        if (lang == 'bn') {
          localeId = 'bn_BD';
        }
      }

      onListeningChange(true);

      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          final words = result.recognizedWords;
          if (words.isNotEmpty) {
            onResult(words);
          }
          if (result.finalResult) {
            onListeningChange(false);
          }
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        localeId: localeId,
      );
      return true;
    } catch (e) {
      debugPrint('startListening error: $e');
      onListeningChange(false);
      return false;
    }
  }

  /// Stops listening immediately.
  static Future<void> stop() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (e) {
      debugPrint('stop listening error: $e');
    }
  }

  /// Parses spoken amount into numeric string (e.g. "পাঁচশত" or "500.50" or "1200 taka").
  static String parseSpokenAmount(String text) {
    const bnToEnDigits = {
      '০': '0',
      '১': '1',
      '২': '2',
      '৩': '3',
      '৪': '4',
      '৫': '5',
      '৬': '6',
      '৭': '7',
      '৮': '8',
      '৯': '9',
    };

    var cleaned = text.trim();
    bnToEnDigits.forEach((bn, en) {
      cleaned = cleaned.replaceAll(bn, en);
    });

    // Remove currency words like টাকা, taka, tk, $, ৳
    cleaned = cleaned
        .replaceAll(RegExp(r'(টাকা|টাকার|টাকায়|taka|tk|bdt|\$|৳)', caseSensitive: false), '')
        .trim();

    // Match numbers like 500, 500.50
    final match = RegExp(r'[0-9]+(\.[0-9]+)?').firstMatch(cleaned);
    if (match != null) {
      return match.group(0)!;
    }

    return cleaned.replaceAll(RegExp(r'[^0-9.]'), '');
  }
}
