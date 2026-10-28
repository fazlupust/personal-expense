import 'dart:async';
import 'package:collection/collection.dart';
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

  /// Resolves the best available Bengali locale on the current device.
  static Future<String> getBestBengaliLocale() async {
    try {
      final locales = await _speech.locales();
      if (locales.isNotEmpty) {
        // 1. Bangladesh Bengali (bn_BD, bn-BD)
        final bnBd = locales.firstWhereOrNull((l) {
          final id = l.localeId.toLowerCase().replaceAll('-', '_');
          return id == 'bn_bd';
        });
        if (bnBd != null) return bnBd.localeId;

        // 2. Any Bengali (bn_IN, bn-IN, bn)
        final anyBn = locales.firstWhereOrNull((l) {
          return l.localeId.toLowerCase().startsWith('bn');
        });
        if (anyBn != null) return anyBn.localeId;
      }
    } catch (e) {
      debugPrint('getBestBengaliLocale error: $e');
    }
    return 'bn_BD';
  }

  /// Starts listening and streams transcribed text back via [onResult].
  /// Defaults to Bengali (bn_BD / bn_IN) so speaking Bangla transcribes in Bengali directly.
  static Future<bool> startListening({
    required void Function(String text) onResult,
    required void Function(bool listening) onListeningChange,
    String? localeOverride,
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

      // Prioritize Bengali locale on device so Bangla speech recognition works accurately
      final String localeId = localeOverride ?? await getBestBengaliLocale();

      debugPrint('[VoiceService] Listening with locale: $localeId');
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
        listenFor: const Duration(seconds: 25),
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

    // Common Bengali spoken word amount mapping
    final lower = cleaned.toLowerCase();
    const bnWords = {
      'একশত': '100', 'একশো': '100', 'একশ': '100',
      'দুইশত': '200', 'দুইশো': '200', 'দুইশ': '200',
      'তিনশত': '300', 'তিনশো': '300', 'তিনশ': '300',
      'চারশত': '400', 'চারশো': '400', 'চারশ': '400',
      'পাঁচশত': '500', 'পাঁচশো': '500', 'পাঁচশ': '500',
      'ছয়শত': '600', 'ছয়শো': '600', 'ছয়শ': '600',
      'সাতশত': '700', 'সাতশো': '700', 'সাতশ': '700',
      'আটশত': '800', 'আটশো': '800', 'আটশ': '800',
      'নয়শত': '900', 'নয়শো': '900', 'নয়শ': '900',
      'এক হাজার': '1000', 'হাজার': '1000',
      'দুই হাজার': '2000', 'পাঁচ হাজার': '5000', 'দশ হাজার': '10000',
      'বিশ হাজার': '20000', 'পঞ্চাশ হাজার': '50000',
      'এক লাখ': '100000', 'এক লক্ষ': '100000',
      'দশ': '10', 'বিশ': '20', 'কুড়ি': '20', 'ত্রিশ': '30',
      'চল্লিশ': '40', 'পঞ্চাশ': '50', 'ষাট': '60', 'সত্তর': '70',
      'আশি': '80', 'নব্বই': '90',
    };

    for (final entry in bnWords.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return cleaned.replaceAll(RegExp(r'[^0-9.]'), '');
  }
}
