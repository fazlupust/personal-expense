import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportFileSharer {
  const ExportFileSharer._();

  static Future<void> shareFile(
    BuildContext context, {
    required String content,
    required String fileName,
    required String mimeType,
    required String subject,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(content, encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType, name: fileName)],
        subject: subject,
        text: subject,
        sharePositionOrigin: origin,
      );
    } catch (_) {
      try {
        await Share.share(
          content,
          subject: subject,
          sharePositionOrigin: origin,
        );
      } catch (e) {
        await Clipboard.setData(ClipboardData(text: content));
        Get.snackbar(
          'Copied to Clipboard'.tr,
          'Sharing failed. Content copied to clipboard!'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1F8A5B),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 12,
        );
      }
    }
  }

  static Future<void> shareBytesFile(
    BuildContext context, {
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    required String subject,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType, name: fileName)],
        subject: subject,
        text: subject,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      Get.snackbar(
        'Export Failed'.tr,
        'Could not share file: $e'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFDC2626),
        colorText: Colors.white,
        icon: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 12,
      );
    }
  }

  static void copyToClipboard(BuildContext context, String data, String title) {
    Clipboard.setData(ClipboardData(text: data));
    Get.snackbar(
      title.tr,
      'Copied to clipboard! You can paste it into Excel or Google Sheets.'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF1F8A5B),
      colorText: Colors.white,
      icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
      duration: const Duration(seconds: 3),
      maxWidth: 420,
      margin: const EdgeInsets.all(14),
      borderRadius: 12,
    );
  }
}
