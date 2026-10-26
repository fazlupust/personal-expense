import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/note_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/note_service.dart';

class NotesController extends GetxController {
  static NotesController get to => Get.find<NotesController>();

  final titleCtrl = TextEditingController();
  final personCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  DateTime formDate = DateTime.now();
  NoteModel? editingNote;
  String? titleError;

  List<NoteModel> notes = [];
  String searchQuery = '';
  String selectedPerson = 'All';

  StreamSubscription<List<NoteModel>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _initNotes();
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    personCtrl.dispose();
    amountCtrl.dispose();
    notesCtrl.dispose();
    _sub?.cancel();
    super.onClose();
  }

  void _initNotes() {
    if (Get.isRegistered<NoteService>() && Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      final service = Get.find<NoteService>();

      ever(auth.firebaseUser, (user) {
        _sub?.cancel();
        if (user != null) {
          _sub = service.streamUserNotes(user.uid).listen((list) {
            notes = list;
            update();
          }, onError: (err) {
            debugPrint('Notes stream error: $err');
          });
        } else {
          notes = [];
          update();
        }
      });

      if (auth.isLoggedIn && auth.currentUid != null) {
        _sub = service.streamUserNotes(auth.currentUid!).listen((list) {
          notes = list;
          update();
        }, onError: (err) {
          debugPrint('Notes stream error: $err');
        });
      }
    }
  }

  /// All unique persons present in notes
  List<String> get uniquePersons {
    final set = <String>{};
    for (final n in notes) {
      final trimmed = n.personName.trim();
      if (trimmed.isNotEmpty) set.add(trimmed);
    }
    final list = set.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  /// Filtered notes based on selected person and search query
  List<NoteModel> get filteredNotes {
    return notes.where((n) {
      // 1. Person filter
      if (selectedPerson != 'All') {
        if (n.personName.trim().toLowerCase() != selectedPerson.trim().toLowerCase()) {
          return false;
        }
      }

      // 2. Search query filter
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchTitle = n.title.toLowerCase().contains(q);
        final matchPerson = n.personName.toLowerCase().contains(q);
        final matchNotes = n.notes.toLowerCase().contains(q);
        final matchAmount = n.hasAmount && n.amount.toString().contains(q);
        if (!matchTitle && !matchPerson && !matchNotes && !matchAmount) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Total sum of amount for the currently filtered notes
  double get totalAmount {
    return filteredNotes.fold<double>(0.0, (sum, n) => sum + n.amount);
  }

  /// Count of filtered notes with an amount > 0
  int get notesWithAmountCount {
    return filteredNotes.where((n) => n.hasAmount).length;
  }

  void setSearchQuery(String q) {
    searchQuery = q;
    update();
  }

  void selectPerson(String person) {
    selectedPerson = person;
    update();
  }

  void setFormDate(DateTime d) {
    formDate = d;
    update();
  }

  void openCreate() {
    editingNote = null;
    titleCtrl.clear();
    personCtrl.text = selectedPerson != 'All' ? selectedPerson : '';
    amountCtrl.clear();
    notesCtrl.clear();
    formDate = DateTime.now();
    titleError = null;
    update();
  }

  void openEdit(NoteModel note) {
    editingNote = note;
    titleCtrl.text = note.title;
    personCtrl.text = note.personName;
    amountCtrl.text = note.amount > 0 ? (note.amount % 1 == 0 ? note.amount.toInt().toString() : note.amount.toString()) : '';
    notesCtrl.text = note.notes;
    formDate = note.date;
    titleError = null;
    update();
  }

  Future<bool> save() async {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) {
      titleError = 'Enter a note title.'.tr;
      update();
      return false;
    }
    titleError = null;

    final person = personCtrl.text.trim();
    final amountText = amountCtrl.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;
    final noteDesc = notesCtrl.text.trim();

    try {
      if (editingNote != null) {
        final updated = editingNote!.copyWith(
          title: title,
          personName: person,
          amount: amount,
          notes: noteDesc,
          date: formDate,
          updatedAt: DateTime.now(),
        );

        if (Get.isRegistered<NoteService>() && Get.isRegistered<AuthService>() && Get.find<AuthService>().isLoggedIn) {
          await Get.find<NoteService>().updateNote(updated);
        } else {
          final idx = notes.indexWhere((n) => n.id == editingNote!.id);
          if (idx != -1) {
            notes[idx] = updated;
          }
        }
      } else {
        if (Get.isRegistered<NoteService>() && Get.isRegistered<AuthService>() && Get.find<AuthService>().isLoggedIn) {
          await Get.find<NoteService>().addNote(
            title: title,
            date: formDate,
            personName: person,
            amount: amount,
            notes: noteDesc,
          );
        } else {
          final newNote = NoteModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            date: formDate,
            personName: person,
            amount: amount,
            notes: noteDesc,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          notes.insert(0, newNote);
        }
      }

      update();
      if (Get.context != null) {
        Get.snackbar(
          'Success'.tr,
          (editingNote != null ? 'Note updated successfully.' : 'Note saved successfully.').tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
      return true;
    } catch (e) {
      debugPrint('Save note error: $e');
      if (Get.context != null) {
        Get.snackbar(
          'Alert'.tr,
          'Failed to save note. Please try again.'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return false;
    }
  }

  Future<void> delete(NoteModel note) async {
    try {
      if (Get.isRegistered<NoteService>() && Get.isRegistered<AuthService>() && Get.find<AuthService>().isLoggedIn && note.id.isNotEmpty) {
        await Get.find<NoteService>().deleteNote(note.id);
      } else {
        notes.removeWhere((n) => n.id == note.id);
      }
      update();
      if (Get.context != null) {
        Get.snackbar(
          'Success'.tr,
          'Note deleted successfully.'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('Delete note error: $e');
    }
  }
}
