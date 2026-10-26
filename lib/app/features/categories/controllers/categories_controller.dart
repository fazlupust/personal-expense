import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/entry_type.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/category_service.dart';

class CategoriesController extends GetxController {
  CategoriesController([SharedPreferences? _]);

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
          _sub = service.streamCategories().listen((list) {
            if (list.isNotEmpty) {
              categories = list;
              update();
            }
          }, onError: (err) {
            debugPrint('Categories stream error: $err');
          });
        }
      });

      if (auth.isLoggedIn) {
        service.seedDefaultsIfEmpty();
        _sub = service.streamCategories().listen((list) {
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

  void setType(EntryType t) {
    formType = t;
    nameError = null;
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
    if (name.isEmpty && nameBn.isEmpty) {
      nameError = 'Enter a category name.';
      update();
      return;
    }

    final effectiveEn = name.isNotEmpty ? name : nameBn;
    final effectiveBn = nameBn.isNotEmpty ? nameBn : name;

    final exists = categories.any(
      (c) => c.type == formType && (c.nameEn.toLowerCase() == effectiveEn.toLowerCase() || c.nameBn == effectiveBn),
    );
    if (exists) {
      nameError = 'That category already exists.';
      update();
      return;
    }

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
  }

  Future<void> delete(CategoryModel c) async {
    if (Get.isRegistered<CategoryService>() && Get.isRegistered<AuthService>() && Get.find<AuthService>().isLoggedIn && c.id.isNotEmpty) {
      await Get.find<CategoryService>().softDeleteCategory(c.id);
    } else {
      categories.remove(c);
    }
    update();
  }
}
