import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/category_service.dart';

class CategoriesController extends GetxController {
  CategoriesController() {
    _initCategories();
  }

  final nameCtrl = TextEditingController();
  final nameBnCtrl = TextEditingController();
  List<CategoryModel> categories = [];
  EntryType formType = EntryType.expense;
  String formEmoji = AppConstants.categoryEmojis.first;
  String? nameError;

  StreamSubscription<List<CategoryModel>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _initCategories();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    nameBnCtrl.dispose();
    _sub?.cancel();
    super.onClose();
  }

  void _initCategories() {
    // Default fallback categories
    categories = List.of(AppConstants.defaultCategories);

    if (Get.isRegistered<CategoryService>() && Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      final service = Get.find<CategoryService>();

      ever(auth.firebaseUser, (user) {
        _sub?.cancel();
        if (user != null) {
          service.seedDefaultsIfEmpty();
          _sub = service.streamCategories(user.uid).listen((list) {
            if (list.isNotEmpty) {
              categories = list;
              update();
            }
          }, onError: (err) {
            debugPrint('Categories stream error: $err');
          });
        } else {
          categories = List.of(AppConstants.defaultCategories);
          update();
        }
      });

      if (auth.isLoggedIn) {
        service.seedDefaultsIfEmpty();
        _sub = service.streamCategories(auth.currentUid).listen((list) {
          if (list.isNotEmpty) {
            categories = list;
            update();
          }
        }, onError: (err) {
          debugPrint('Categories stream error: $err');
        });
      }
    }
  }

  List<CategoryModel> byType(EntryType t) => categories.where((c) => c.type == t).toList();

  String emojiOf(EntryType t, String name) {
    for (final c in categories) {
      if (c.type == t && (c.nameEn == name || c.nameBn == name || c.name == name)) return c.emoji;
    }
    return '•';
  }

  bool isDuplicate(String inputName, EntryType type) {
    final clean = inputName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) return false;

    // Check across all loaded categories
    for (final c in categories) {
      if (c.type != type) continue;

      final en = c.nameEn.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final bn = c.nameBn.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final legacy = c.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final tr = c.name.tr.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      if (clean == en || clean == bn || clean == legacy || clean == tr) {
        return true;
      }
    }

    // Also check default categories as a fallback
    for (final d in AppConstants.defaultCategories) {
      if (d.type != type) continue;
      final en = d.nameEn.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final bn = d.nameBn.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final legacy = d.name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final tr = d.name.tr.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

      if (clean == en || clean == bn || clean == legacy || clean == tr) {
        return true;
      }
    }

    return false;
  }

  void onNameChanged(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      if (nameError != null) {
        nameError = null;
        update();
      }
      return;
    }

    if (isDuplicate(trimmed, formType)) {
      nameError = 'That category already exists.';
      update();
    } else if (nameError != null) {
      nameError = null;
      update();
    }
  }

  void setType(EntryType t) {
    formType = t;
    // Re-check duplicate on type switch
    final current = nameCtrl.text.trim();
    if (current.isNotEmpty && isDuplicate(current, formType)) {
      nameError = 'That category already exists.';
    } else {
      nameError = null;
    }
    update();
  }

  void setEmoji(String e) {
    formEmoji = e;
    update();
  }

  void clearError() {
    if (nameError != null) {
      nameError = null;
      update();
    }
  }

  Future<void> create() async {
    final name = nameCtrl.text.trim();
    final nameBn = nameBnCtrl.text.trim();
    final effective = name.isNotEmpty ? name : nameBn;

    if (effective.isEmpty) {
      nameError = 'Enter a category name.';
      update();
      return;
    }

    if (isDuplicate(effective, formType)) {
      nameError = 'That category already exists.';
      update();
      Get.snackbar(
        'Alert'.tr,
        'That category already exists.'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final effectiveEn = name.isNotEmpty ? name : nameBn;
    final effectiveBn = nameBn.isNotEmpty ? nameBn : name;

    try {
      if (Get.isRegistered<CategoryService>() && Get.isRegistered<AuthService>() && Get.find<AuthService>().isLoggedIn) {
        await Get.find<CategoryService>().addCategory(
          nameBn: effectiveBn,
          nameEn: effectiveEn,
          type: formType,
          emoji: formEmoji,
        );
      } else {
        categories.add(CategoryModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          nameBn: effectiveBn,
          nameEn: effectiveEn,
          type: formType,
          emoji: formEmoji,
        ));
      }

      nameCtrl.clear();
      nameBnCtrl.clear();
      nameError = null;
      update();

      Get.snackbar(
        'Success'.tr,
        'Category created successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      nameError = 'That category already exists.';
      update();
    }
  }

  Future<void> delete(CategoryModel c) async {
    final isDev = Get.isRegistered<AuthService>() && Get.find<AuthService>().isDeveloper;
    final isDefault = c.isDefaultCategory || c.isDefault || AppConstants.isDefaultCategory(c.nameEn, c.nameBn, c.name);

    if (isDefault && !isDev) {
      if (Get.context != null) {
        Get.snackbar(
          'Alert'.tr,
          'Default categories cannot be deleted.'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    if (Get.isRegistered<CategoryService>() && Get.isRegistered<AuthService>() && Get.find<AuthService>().isLoggedIn && c.id.isNotEmpty) {
      await Get.find<CategoryService>().softDeleteCategory(c.id);
    } else {
      categories.remove(c);
    }
    update();

    if (Get.context != null) {
      Get.snackbar(
        'Success'.tr,
        'Category deleted successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
