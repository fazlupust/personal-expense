import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_widgets.dart';
import '../../../../data/models/category_model.dart';

class CategoryListCard extends StatelessWidget {
  const CategoryListCard({super.key, required this.title, required this.items, required this.onDelete});
  final String title;
  final List<CategoryModel> items;
  final ValueChanged<CategoryModel> onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return AppCard(
      title: title,
      flush: true,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            Container(
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
                    child: Text(items[i].emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[i].name.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, color: p.ink),
                    ),
                  ),
                  if (items[i].isDefault)
                    Text('Default'.tr, style: TextStyle(fontSize: 12, color: p.mute))
                  else
                    IconButton(
                      tooltip: 'Delete category'.tr,
                      icon: Icon(Icons.delete_outline, color: p.expense),
                      onPressed: () => onDelete(items[i]),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
