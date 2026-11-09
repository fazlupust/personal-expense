import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/services/auth_service.dart';
import '../../controllers/categories_controller.dart';

class CategoryListCard extends StatelessWidget {
  const CategoryListCard({super.key, required this.title, required this.items, required this.onDelete});
  final String title;
  final List<CategoryModel> items;
  final ValueChanged<CategoryModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isDev = Get.isRegistered<AuthService>() && Get.find<AuthService>().isDeveloper;

    return AppCard(
      title: title,
      flush: true,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Builder(builder: (ctx) {
              final cat = items[i];
              final isDefault = cat.isDefaultCategory ||
                  cat.isDefault ||
                  AppConstants.isDefaultCategory(cat.nameEn, cat.nameBn, cat.name);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: i < items.length - 1 ? Border(bottom: BorderSide(color: p.line)) : null,
                ),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: (!isDefault || isDev) ? () => _showIconPicker(ctx, cat) : null,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: p.bg, shape: BoxShape.circle),
                            child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                          ),
                          if (!isDefault || isDev)
                            Positioned(
                              right: -1,
                              bottom: -1,
                              child: Container(
                                padding: const EdgeInsets.all(2.5),
                                decoration: BoxDecoration(
                                  color: isDefault ? p.income : p.ink.withOpacity(0.65),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 9, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Builder(builder: (ctx) {
                        final isBn = Get.locale?.languageCode == 'bn';
                        final mainName = cat.displayName(isBn).isNotEmpty
                            ? cat.displayName(isBn)
                            : cat.name.tr;
                        final subName = isBn ? cat.nameEn : cat.nameBn;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mainName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.ink),
                            ),
                            if (subName.isNotEmpty && subName != mainName)
                              Text(
                                subName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11.5, color: p.mute),
                              ),
                          ],
                        );
                      }),
                    ),
                    if (!isDefault || isDev)
                      IconButton(
                        tooltip: isDefault ? 'Change icon (Dev)'.tr : 'Change icon'.tr,
                        icon: Icon(Icons.edit_outlined, size: 20, color: p.ink),
                        onPressed: () => _showIconPicker(ctx, cat),
                      ),
                    if (isDefault) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.mute.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Default'.tr,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.mute),
                        ),
                      ),
                      if (isDev) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Delete default category (Dev)'.tr,
                          icon: Icon(Icons.delete_forever, size: 20, color: p.expense),
                          onPressed: () => _confirmDelete(ctx, cat, true),
                        ),
                      ],
                    ] else
                      IconButton(
                        tooltip: 'Delete category'.tr,
                        icon: Icon(Icons.delete_outline, size: 20, color: p.expense),
                        onPressed: () => _confirmDelete(ctx, cat, false),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CategoryModel cat, bool isDefault) async {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';
    final nameToShow = cat.displayName(isBn).isNotEmpty ? cat.displayName(isBn) : cat.name.tr;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(isDefault ? 'Delete Default Category?'.tr : 'Delete Category'.tr),
        content: Text(isDefault
            ? 'This is a default category. As a developer, are you sure you want to delete "$nameToShow"?'.tr
            : 'Are you sure you want to delete "$nameToShow"?'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: p.expense),
            child: Text('Delete'.tr),
          ),
        ],
      ),
    );
    if (ok == true) {
      onDelete(cat);
    }
  }

  void _showIconPicker(BuildContext context, CategoryModel cat) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 520),
      builder: (_) => _CategoryIconPickerSheet(category: cat),
    );
  }
}

/// Bottom sheet dialog allowing developer and users to choose or type any emoji for a category
class _CategoryIconPickerSheet extends StatefulWidget {
  const _CategoryIconPickerSheet({required this.category});
  final CategoryModel category;

  @override
  State<_CategoryIconPickerSheet> createState() => _CategoryIconPickerSheetState();
}

class _CategoryIconPickerSheetState extends State<_CategoryIconPickerSheet> {
  final TextEditingController _customEmojiCtrl = TextEditingController();
  late String _selectedEmoji;

  // Rich palette of popular category icons categorized by theme
  static const List<String> allEmojis = [
    // Fruits & Food
    '🍎', '🍏', '🍇', '🍉', '🍊', '🍋', '🍌', '🍍', '🥭', '🍐', '🍑', '🍒', '🍓', '🫐', '🥝', '🍅', '🥥', '🥑', '🥦', '🥕',
    '🍜', '🛒', '🍔', '🍕', '🍞', '🥐', '🍗', '🥩', '🥓', '🍣', '🍤', '🍲', '🥗', '☕', '🧃', '🍵', '🍼', '🍦', '🍩', '🍫',
    // Daily Life, Home, Living
    '🏠', '🏡', '🏢', '🛍️', '👕', '👗', '👟', '💡', '⚡', '🌐', '📱', '💻', '🧹', '🧺', '🧼', '📦', '🎁', '🔑', '🏷️', '📻',
    // Health & Family
    '👶', '💊', '🩺', '🏥', '🩹', '💉', '🏋️', '🧘', '💇', '👨‍👩‍👧', '🤝', '🤲', '🕌', '📚', '🎓', '🎬', '🎮', '🚗', '🚌', '⛽',
    // Money & Finance
    '💸', '💰', '💳', '🏦', '🪙', '💵', '📈', '📉', '📊', '🧾', '💼', '🏪', '✈️', '🛡️', '🔧', '📦', '🌍', '🎖️',
  ];

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.category.emoji;
  }

  @override
  void dispose() {
    _customEmojiCtrl.dispose();
    super.dispose();
  }

  void _applyEmoji(String emoji) {
    final clean = emoji.trim();
    if (clean.isEmpty) return;
    setState(() => _selectedEmoji = clean);
    if (Get.isRegistered<CategoriesController>()) {
      Get.find<CategoriesController>().updateCategoryEmoji(widget.category, clean);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';
    final nameToShow = widget.category.displayName(isBn).isNotEmpty
        ? widget.category.displayName(isBn)
        : widget.category.name.tr;

    return Material(
      color: p.card,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                color: p.income,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: Text(_selectedEmoji, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Change Category Icon'.tr,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            nameToShow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Custom emoji / symbol input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customEmojiCtrl,
                        decoration: InputDecoration(
                          hintText: 'Type or paste any emoji (e.g. 🍎, 🍉, 💸)'.tr,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          prefixIcon: const Icon(Icons.emoji_emotions_outlined, size: 20),
                        ),
                        onSubmitted: (val) => _applyEmoji(val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.income,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _applyEmoji(_customEmojiCtrl.text),
                      child: Text('Set'.tr),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Text(
                  'Or pick an icon below:'.tr,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.mute),
                ),
              ),

              // Emoji Grid
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final emoji in allEmojis)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _applyEmoji(emoji),
                          child: Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: emoji == _selectedEmoji ? p.income.withOpacity(0.18) : p.bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: emoji == _selectedEmoji ? p.income : p.line,
                                width: emoji == _selectedEmoji ? 2 : 1,
                              ),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
