import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/firebase_auth_repository.dart';
import '../services/firebase_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!FirebaseService.isInitialized) {
    throw StateError(
      'Firebase is not initialized. Configure Firebase before using auth.',
    );
  }

  return FirebaseAuthRepository(FirebaseAuth.instance);
});

final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  if (!FirebaseService.isInitialized) {
    return Stream<AppUser?>.error(
      StateError('Firebase auth stream unavailable before initialization.'),
    );
  }

  return FirebaseAuth.instance.authStateChanges().map(
        (user) => user == null ? null : AppUser.fromFirebaseUser(user),
      );
});

class AuthController extends AsyncNotifier<AppUser?> {
  late final AuthRepository _repository;

  @override
  Future<AppUser?> build() async {
    _repository = ref.watch(authRepositoryProvider);

    ref.listen<AsyncValue<AppUser?>>(
      authStateChangesProvider,
      (previous, next) {
        next.whenData((user) {
          state = AsyncValue.data(user);
        });
      },
    );

    return _repository.getCurrentUser();
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    final nextState = await AsyncValue.guard(
      () => _repository.signInWithEmail(email: email, password: password),
    );
    state = nextState;
    return !nextState.hasError && nextState.valueOrNull != null;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    final nextState = await AsyncValue.guard(
      () => _repository.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
    state = nextState;
    return !nextState.hasError && nextState.valueOrNull != null;
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const AsyncValue.loading();
    final nextState = await AsyncValue.guard(
      () => _repository.sendPasswordResetEmail(email: email),
    );
    state = const AsyncValue.data(null);
    return !nextState.hasError;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Unable to connect to Firebase. Check emulator internet and Firebase Android SHA/API key configuration.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again in a moment.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }

  return error.toString();
}
