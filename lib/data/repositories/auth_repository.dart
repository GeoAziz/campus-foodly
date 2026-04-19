import '../models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> signOut();
}
