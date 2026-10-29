part of 'prayer_tasbih_controller.dart';

extension PrayerTasbihFirestoreSync on PrayerTasbihController {
  // --- Firestore Sync & User-Isolation ---
  void _scheduleFirestoreSync() {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    _firestoreDebounceTimer?.cancel();
    _firestoreDebounceTimer = Timer(const Duration(milliseconds: 600), () {
      _flushToFirestore(uid);
    });
  }

  Future<void> flushNowForTesting([String? uidOverride]) async {
    final uid = uidOverride ?? _currentUid;
    if (uid.isNotEmpty) {
      await _flushToFirestore(uid);
    }
  }

  Future<void> _flushToFirestore(String uid) async {
    if (uid.isEmpty) {
      debugPrint('[TasbihFirestore] Skip sync: No user UID found. Saved locally in SharedPreferences.');
      return;
    }
    try {
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final dayCounts = _zikirDailyCounts[todayKey] ?? <String, int>{};

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 1. Day-wise and zikir-wise document: users/{uid}/tasbih_daily/{todayKey}
      final dayDoc = db
          .collection('users')
          .doc(uid)
          .collection('tasbih_daily')
          .doc(todayKey);

      batch.set(
        dayDoc,
        {
          'user_id': uid,
          'date': todayKey,
          'counts': Map<String, dynamic>.from(dayCounts),
          'day_total': _todayTotal,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2. Summary document with lifetime total and zikir-wise totals
      final summaryDoc = db
          .collection('users')
          .doc(uid)
          .collection('tasbih_summary')
          .doc('summary');

      batch.set(
        summaryDoc,
        {
          'user_id': uid,
          'lifetime_total': _lifetimeTotal,
          'today_total': _todayTotal,
          'last_date': todayKey,
          'zikir_lifetime_counts': Map<String, dynamic>.from(_zikirLifetimeCounts),
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 3. Day-wise individual zikir entries across all recorded days in _zikirDailyCounts
      final allDays = Map<String, Map<String, int>>.from(_zikirDailyCounts);
      if (!allDays.containsKey(todayKey)) {
        allDays[todayKey] = dayCounts;
      }

      for (final dayEntry in allDays.entries) {
        final dKey = dayEntry.key;
        for (final entry in dayEntry.value.entries) {
          final zId = entry.key;
          final count = entry.value;
          if (count <= 0) continue;

          final zikir = allZikirs.firstWhere(
            (z) => z.id == zId,
            orElse: () => ZikirItem(
              id: zId,
              arabic: '',
              titleBn: zId,
              titleEn: zId,
              meaningBn: '',
              meaningEn: '',
            ),
          );

          final docId = '${dKey}_$zId';
          final entryData = {
            'id': docId,
            'user_id': uid,
            'jikir_id': zId,
            'jikir_name': zikir.titleBn,
            'jikir_name_en': zikir.titleEn,
            'arabic': zikir.arabic,
            'category': zikir.category.name,
            'jikir_count': count,
            'jikircound': count, // alias for query flexibility
            'date': dKey,
            'updated_at': FieldValue.serverTimestamp(),
          };

          // 3a. Root collection 'jikir' (e.g. jikir/{uid}_{date}_{zId})
          final jikirDocId = '${uid}_${dKey}_$zId';
          final jikirDoc = db.collection('jikir').doc(jikirDocId);
          batch.set(
            jikirDoc,
            {
              ...entryData,
              'id': jikirDocId,
            },
            SetOptions(merge: true),
          );

          // 3b. Root collection: tasbih_entries/{uid}_{date}_{zId}
          final rootDocId = '${uid}_${dKey}_$zId';
          final rootDoc = db.collection('tasbih_entries').doc(rootDocId);
          batch.set(
            rootDoc,
            {
              ...entryData,
              'id': rootDocId,
            },
            SetOptions(merge: true),
          );

          // 3c. User subcollection: users/{uid}/tasbih_entries/{date}_{zId}
          final entryDoc = db
              .collection('users')
              .doc(uid)
              .collection('tasbih_entries')
              .doc(docId);
          batch.set(entryDoc, entryData, SetOptions(merge: true));
        }
      }

      await batch.commit();
      debugPrint('[TasbihFirestore] Synced to Firestore for user: $uid (date: $todayKey, counts: $dayCounts)');
    } catch (e) {
      debugPrint('[TasbihFirestore] Error syncing to Firestore: $e');
    }
  }

  Future<void> _syncFromFirestore(String uid) async {
    if (uid.isEmpty) return;
    try {
      final db = FirebaseFirestore.instance;

      // 1. Fetch summary document
      final summaryDoc = await db
          .collection('users')
          .doc(uid)
          .collection('tasbih_summary')
          .doc('summary')
          .get();

      if (summaryDoc.exists && summaryDoc.data() != null) {
        final data = summaryDoc.data()!;
        final remoteLifetime = (data['lifetime_total'] as num?)?.toInt() ?? 0;
        if (remoteLifetime > _lifetimeTotal) {
          _lifetimeTotal = remoteLifetime;
        }

        final remoteZikirCounts = data['zikir_lifetime_counts'] as Map<String, dynamic>?;
        if (remoteZikirCounts != null) {
          remoteZikirCounts.forEach((k, v) {
            final cnt = (v as num).toInt();
            _zikirLifetimeCounts[k] = max(_zikirLifetimeCounts[k] ?? 0, cnt);
          });
        }
      }

      // 2. Fetch daily documents (limit to recent 90 days for fast loading)
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final dailySnap = await db
          .collection('users')
          .doc(uid)
          .collection('tasbih_daily')
          .limit(90)
          .get();

      for (final doc in dailySnap.docs) {
        final dateKey = doc.id;
        final counts = doc.data()['counts'] as Map<String, dynamic>?;
        if (counts != null) {
          final dayMap = _zikirDailyCounts.putIfAbsent(dateKey, () => <String, int>{});
          counts.forEach((k, v) {
            final cnt = (v as num).toInt();
            dayMap[k] = max(dayMap[k] ?? 0, cnt);
          });
        }
      }

      // 3. Fetch individual day-wise entries from root collection 'jikir', 'tasbih_entries' or users/{uid}/tasbih_entries
      try {
        final jikirSnap = await db
            .collection('jikir')
            .where('user_id', isEqualTo: uid)
            .limit(300)
            .get();

        if (jikirSnap.docs.isNotEmpty) {
          for (final doc in jikirSnap.docs) {
            final entry = TasbihEntryModel.fromFirestore(doc);
            final dayMap = _zikirDailyCounts.putIfAbsent(entry.date, () => <String, int>{});
            dayMap[entry.jikirId] = max(dayMap[entry.jikirId] ?? 0, entry.jikirCount);
          }
        } else {
          final rootEntriesSnap = await db
              .collection('tasbih_entries')
              .where('user_id', isEqualTo: uid)
              .limit(300)
              .get();

          if (rootEntriesSnap.docs.isNotEmpty) {
            for (final doc in rootEntriesSnap.docs) {
              final entry = TasbihEntryModel.fromFirestore(doc);
              final dayMap = _zikirDailyCounts.putIfAbsent(entry.date, () => <String, int>{});
              dayMap[entry.jikirId] = max(dayMap[entry.jikirId] ?? 0, entry.jikirCount);
            }
          } else {
            final entriesSnap = await db
                .collection('users')
                .doc(uid)
                .collection('tasbih_entries')
                .orderBy('date', descending: true)
                .limit(300)
                .get();

            if (entriesSnap.docs.isNotEmpty) {
              for (final doc in entriesSnap.docs) {
                final entry = TasbihEntryModel.fromFirestore(doc);
                final dayMap = _zikirDailyCounts.putIfAbsent(entry.date, () => <String, int>{});
                dayMap[entry.jikirId] = max(dayMap[entry.jikirId] ?? 0, entry.jikirCount);
              }
            }
          }
        }
      } catch (err) {
        debugPrint('[TasbihFirestore] Note: entries collection fetch: $err');
      }

      // Re-evaluate today's total from day map
      final todayMap = _zikirDailyCounts[todayKey];
      if (todayMap != null && todayMap.isNotEmpty) {
        int sumToday = 0;
        todayMap.forEach((_, c) => sumToday += c);
        if (sumToday > _todayTotal) {
          _todayTotal = sumToday;
        }
      }

      _rebuildHistoryEntriesLocal();
      await _persistTasbihData(uid);
      update();
    } catch (e) {
      debugPrint('[TasbihFirestore] Error fetching from Firestore: $e');
    }
  }

  void _rebuildHistoryEntriesLocal() {
    final list = <TasbihEntryModel>[];
    _zikirDailyCounts.forEach((dateKey, map) {
      map.forEach((zId, cnt) {
        if (cnt > 0) {
          final zikir = allZikirs.firstWhere(
            (z) => z.id == zId,
            orElse: () => ZikirItem(
              id: zId,
              arabic: '',
              titleBn: zId,
              titleEn: zId,
              meaningBn: '',
              meaningEn: '',
            ),
          );
          list.add(
            TasbihEntryModel(
              id: '${dateKey}_$zId',
              userId: _currentUid,
              jikirId: zId,
              jikirName: zikir.titleBn,
              jikirNameEn: zikir.titleEn,
              arabic: zikir.arabic,
              category: zikir.category.name,
              jikirCount: cnt,
              date: dateKey,
            ),
          );
        }
      });
    });
    list.sort((a, b) {
      final dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      return b.jikirCount.compareTo(a.jikirCount);
    });
    _historyEntries.assignAll(list);
  }

  Future<void> refreshHistoryFromFirestore() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    _isSyncingHistory = true;
    update();
    try {
      if (_todayTotal > 0 || _zikirDailyCounts.isNotEmpty) {
        await _flushToFirestore(uid);
      }
      await _syncFromFirestore(uid);
    } finally {
      _isSyncingHistory = false;
      update();
    }
  }

  // --- Persistence ---
  Future<void> _loadTasbihData([String? uidOverride]) async {
    final uid = uidOverride ?? _currentUid;
    final prefs = await SharedPreferences.getInstance();

    _currentCount = 0;
    _completedCycles = 0;
    _todayTotal = 0;
    _lifetimeTotal = 0;
    _zikirLifetimeCounts.clear();
    _zikirDailyCounts.clear();

    final locationId = prefs.getString(_userKey('prayer_location_id', uid)) ?? 'dhaka';
    _selectedLocation = BangladeshLocation.findById(locationId);
    _isHanafi = prefs.getBool(_userKey('prayer_is_hanafi', uid)) ?? true;
    _hijriOffsetDays = prefs.getInt(_userKey('prayer_hijri_offset', uid)) ?? -1;
    _recalculatePrayerTimes();

    _isVibrationEnabled = prefs.getBool(_userKey('tasbih_vibrate', uid)) ?? true;
    _isSoundEnabled = prefs.getBool(_userKey('tasbih_sound', uid)) ?? true;
    _isCountHidden = prefs.getBool(_userKey('tasbih_hide_count', uid)) ?? false;
    _isZikirCardHidden = prefs.getBool(_userKey('tasbih_hide_zikir_card', uid)) ?? true;
    _isProhibitedAlertOn = prefs.getBool(_userKey('prohibited_alert_on', uid)) ?? true;
    _prohibitedBufferMinutes = prefs.getInt(_userKey('prohibited_buffer_minutes', uid)) ?? 15;

    // Backward compatibility: If user-keyed is not found and un-keyed exists, migrate
    if (uid.isNotEmpty && !prefs.containsKey(_userKey('tasbih_lifetime_total', uid))) {
      final oldLifetime = prefs.getInt('tasbih_lifetime_total');
      if (oldLifetime != null && oldLifetime > 0) {
        _lifetimeTotal = oldLifetime;
        final oldDaily = prefs.getString('tasbih_zikir_daily_counts');
        if (oldDaily != null) {
          try {
            final decoded = jsonDecode(oldDaily) as Map<String, dynamic>;
            decoded.forEach((dateKey, map) {
              if (map is Map) {
                final inner = <String, int>{};
                map.forEach((k, v) => inner[k.toString()] = (v as num).toInt());
                _zikirDailyCounts[dateKey] = inner;
              }
            });
          } catch (_) {}
        }
        final oldLifetimeZikirs = prefs.getString('tasbih_zikir_lifetime_counts');
        if (oldLifetimeZikirs != null) {
          try {
            final decoded = jsonDecode(oldLifetimeZikirs) as Map<String, dynamic>;
            decoded.forEach((k, v) => _zikirLifetimeCounts[k] = (v as num).toInt());
          } catch (_) {}
        }
        await _persistTasbihData(uid);
        // Remove legacy un-keyed prefs so they never bleed to other accounts
        await prefs.remove('tasbih_lifetime_total');
        await prefs.remove('tasbih_zikir_daily_counts');
        await prefs.remove('tasbih_zikir_lifetime_counts');
        await prefs.remove('tasbih_today_total');
        await prefs.remove('tasbih_last_date');
        _scheduleFirestoreSync();
      } else {
        _lifetimeTotal = 0;
      }
    } else {
      _lifetimeTotal = prefs.getInt(_userKey('tasbih_lifetime_total', uid)) ?? 0;
    }

    // Load per-zikir lifetime counts
    final lifetimeJsonStr = prefs.getString(_userKey('tasbih_zikir_lifetime_counts', uid));
    if (lifetimeJsonStr != null) {
      try {
        final decoded = jsonDecode(lifetimeJsonStr) as Map<String, dynamic>;
        _zikirLifetimeCounts.clear();
        decoded.forEach((k, v) => _zikirLifetimeCounts[k] = (v as num).toInt());
      } catch (_) {}
    } else if (uid.isNotEmpty && !prefs.containsKey(_userKey('tasbih_lifetime_total', uid))) {
      // migrated above
    } else {
      _zikirLifetimeCounts.clear();
    }

    // Load per-zikir daily counts
    final dailyJsonStr = prefs.getString(_userKey('tasbih_zikir_daily_counts', uid));
    if (dailyJsonStr != null) {
      try {
        final decoded = jsonDecode(dailyJsonStr) as Map<String, dynamic>;
        _zikirDailyCounts.clear();
        decoded.forEach((dateKey, map) {
          if (map is Map) {
            final inner = <String, int>{};
            map.forEach((k, v) => inner[k.toString()] = (v as num).toInt());
            _zikirDailyCounts[dateKey] = inner;
          }
        });
      } catch (_) {}
    } else if (uid.isNotEmpty && !prefs.containsKey(_userKey('tasbih_lifetime_total', uid))) {
      // migrated above
    } else {
      _zikirDailyCounts.clear();
    }

    // Check if today's count is for today
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = prefs.getString(_userKey('tasbih_last_date', uid)) ?? '';
    if (savedDate == todayKey) {
      _todayTotal = prefs.getInt(_userKey('tasbih_today_total', uid)) ?? 0;
    } else {
      _todayTotal = 0;
      await prefs.setString(_userKey('tasbih_last_date', uid), todayKey);
      await prefs.setInt(_userKey('tasbih_today_total', uid), 0);
    }
    _rebuildHistoryEntriesLocal();
    update();
  }

  Future<void> _persistTasbihData([String? uidOverride]) async {
    final uid = uidOverride ?? _currentUid;
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snapToday = _todayTotal;
    final snapLife = _lifetimeTotal;
    final snapLifetimeZikirs = jsonEncode(_zikirLifetimeCounts);
    final snapDailyZikirs = jsonEncode(_zikirDailyCounts);

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;

    await prefs.setString(_userKey('tasbih_last_date', uid), todayKey);
    await prefs.setInt(_userKey('tasbih_today_total', uid), snapToday);
    await prefs.setInt(_userKey('tasbih_lifetime_total', uid), snapLife);
    await prefs.setString(_userKey('tasbih_zikir_lifetime_counts', uid), snapLifetimeZikirs);
    await prefs.setString(_userKey('tasbih_zikir_daily_counts', uid), snapDailyZikirs);
  }

  Future<void> _persistSettings([String? uidOverride]) async {
    final uid = uidOverride ?? _currentUid;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(_userKey('tasbih_vibrate', uid), _isVibrationEnabled);
    await prefs.setBool(_userKey('tasbih_sound', uid), _isSoundEnabled);
    await prefs.setBool(_userKey('tasbih_hide_count', uid), _isCountHidden);
    await prefs.setBool(_userKey('tasbih_hide_zikir_card', uid), _isZikirCardHidden);
  }
}
