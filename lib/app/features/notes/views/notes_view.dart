import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../data/models/note_model.dart';
import '../controllers/notes_controller.dart';
import 'components/note_form_sheet.dart';

class NotesView extends StatelessWidget {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Personal Notes & Debts'.tr,
        showBackButton: true,
        showLanguageToggle: false,
        showThemeToggle: false,
        showLogout: false,
        actions: [
          GetBuilder<NotesController>(
            builder: (c) => IconButton(
              icon: Icon(
                c.isAmountHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              ),
              tooltip: c.isAmountHidden ? 'Show amount'.tr : 'Hide amount'.tr,
              onPressed: c.toggleAmountVisibility,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh'.tr,
            onPressed: () {
              if (Get.isRegistered<NotesController>()) {
                Get.find<NotesController>().refreshNotes();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final c = Get.find<NotesController>();
          c.openCreate();
          showNoteFormSheet(context);
        },
        backgroundColor: p.income,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('New Note'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: GetBuilder<NotesController>(
          builder: (c) {
            final list = c.filteredNotes;
            final persons = c.uniquePersons;
            final isFilteredPerson = c.selectedPerson != 'All';

            return RefreshIndicator(
              onRefresh: c.refreshNotes,
              color: p.income,
              child: ContentWrap(
                physics: const AlwaysScrollableScrollPhysics(),
                bottomSpace: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // 1. Total Amount Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF134E35),
                          const Color(0xFF1B6B4C),
                          const Color(0xFF2E8B63),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF134E35).withOpacity(0.32),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isFilteredPerson ? Icons.person_rounded : Icons.account_balance_wallet_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        isFilteredPerson ? c.selectedPerson : 'All Notes Summary'.tr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${Fmt.count(list.length)} ${'notes'.tr}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Total Calculated Amount'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: c.toggleAmountVisibility,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      c.isAmountHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      c.isAmountHidden ? 'Show'.tr : 'Hide'.tr,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: c.toggleAmountVisibility,
                          borderRadius: BorderRadius.circular(8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              c.isAmountHidden ? '${AppConstants.currency} ••••••' : Fmt.money(c.totalAmount),
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: c.isAmountHidden ? 2.0 : -0.5,
                              ),
                            ),
                          ),
                        ),
                        if (c.notesWithAmountCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${Fmt.count(c.notesWithAmountCount)} ${'notes with financial amount'.tr}',
                            style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.85)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Search Box
                  TextField(
                    controller: c.searchCtrl,
                    onChanged: c.setSearchQuery,
                    style: TextStyle(fontSize: 15.5, color: p.ink),
                    decoration: InputDecoration(
                      hintText: 'Search notes by title, person, or note...'.tr,
                      hintStyle: TextStyle(fontSize: 14.5, color: p.mute),
                      prefixIcon: Icon(Icons.search_rounded, size: 21, color: p.mute),
                      suffixIcon: (c.searchQuery.isNotEmpty || c.searchCtrl.text.isNotEmpty)
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, size: 19, color: p.ink),
                              tooltip: 'Clear'.tr,
                              onPressed: c.clearSearch,
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Person Filter Chips
                  if (persons.isNotEmpty) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('All'.tr),
                            selected: c.selectedPerson == 'All',
                            onSelected: (_) => c.selectPerson('All'),
                            selectedColor: p.income,
                            labelStyle: TextStyle(
                              color: c.selectedPerson == 'All' ? Colors.white : p.ink,
                              fontWeight: c.selectedPerson == 'All' ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          for (final person in persons) ...[
                            ChoiceChip(
                              avatar: Icon(
                                Icons.person_rounded,
                                size: 15,
                                color: c.selectedPerson == person ? Colors.white : p.mute,
                              ),
                              label: Text(person),
                              selected: c.selectedPerson == person,
                              onSelected: (_) => c.selectPerson(person),
                              selectedColor: p.income,
                              labelStyle: TextStyle(
                                color: c.selectedPerson == person ? Colors.white : p.ink,
                                fontWeight: c.selectedPerson == person ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 4. Notes List Table / Cards
                  if (c.isLoading && c.notes.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 38,
                              height: 38,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(p.income),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading notes...'.tr,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: p.mute,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (list.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: p.income.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(Icons.note_alt_outlined, size: 34, color: p.income),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No notes found'.tr,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add debts, loans, or personal reminders for people.'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: p.mute),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Column of note tiles
                    for (int i = 0; i < list.length; i++)
                      _NoteCardItem(
                        serial: i + 1,
                        note: list[i],
                        isAmountHidden: c.isAmountHidden,
                        onToggleAmount: c.toggleAmountVisibility,
                        onTap: () {
                          c.openEdit(list[i]);
                          showNoteFormSheet(context);
                        },
                        onDelete: () => _confirmDelete(context, c, list[i]),
                      ),
                  ],
                ],
              ),
            ),
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, NotesController c, NoteModel note) {
    final p = context.pal;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline_rounded, color: p.expense, size: 36),
              const SizedBox(height: 12),
              Text(
                'Delete Note?'.tr,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete this note?'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.mute),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.ink,
                        side: BorderSide(color: p.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Cancel'.tr),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Get.back();
                        c.delete(note);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: p.expense,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Delete'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCardItem extends StatelessWidget {
  const _NoteCardItem({
    required this.serial,
    required this.note,
    required this.isAmountHidden,
    required this.onToggleAmount,
    required this.onTap,
    required this.onDelete,
  });

  final int serial;
  final NoteModel note;
  final bool isAmountHidden;
  final VoidCallback onToggleAmount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: S.L, Title, and Amount badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // S.L Badge (clean number without #)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$serial',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.income,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                          if (note.hasPerson) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline_rounded, size: 15, color: p.income),
                                const SizedBox(width: 4),
                                Text(
                                  note.personName,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: p.income,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Amount if present
                    if (note.hasAmount) ...[
                      InkWell(
                        onTap: onToggleAmount,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: p.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: p.line),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isAmountHidden ? '${AppConstants.currency} ••••••' : Fmt.money(note.amount),
                                style: TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  color: p.income,
                                  letterSpacing: isAmountHidden ? 1.5 : 0,
                                ),
                              ),
                              if (isAmountHidden) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.visibility_off_rounded, size: 14, color: p.mute),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Note description if present
                if (note.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    note.notes,
                    style: TextStyle(
                      fontSize: 15.5,
                      color: p.ink.withOpacity(0.9),
                      height: 1.45,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Bottom row: Date, Time, and Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 13, color: p.mute),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              Fmt.date(note.date, 'd MMM yyyy'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.mute),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time_rounded, size: 13.5, color: p.mute),
                          const SizedBox(width: 4),
                          Text(
                            Fmt.date(note.date, 'hh:mm a'),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: p.mute),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.edit_outlined, size: 18, color: p.mute),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline_rounded, size: 18, color: p.expense),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
