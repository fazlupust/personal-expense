import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../data/models/entry_type.dart';
import '../controllers/categories_controller.dart';
import 'components/category_form_card.dart';
import 'components/category_list_card.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Categories',
        showBackButton: true,
      ),
      body: SafeArea(
        child: GetBuilder<CategoriesController>(
          builder: (c) => ContentWrap(
            bottomSpace: 24,
            child: AdaptiveColumns(
              left: [CategoryFormCard(controller: c)],
              right: [
                CategoryListCard(
                  title: 'Expense categories',
                  items: c.byType(EntryType.expense),
                  onDelete: c.delete,
                ),
                CategoryListCard(
                  title: 'Income categories',
                  items: c.byType(EntryType.income),
                  onDelete: c.delete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
