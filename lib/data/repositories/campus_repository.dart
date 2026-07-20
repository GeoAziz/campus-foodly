import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/campus.dart';
import '../services/firebase_service.dart';

abstract class CampusRepository {
  Future<List<Campus>> fetchAllCampuses();
  Future<Campus?> fetchCampusById(String campusId);
}

class FirestoreCampusRepository implements CampusRepository {
  FirestoreCampusRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final MockCampusRepository _mockRepository = MockCampusRepository();

  @override
  Future<List<Campus>> fetchAllCampuses() async {
    try {
      final snapshot = await _firestore
          .collection('campuses')
          .where('is_active', isEqualTo: true)
          .get();

      // If Firestore returns empty results, fall back to mock data
      if (snapshot.docs.isEmpty) {
        return _mockRepository.fetchAllCampuses();
      }

      return snapshot.docs
          .map((doc) => Campus.fromMap(doc.id, doc.data()))
          .toList(growable: false);
    } catch (e) {
      // Fall back to mock data if Firestore is unavailable
      return _mockRepository.fetchAllCampuses();
    }
  }

  @override
  Future<Campus?> fetchCampusById(String campusId) async {
    try {
      final doc = await _firestore.collection('campuses').doc(campusId).get();
      if (doc.exists) {
        return Campus.fromMap(doc.id, doc.data() ?? {});
      }
      // Fall back to mock data if not found
      return _mockRepository.fetchCampusById(campusId);
    } catch (e) {
      // Fall back to mock data if Firestore is unavailable
      return _mockRepository.fetchCampusById(campusId);
    }
  }
}

class MockCampusRepository implements CampusRepository {
  @override
  Future<List<Campus>> fetchAllCampuses() async {
    return const [
      Campus(
        id: 'kca-university',
        name: 'KCA University',
        shortName: 'KCA',
        latitude: -1.2547,
        longitude: 36.7674,
        radiusMeters: 800,
        isActive: true,
        deliveryFee: 50,
        minOrder: 100,
        description: 'KCA University Campus',
      ),
      Campus(
        id: 'usiu-africa',
        name: 'USIU-Africa',
        shortName: 'USIU',
        latitude: -1.2341,
        longitude: 36.7620,
        radiusMeters: 800,
        isActive: true,
        deliveryFee: 50,
        minOrder: 100,
        description: 'USIU-Africa Campus',
      ),
      Campus(
        id: 'pac-university',
        name: 'PAC University',
        shortName: 'PAC',
        latitude: -1.2467,
        longitude: 36.7540,
        radiusMeters: 800,
        isActive: true,
        deliveryFee: 40,
        minOrder: 80,
        description: 'PAC University Campus',
      ),
      Campus(
        id: 'kenyatta-university',
        name: 'Kenyatta University',
        shortName: 'KU',
        latitude: -1.2381,
        longitude: 36.8923,
        radiusMeters: 1000,
        isActive: true,
        deliveryFee: 60,
        minOrder: 150,
        description: 'Kenyatta University Main Campus',
      ),
    ];
  }

  @override
  Future<Campus?> fetchCampusById(String campusId) async {
    final campuses = await fetchAllCampuses();
    try {
      return campuses.firstWhere((c) => c.id == campusId);
    } catch (_) {
      return null;
    }
  }
}

CampusRepository buildCampusRepository() {
  if (!FirebaseService.isInitialized) {
    return MockCampusRepository();
  }

  return FirestoreCampusRepository(FirebaseFirestore.instance);
}
