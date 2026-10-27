import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/services/auth_service.dart';

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
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: p.bg, shape: BoxShape.circle),
                      child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat.name.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, color: p.ink),
                      ),
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
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: Text(isDefault ? 'Delete Default Category?'.tr : 'Delete Category'.tr),
        content: Text(isDefault
            ? 'This is a default category. As a developer, are you sure you want to delete "${cat.name.tr}"?'.tr
            : 'Are you sure you want to delete "${cat.name.tr}"?'.tr),
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
}
