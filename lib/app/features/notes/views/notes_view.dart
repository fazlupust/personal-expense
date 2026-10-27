import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        actions: [
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFilteredPerson ? Icons.person_rounded : Icons.account_balance_wallet_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isFilteredPerson ? c.selectedPerson : 'All Notes Summary'.tr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${Fmt.count(list.length)} ${'notes'.tr}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Total Calculated Amount'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            Fmt.money(c.totalAmount),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (c.notesWithAmountCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${Fmt.count(c.notesWithAmountCount)} ${'notes with financial amount'.tr}',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Search Box
                  TextField(
                    onChanged: c.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search notes by title, person, or note...'.tr,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: c.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => c.setSearchQuery(''),
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
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          for (final person in persons) ...[
                            ChoiceChip(
                              avatar: Icon(
                                Icons.person_rounded,
                                size: 14,
                                color: c.selectedPerson == person ? Colors.white : p.mute,
                              ),
                              label: Text(person),
                              selected: c.selectedPerson == person,
                              onSelected: (_) => c.selectPerson(person),
                              selectedColor: p.income,
                              labelStyle: TextStyle(
                                color: c.selectedPerson == person ? Colors.white : p.ink,
                                fontWeight: c.selectedPerson == person ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12,
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
    required this.onTap,
    required this.onDelete,
  });

  final int serial;
  final NoteModel note;
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
                    // S.L Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.income.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$serial',
                        style: TextStyle(
                          fontSize: 11,
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
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                          if (note.hasPerson) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline_rounded, size: 13, color: p.income),
                                const SizedBox(width: 4),
                                Text(
                                  note.personName,
                                  style: TextStyle(
                                    fontSize: 12,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: p.line),
                        ),
                        child: Text(
                          Fmt.money(note.amount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.income,
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
                      fontSize: 13,
                      color: p.ink.withOpacity(0.85),
                      height: 1.35,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Bottom row: Date, Location, and Action Buttons
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: p.mute),
                    const SizedBox(width: 4),
                    Text(
                      Fmt.date(note.date, 'd MMM yyyy'),
                      style: TextStyle(fontSize: 11, color: p.mute),
                    ),
                    if (note.hasLocation) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.location_on_outlined, size: 12, color: p.income),
                      const SizedBox(width: 2),
                      Text(
                        '${note.latitude!.toStringAsFixed(2)}, ${note.longitude!.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 11, color: p.mute),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 16, color: p.mute),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Edit Note'.tr,
                      onPressed: onTap,
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, size: 16, color: p.expense),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete Note'.tr,
                      onPressed: onDelete,
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
