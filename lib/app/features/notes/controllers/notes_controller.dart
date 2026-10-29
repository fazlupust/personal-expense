import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/note_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/note_service.dart';
import '../../../data/services/voice_service.dart';

class NotesController extends GetxController {
  static NotesController get to => Get.find<NotesController>();

  final titleCtrl = TextEditingController();
  final personCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final searchCtrl = TextEditingController();

  DateTime formDate = DateTime.now();
  NoteModel? editingNote;
  String? titleError;

  List<NoteModel> notes = [];
  bool isLoading = true;
  bool isSaving = false;
  String searchQuery = '';
  String selectedPerson = 'All';

  // Amount privacy visibility state
  bool isAmountHidden = false;
  static const _amountHiddenKey = 'personal_expense_notes_amount_hidden';

  void toggleAmountVisibility() {
    isAmountHidden = !isAmountHidden;
    _prefs?.setBool(_amountHiddenKey, isAmountHidden);
    update();
  }

  // Voice recognition states
  bool isListeningTitle = false;
  bool isListeningPerson = false;
  bool isListeningAmount = false;
  bool isListeningNote = false;

  StreamSubscription<List<NoteModel>>? _sub;
  static const _cacheKey = 'personal_expense_notes_cache';

  SharedPreferences? get _prefs =>
      Get.isRegistered<SharedPreferences>() ? Get.find<SharedPreferences>() : null;

  @override
  void onInit() {
    super.onInit();
    _initNotes();
  }

  @override
  void onClose() {
    stopAllVoice();
    titleCtrl.dispose();
    personCtrl.dispose();
    amountCtrl.dispose();
    notesCtrl.dispose();
    searchCtrl.dispose();
    _sub?.cancel();
    super.onClose();
  }

  String _effectiveCacheKey([String? uidOverride]) {
    final uid = uidOverride ?? (Get.isRegistered<AuthService>() ? (Get.find<AuthService>().currentUid ?? '') : '');
    return uid.isNotEmpty ? '${_cacheKey}_$uid' : _cacheKey;
  }

