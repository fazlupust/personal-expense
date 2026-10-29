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
              categories = _mergeWithDefaults(list);
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
            categories = _mergeWithDefaults(list);
            update();
          }
        }, onError: (err) {
          debugPrint('Categories stream error: $err');
        });
      }
    }
  }

  List<CategoryModel> _mergeWithDefaults(List<CategoryModel> list) {
    final result = List<CategoryModel>.from(list);
    for (final def in AppConstants.defaultCategories) {
      final exists = result.any((c) =>
          c.type == def.type &&
          (c.nameEn.toLowerCase() == def.nameEn.toLowerCase() ||
              c.nameBn == def.nameBn ||
              c.name == def.nameEn ||
              c.name == def.nameBn));
      if (!exists) {
        result.add(def);
      }
    }
    return result;
  }

  List<CategoryModel> byType(EntryType t) => categories.where((c) => c.type == t).toList();

  String emojiOf(EntryType t, String name) {
    for (final c in categories) {
      if (c.type == t && (c.nameEn == name || c.nameBn == name || c.name == name)) return c.emoji;
    }
    if (name == 'Deposit' || name == 'ডিপোজিট' || name == 'Deposit / Investment' || name == 'ডিপোজিট ও বিনিয়োগ') return '🏦';
    if (name == 'Investment' || name == 'বিনিয়োগ' || name == 'বিনিয়োগ ও মুনাফা') return '📈';
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
    if (nameCtrl.text != val) {
      nameCtrl.text = val;
    }
    _validateDuplicate();
  }

  void onNameBnChanged(String val) {
    if (nameBnCtrl.text != val) {
      nameBnCtrl.text = val;
    }
    _validateDuplicate();
  }

  void _validateDuplicate() {
    final en = nameCtrl.text.trim();
    final bn = nameBnCtrl.text.trim();

    if (en.isEmpty && bn.isEmpty) {
      if (nameError != null) {
        nameError = null;
        update();
      }
      return;
    }

    if ((en.isNotEmpty && isDuplicate(en, formType)) ||
        (bn.isNotEmpty && isDuplicate(bn, formType))) {
      nameError = 'That category already exists.';
      update();
    } else if (nameError != null) {
      nameError = null;
      update();
    }
  }

  void setType(EntryType t) {
    formType = t;
    _validateDuplicate();
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

  String categoryDisplayName(EntryType t, String rawName, bool isBn) {
    for (final c in categories) {
      if (c.type == t && (c.nameEn == rawName || c.nameBn == rawName || c.name == rawName)) {
        return c.displayName(isBn);
      }
    }
    for (final d in AppConstants.defaultCategories) {
      if (d.type == t && (d.nameEn == rawName || d.nameBn == rawName || d.name == rawName)) {
        return d.displayName(isBn);
      }
    }
    return rawName.tr;
  }

  Future<void> create() async {
    final name = nameCtrl.text.trim();
    final nameBn = nameBnCtrl.text.trim();

    if (name.isEmpty && nameBn.isEmpty) {
      nameError = 'Enter a category name.';
      update();
      return;
    }

    if ((name.isNotEmpty && isDuplicate(name, formType)) ||
        (nameBn.isNotEmpty && isDuplicate(nameBn, formType))) {
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
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 12,
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
        backgroundColor: const Color(0xFF1B5E20),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 12,
      );
    }
  }
}
