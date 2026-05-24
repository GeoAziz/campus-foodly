import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final entryTabIndexProvider = StateProvider<int>((ref) => 0);

class PhoneLoginState {
  const PhoneLoginState({
    this.phoneNumber = '',
    this.submitted = false,
    this.verificationId = '',
    this.resendToken,
    this.status = PhoneAuthStatus.idle,
    this.errorMessage,
  });

  final String phoneNumber;
  final bool submitted;
  final String verificationId;
  final int? resendToken;
  final PhoneAuthStatus status;
  final String? errorMessage;

  PhoneLoginState copyWith({
    String? phoneNumber,
    bool? submitted,
    String? verificationId,
    int? resendToken,
    PhoneAuthStatus? status,
    String? errorMessage,
  }) {
    return PhoneLoginState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      submitted: submitted ?? this.submitted,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

enum PhoneAuthStatus {
  idle,
  sendingCode,
  codeSent,
  verifying,
  verified,
  failed,
}

class PhoneLoginController extends StateNotifier<PhoneLoginState> {
  PhoneLoginController() : super(const PhoneLoginState());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void updatePhoneNumber(String value) {
    state = state.copyWith(phoneNumber: value);
  }

  void markSubmitted() {
    state = state.copyWith(submitted: true);
  }

  Future<bool> sendVerificationCode() async {
    if (_auth.app.name.isEmpty) {
      state = state.copyWith(
        status: PhoneAuthStatus.failed,
        errorMessage: 'Firebase is not initialized.',
      );
      return false;
    }

    final completer = Completer<bool>();
    state = state.copyWith(
      submitted: true,
      status: PhoneAuthStatus.sendingCode,
      errorMessage: null,
    );

    await _auth.verifyPhoneNumber(
      phoneNumber: state.phoneNumber.trim(),
      forceResendingToken: state.resendToken,
      verificationCompleted: (credential) async {
        try {
          await _auth.signInWithCredential(credential);
          state = state.copyWith(status: PhoneAuthStatus.verified);
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        } catch (error) {
          state = state.copyWith(
            status: PhoneAuthStatus.failed,
            errorMessage: error.toString(),
          );
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        }
      },
      verificationFailed: (error) {
        state = state.copyWith(
          status: PhoneAuthStatus.failed,
          errorMessage: error.message ?? error.toString(),
        );
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
      codeSent: (verificationId, resendToken) {
        state = state.copyWith(
          verificationId: verificationId,
          resendToken: resendToken,
          status: PhoneAuthStatus.codeSent,
        );
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        state = state.copyWith(
          verificationId: verificationId,
          status: PhoneAuthStatus.codeSent,
        );
      },
    );

    return completer.future;
  }

  Future<bool> verifyCode(String smsCode) async {
    if (state.verificationId.isEmpty) {
      state = state.copyWith(
        status: PhoneAuthStatus.failed,
        errorMessage: 'Verification code not sent yet.',
      );
      return false;
    }

    state =
        state.copyWith(status: PhoneAuthStatus.verifying, errorMessage: null);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      state = state.copyWith(status: PhoneAuthStatus.verified);
      return true;
    } catch (error) {
      state = state.copyWith(
        status: PhoneAuthStatus.failed,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  void reset() {
    state = const PhoneLoginState();
  }
}

/// Phone login provider with auto-dispose to prevent memory leaks
/// Disposes when user navigates away from phone login screen
final phoneLoginControllerProvider =
    StateNotifierProvider.autoDispose<PhoneLoginController, PhoneLoginState>(
  (ref) => PhoneLoginController(),
);

class SearchUiState {
  const SearchUiState({
    this.query = '',
    this.isSearching = false,
  });

  final String query;
  final bool isSearching;

  SearchUiState copyWith({
    String? query,
    bool? isSearching,
  }) {
    return SearchUiState(
      query: query ?? this.query,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class SearchUiController extends StateNotifier<SearchUiState> {
  SearchUiController() : super(const SearchUiState());

  void updateQuery(String query) {
    state = state.copyWith(
      query: query,
      isSearching: query.trim().isNotEmpty,
    );
  }

  void clearSearch() {
    state = const SearchUiState();
  }
}

final searchUiControllerProvider =
    StateNotifierProvider<SearchUiController, SearchUiState>(
  (ref) => SearchUiController(),
);

class AddToOrderState {
  const AddToOrderState({
    this.choiceOfTopCookie = 1,
    this.choiceOfBottomCookie = 1,
    this.numOfItems = 1,
  });

  final int choiceOfTopCookie;
  final int choiceOfBottomCookie;
  final int numOfItems;

  AddToOrderState copyWith({
    int? choiceOfTopCookie,
    int? choiceOfBottomCookie,
    int? numOfItems,
  }) {
    return AddToOrderState(
      choiceOfTopCookie: choiceOfTopCookie ?? this.choiceOfTopCookie,
      choiceOfBottomCookie: choiceOfBottomCookie ?? this.choiceOfBottomCookie,
      numOfItems: numOfItems ?? this.numOfItems,
    );
  }
}

class AddToOrderController extends StateNotifier<AddToOrderState> {
  AddToOrderController() : super(const AddToOrderState());

  void selectTopCookie(int index) {
    state = state.copyWith(choiceOfTopCookie: index);
  }

  void selectBottomCookie(int index) {
    state = state.copyWith(choiceOfBottomCookie: index);
  }

  void incrementItems() {
    state = state.copyWith(numOfItems: state.numOfItems + 1);
  }

  void decrementItems() {
    if (state.numOfItems <= 1) {
      return;
    }
    state = state.copyWith(numOfItems: state.numOfItems - 1);
  }
}

final addToOrderControllerProvider =
    StateNotifierProvider.autoDispose<AddToOrderController, AddToOrderState>(
  (ref) => AddToOrderController(),
);
