import 'package:riverpod/riverpod.dart';

import '../../../data/providers/auth_provider.dart';
import '../../../data/repositories/auth_repository.dart';

class PasswordChangeState {
  const PasswordChangeState({
    this.currentPassword = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.isLoading = false,
    this.error,
    this.success = false,
    this.showCurrentPassword = false,
    this.showNewPassword = false,
    this.showConfirmPassword = false,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  final bool isLoading;
  final String? error;
  final bool success;
  final bool showCurrentPassword;
  final bool showNewPassword;
  final bool showConfirmPassword;

  PasswordChangeState copyWith({
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
    bool? isLoading,
    String? error,
    bool? success,
    bool? showCurrentPassword,
    bool? showNewPassword,
    bool? showConfirmPassword,
  }) {
    return PasswordChangeState(
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      success: success ?? this.success,
      showCurrentPassword: showCurrentPassword ?? this.showCurrentPassword,
      showNewPassword: showNewPassword ?? this.showNewPassword,
      showConfirmPassword: showConfirmPassword ?? this.showConfirmPassword,
    );
  }
}

class PasswordChangeController extends StateNotifier<PasswordChangeState> {
  PasswordChangeController(this._authRepository)
      : super(const PasswordChangeState());

  final AuthRepository _authRepository;

  void updateCurrentPassword(String value) {
    state = state.copyWith(currentPassword: value, error: null);
  }

  void updateNewPassword(String value) {
    state = state.copyWith(newPassword: value, error: null);
  }

  void updateConfirmPassword(String value) {
    state = state.copyWith(confirmPassword: value, error: null);
  }

  void toggleCurrentPasswordVisibility() {
    state = state.copyWith(
      showCurrentPassword: !state.showCurrentPassword,
    );
  }

  void toggleNewPasswordVisibility() {
    state = state.copyWith(
      showNewPassword: !state.showNewPassword,
    );
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      showConfirmPassword: !state.showConfirmPassword,
    );
  }

  String? validateNewPassword() {
    if (state.newPassword.isEmpty) {
      return 'New password is required';
    }
    if (state.newPassword.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (state.newPassword != state.confirmPassword) {
      return 'Passwords do not match';
    }
    if (state.newPassword == state.currentPassword) {
      return 'New password must be different from current password';
    }
    return null;
  }

  Future<void> changePassword() async {
    final validationError = validateNewPassword();
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return;
    }

    if (state.currentPassword.isEmpty) {
      state = state.copyWith(error: 'Current password is required');
      return;
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authRepository.changePassword(
        currentPassword: state.currentPassword,
        newPassword: state.newPassword,
      );

      state = state.copyWith(
        isLoading: false,
        success: true,
        currentPassword: '',
        newPassword: '',
        confirmPassword: '',
      );

      // Clear success flag after a moment
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(success: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e.toString()),
      );
    }
  }

  String _extractErrorMessage(String error) {
    if (error.contains('wrong-password') ||
        error.contains('Current password is incorrect')) {
      return 'Current password is incorrect';
    }
    if (error.contains('weak-password')) {
      return 'Password is too weak';
    }
    if (error.contains('requires-recent-login')) {
      return 'Please sign out and sign in again before changing password';
    }
    return 'Failed to change password: $error';
  }

  void reset() {
    state = const PasswordChangeState();
  }
}

final passwordChangeControllerProvider =
    StateNotifierProvider<PasswordChangeController, PasswordChangeState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return PasswordChangeController(authRepository);
});
