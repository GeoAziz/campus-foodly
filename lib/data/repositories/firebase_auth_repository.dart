import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    return AppUser.fromFirebaseUser(user);
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await (() async {
      try {
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (error) {
        debugPrint(
          'FirebaseAuth signInWithEmailAndPassword failed '
          'code=${error.code} message=${error.message}',
        );

        if (error.code == 'network-request-failed') {
          throw FirebaseAuthException(
            code: error.code,
            message: 'Could not reach Firebase Auth. On emulator, verify '
                'internet connectivity, Google Play services, and Android '
                'SHA/API key setup in Firebase.',
          );
        }

        rethrow;
      }
    })();

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Sign in failed',
      );
    }

    return AppUser.fromFirebaseUser(user);
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await (() async {
      try {
        return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (error) {
        debugPrint(
          'FirebaseAuth createUserWithEmailAndPassword failed '
          'code=${error.code} message=${error.message}',
        );
        rethrow;
      }
    })();

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Sign up failed',
      );
    }

    if (displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName.trim());
      await user.reload();
    }

    final appUser = AppUser.fromFirebaseUser(
      _auth.currentUser ?? user,
      role: 'user',
    );

    // Write user document with required uid and role fields for Firestore rules compliance
    await FirebaseFirestore.instance.collection('users').doc(appUser.id).set(
          appUser.copyWith(displayName: displayName.trim()).toMap(),
          SetOptions(merge: true),
        );

    return appUser;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user currently signed in',
      );
    }

    if (user.email == null) {
      throw FirebaseAuthException(
        code: 'no-email',
        message: 'User has no email associated',
      );
    }

    try {
      // Reauthenticate with current password
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        ),
      );

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw FirebaseAuthException(
          code: 'wrong-password',
          message: 'Current password is incorrect',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
