import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/auth_provider.dart';

final userOrderHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final userId = authState.valueOrNull?.id;

  if (userId == null) {
    return [];
  }

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          // Ensure created_at is a DateTime
          final createdAt = data['created_at'];
          return {
            ...data,
            'id': doc.id,
            'created_at':
                createdAt is Timestamp ? createdAt.toDate() : createdAt,
          };
        })
        .toList(growable: false);
  } catch (e) {
    throw Exception('Failed to load order history: $e');
  }
});
