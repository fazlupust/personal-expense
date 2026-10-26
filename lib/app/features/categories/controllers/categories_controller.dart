import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/entry_type.dart';

class CategoriesController extends GetxController {
  CategoriesController(this._prefs);
  final SharedPreferences _prefs;

  final nameCtrl = TextEditingController();
  List<CategoryModel> categories = [];
  EntryType formType = EntryType.expense;
  String formEmoji = AppConstants.categoryEmojis.first;
  String? nameError;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    super.onClose();
  }

  void _load() {
    final raw = _prefs.getString(AppConstants.prefsCategories);
    if (raw != null) {
      try {
        categories = (jsonDecode(raw) as List)
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        categories = [];
      }
    }
    if (categories.isEmpty) {
      categories = List.of(AppConstants.defaultCategories);
      _persist();
    }
  }

  Future<void> _persist() => _prefs.setString(
        AppConstants.prefsCategories,
        jsonEncode(categories.map((c) => c.toJson()).toList()),
      );

  List<CategoryModel> byType(EntryType t) => categories.where((c) => c.type == t).toList();

  String emojiOf(EntryType t, String name) {
    for (final c in categories) {
      if (c.type == t && c.name == name) return c.emoji;
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

  void create() {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      nameError = 'Enter a category name.';
      update();
      return;
    }
    final exists = categories.any(
      (c) => c.type == formType && c.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      nameError = 'That category already exists.';
      update();
      return;
    }
    categories.add(CategoryModel(name: name, emoji: formEmoji, type: formType));
    nameCtrl.clear();
    nameError = null;
    _persist();
    update();
  }

  void delete(CategoryModel c) {
    if (c.isDefault) return;
    categories.remove(c);
    _persist();
    update();
  }
}
