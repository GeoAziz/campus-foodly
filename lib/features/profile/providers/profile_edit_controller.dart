import 'package:riverpod/riverpod.dart';

import '../models/profile_data.dart';
import '../repositories/profile_repository.dart';
import 'profile_provider.dart';

class ProfileEditState {
  const ProfileEditState({
    this.mode = ProfileEditMode.view,
    this.profileData,
    this.displayName,
    this.phone,
    this.bio,
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  final ProfileEditMode mode;
  final ProfileData? profileData;
  final String? displayName;
  final String? phone;
  final String? bio;
  final bool isLoading;
  final String? error;
  final bool success;

  ProfileEditState copyWith({
    ProfileEditMode? mode,
    ProfileData? profileData,
    String? displayName,
    String? phone,
    String? bio,
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return ProfileEditState(
      mode: mode ?? this.mode,
      profileData: profileData ?? this.profileData,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      success: success ?? this.success,
    );
  }
}

enum ProfileEditMode { view, edit }

class ProfileEditController extends StateNotifier<ProfileEditState> {
  ProfileEditController(this._repository, this._uid)
      : super(const ProfileEditState()) {
    _loadProfile();
  }

  final ProfileRepository _repository;
  final String _uid;

  Future<void> _loadProfile() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final profile = await _repository.getProfile(_uid);
      state = state.copyWith(
        isLoading: false,
        profileData: profile,
        displayName: profile?.displayName,
        phone: profile?.phone,
        bio: profile?.bio,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void enterEditMode() {
    state = state.copyWith(mode: ProfileEditMode.edit);
  }

  void cancelEdit() {
    state = state.copyWith(
      mode: ProfileEditMode.view,
      displayName: state.profileData?.displayName,
      phone: state.profileData?.phone,
      bio: state.profileData?.bio,
      error: null,
    );
  }

  void updateDisplayName(String value) {
    state = state.copyWith(displayName: value, error: null);
  }

  void updatePhone(String value) {
    state = state.copyWith(phone: value, error: null);
  }

  void updateBio(String value) {
    state = state.copyWith(bio: value, error: null);
  }

  Future<void> saveProfile() async {
    if (state.profileData == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final updated = state.profileData!.copyWith(
        displayName: state.displayName,
        phone: state.phone,
        bio: state.bio,
      );

      await _repository.updateProfile(_uid, updated);

      state = state.copyWith(
        isLoading: false,
        mode: ProfileEditMode.view,
        profileData: updated,
        success: true,
      );

      // Clear success flag after a moment
      await Future.delayed(const Duration(seconds: 2));
      state = state.copyWith(success: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final profileEditControllerProvider = StateNotifierProvider.family<
    ProfileEditController, ProfileEditState, String>((ref, uid) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileEditController(repository, uid);
});
