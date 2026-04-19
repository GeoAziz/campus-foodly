import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.phone,
    this.displayName,
    this.photoUrl,
    this.role = 'user',
  });

  final String id; // uid from Firebase Auth
  final String email;
  final String? phone;
  final String? displayName;
  final String? photoUrl;
  final String role; // 'user', 'restaurant', 'delivery', 'admin'

  factory AppUser.fromFirebaseUser(User user, {String role = 'user'}) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      phone: user.phoneNumber,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      role: role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id, // Firestore rules expect 'uid' field
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? photoUrl,
    String? role,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
    );
  }
}