  void _loadCachedNotes([String? uidOverride]) {
    try {
      final p = _prefs;
      if (p == null) return;
      final key = _effectiveCacheKey(uidOverride);
      final raw = p.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        notes = decoded
            .map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        notes.sort((a, b) => b.date.compareTo(a.date));
      } else {
        notes = [];
      }
    } catch (e) {
      debugPrint('Error loading cached notes: $e');
    }
  }

  void _saveCachedNotes(List<NoteModel> list, [String? uidOverride]) {
    try {
      final p = _prefs;
      if (p == null) return;
      final key = _effectiveCacheKey(uidOverride);
      final encoded = jsonEncode(list.map((n) => n.toJson()).toList());
      p.setString(key, encoded);
    } catch (e) {
      debugPrint('Error saving cached notes: $e');
    }
  }

  void _initNotes() {
    isAmountHidden = _prefs?.getBool(_amountHiddenKey) ?? false;
    _loadCachedNotes();
    if (notes.isNotEmpty) {
      isLoading = false;
      update();
    }

    if (Get.isRegistered<NoteService>() && Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      final service = Get.find<NoteService>();

      ever(auth.firebaseUser, (user) {
        _sub?.cancel();
        if (user != null) {
          _loadCachedNotes(user.uid);
          isLoading = notes.isEmpty;
          update();
          _subscribeToUser(user.uid, service);
        } else {
          notes = [];
          isLoading = false;
          update();
        }
      });

      final currentUid = auth.currentUid ?? auth.currentUser?.uid;
      if (currentUid != null && currentUid.isNotEmpty) {
        _subscribeToUser(currentUid, service);
      } else {
        isLoading = false;
        update();
      }
    } else {
      isLoading = false;
      update();
    }
  }

  void _subscribeToUser(String uid, NoteService service) {
    _sub?.cancel();
    if (notes.isEmpty) {
      isLoading = true;
      update();
    }
    _sub = service.streamUserNotes(uid).listen(
      (list) {
        notes = list;
        _saveCachedNotes(list, uid);
        isLoading = false;
        update();
      },
      onError: (err) {
        debugPrint('Notes stream error: $err');
        _loadCachedNotes(uid);
        isLoading = false;
        update();
      },
    );
  }

  Future<void> refreshNotes() async {
    if (Get.isRegistered<NoteService>() && Get.isRegistered<AuthService>()) {
      final auth = Get.find<AuthService>();
      final service = Get.find<NoteService>();
      final currentUid = auth.currentUid ?? auth.currentUser?.uid;
      if (currentUid != null && currentUid.isNotEmpty) {
        _subscribeToUser(currentUid, service);
        await Future.delayed(const Duration(milliseconds: 400));
        return;
      }
    }
    _loadCachedNotes();
    isLoading = false;
    update();
  }

  // --- Voice Input Controls ---

  void _startVoiceForController(
    TextEditingController controller, {
    required void Function(bool listening) setListening,
    void Function()? onAfterInsert,
  }) {
    stopAllVoice();

    // Capture text before and after cursor so we append/insert from cursor without clearing existing text
    final currentText = controller.text;
    final selection = controller.selection;
    final int cursorPos = (selection.isValid && selection.baseOffset >= 0)
        ? selection.baseOffset
        : currentText.length;

    final prefix = currentText.substring(0, cursorPos);
    final suffix = currentText.substring(cursorPos);
    final spacing = (prefix.isNotEmpty && !prefix.endsWith(' ') && !prefix.endsWith('\n'))
        ? ' '
        : '';

    VoiceService.startListening(
      onResult: (words) {
        if (words.isNotEmpty) {
          final inserted = spacing + words;
          controller.value = TextEditingValue(
            text: prefix + inserted + suffix,
            selection: TextSelection.collapsed(offset: prefix.length + inserted.length),
          );
          onAfterInsert?.call();
          update();
        }
      },
      onListeningChange: (listening) {
        setListening(listening);
        update();
      },
    );
  }

  void toggleVoiceTitle() {
    if (isListeningTitle) {
      VoiceService.stop();
      isListeningTitle = false;
      update();
      return;
    }
    _startVoiceForController(
      titleCtrl,
      setListening: (l) => isListeningTitle = l,
      onAfterInsert: () => titleError = null,
    );
  }

  void toggleVoicePerson() {
    if (isListeningPerson) {
      VoiceService.stop();
      isListeningPerson = false;
      update();
      return;
    }
    _startVoiceForController(
      personCtrl,
      setListening: (l) => isListeningPerson = l,
    );
  }

  void toggleVoiceAmount() {
    if (isListeningAmount) {
      VoiceService.stop();
      isListeningAmount = false;
      update();
      return;
    }
    stopAllVoice();
    VoiceService.startListening(
      onResult: (words) {
        final parsed = VoiceService.parseSpokenAmount(words);
        if (parsed.isNotEmpty) {
          amountCtrl.text = parsed;
          update();
        }
      },
      onListeningChange: (listening) {
        isListeningAmount = listening;
        update();
      },
    );
  }

  void toggleVoiceNote() {
    if (isListeningNote) {
      VoiceService.stop();
      isListeningNote = false;
      update();
      return;
    }
    _startVoiceForController(
      notesCtrl,
      setListening: (l) => isListeningNote = l,
    );
  }

  void stopAllVoice() {
    if (isListeningTitle || isListeningPerson || isListeningAmount || isListeningNote) {
      VoiceService.stop();
      isListeningTitle = false;
      isListeningPerson = false;
      isListeningAmount = false;
      isListeningNote = false;
      update();
    }
  }

  // --- End Voice Input Controls ---

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
    if (searchCtrl.text != q) {
      searchCtrl.text = q;
    }
    update();
  }

  void clearSearch() {
    searchQuery = '';
    searchCtrl.clear();
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
    stopAllVoice();
    editingNote = null;
    titleCtrl.clear();
    personCtrl.text = selectedPerson != 'All' ? selectedPerson : '';
    amountCtrl.clear();
    notesCtrl.clear();
    formDate = DateTime.now();
    titleError = null;
    isSaving = false;
    update();
  }

  void openEdit(NoteModel note) {
    stopAllVoice();
    editingNote = note;
    titleCtrl.text = note.title;
    personCtrl.text = note.personName;
    amountCtrl.text = note.amount > 0 ? (note.amount % 1 == 0 ? note.amount.toInt().toString() : note.amount.toString()) : '';
    notesCtrl.text = note.notes;
    formDate = note.date;
    titleError = null;
    isSaving = false;
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
    isSaving = true;
    update();

    final person = personCtrl.text.trim();
    final amountText = amountCtrl.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;
    final noteDesc = notesCtrl.text.trim();

    try {
      final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
      final service = Get.isRegistered<NoteService>() ? Get.find<NoteService>() : null;
      final uid = auth?.currentUid ?? auth?.currentUser?.uid;
      final canCloudSave = auth != null && auth.isLoggedIn && service != null && uid != null && uid.isNotEmpty;

      if (editingNote != null) {
        final updated = editingNote!.copyWith(
          title: title,
          personName: person,
          amount: amount,
          notes: noteDesc,
          date: formDate,
          updatedAt: DateTime.now(),
        );

        if (canCloudSave && updated.id.isNotEmpty) {
          try {
            await service.updateNote(updated);
          } catch (e) {
            debugPrint('Cloud update failed, updating locally: $e');
          }
        }
        final idx = notes.indexWhere((n) => n.id == editingNote!.id);
        if (idx != -1) {
          notes[idx] = updated;
        } else {
          notes.insert(0, updated);
        }
        _saveCachedNotes(notes);
      } else {
        String newId = DateTime.now().millisecondsSinceEpoch.toString();
        if (canCloudSave) {
          try {
            newId = await service.addNote(
              title: title,
              date: formDate,
              personName: person,
              amount: amount,
              notes: noteDesc,
            );
          } catch (e) {
            debugPrint('Cloud add failed, saving locally: $e');
          }
        }
        final newNote = NoteModel(
          id: newId,
          userId: uid ?? '',
          title: title,
          date: formDate,
          personName: person,
          amount: amount,
          notes: noteDesc,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        notes.insert(0, newNote);
        _saveCachedNotes(notes);
      }

      isSaving = false;
      update();
      if (Get.context != null) {
        Get.snackbar(
          'Success'.tr,
          (editingNote != null ? 'Note updated successfully.' : 'Note saved successfully.').tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1F8A5B),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 12,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Save note error: $e');
      isSaving = false;
      update();
      if (Get.context != null) {
        Get.snackbar(
          'Alert'.tr,
          'Failed to save note. Please try again.'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 12,
        );
      }
      return false;
    }
  }

  Future<void> delete(NoteModel note) async {
    final bool canShowDialog = Get.context != null;
    if (canShowDialog) {
      Get.dialog(
        PopScope(
          canPop: false,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Deleting note...'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
    }

    try {
      // 1. Instantly remove from local list and cache for snappy UI response
      notes.removeWhere((n) => n.id == note.id);
      _saveCachedNotes(notes);
      update();

      // 2. Perform reliable cloud delete with minimal delay for smooth UX
      final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
      final service = Get.isRegistered<NoteService>() ? Get.find<NoteService>() : null;
      final uid = auth?.currentUid ?? auth?.currentUser?.uid;
      final canCloudDelete = auth != null && auth.isLoggedIn && service != null && uid != null && uid.isNotEmpty;

      if (canCloudDelete && note.id.isNotEmpty) {
        try {
          await Future.wait([
            service.deleteNote(note.id),
            Future.delayed(const Duration(milliseconds: 500)),
          ]);
        } catch (e) {
          debugPrint('Cloud delete error: $e');
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 400));
      }

      // Close loading dialog
      if (canShowDialog && (Get.isDialogOpen ?? false)) {
        Get.back();
      }

      if (Get.context != null) {
        Get.snackbar(
          'Success'.tr,
          'Note deleted successfully.'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF1F8A5B),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 12,
        );
      }
    } catch (e) {
      if (canShowDialog && (Get.isDialogOpen ?? false)) {
        Get.back();
      }
      debugPrint('Delete note error: $e');
      if (Get.context != null) {
        Get.snackbar(
          'Alert'.tr,
          'Failed to delete note. Please try again.'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFDC2626),
          colorText: Colors.white,
          icon: const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: 12,
        );
      }
    }
  }
}
