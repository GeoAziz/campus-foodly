import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/campus.dart';
import '../repositories/campus_repository.dart';

final campusRepositoryProvider = Provider<CampusRepository>(
  (ref) => buildCampusRepository(),
);

final allCampusesProvider = FutureProvider<List<Campus>>(
  (ref) => ref.watch(campusRepositoryProvider).fetchAllCampuses(),
);

final selectedCampusIdProvider =
    StateNotifierProvider<SelectedCampusIdNotifier, String?>(
  (ref) => SelectedCampusIdNotifier(),
);

final selectedCampusProvider = FutureProvider<Campus?>((ref) async {
  final campusId = ref.watch(selectedCampusIdProvider);
  if (campusId == null) return null;
  return ref
      .watch(campusRepositoryProvider)
      .fetchCampusById(campusId);
});

class SelectedCampusIdNotifier extends StateNotifier<String?> {
  SelectedCampusIdNotifier() : super(null) {
    _initializeFromPreferences();
  }

  Future<void> _initializeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('selected_campus_id');
      state = saved;
    } catch (_) {
      // Ignore preferences errors
    }
  }

  Future<void> setSelectedCampus(String campusId) async {
    state = campusId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_campus_id', campusId);
    } catch (_) {
      // Log but don't crash on preferences errors
    }

    // Also update Firestore if user is authenticated
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set(
              {'campusId': campusId},
              SetOptions(merge: true),
            );
      }
    } catch (_) {
      // Log but don't crash on Firestore errors
    }
  }

  Future<void> clearSelectedCampus() async {
    state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_campus_id');
    } catch (_) {
      // Log but don't crash on preferences errors
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set(
              {'campusId': FieldValue.delete()},
              SetOptions(merge: true),
            );
      }
    } catch (_) {
      // Log but don't crash on Firestore errors
    }
  }
}
