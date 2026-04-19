import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/address.dart';
import '../repositories/profile_repository.dart';
import 'profile_provider.dart';

class AddressesState {
  const AddressesState({
    this.addresses = const [],
    this.isLoading = false,
    this.error,
    this.selectedAddressId,
  });

  final List<Address> addresses;
  final bool isLoading;
  final String? error;
  final String? selectedAddressId;

  AddressesState copyWith({
    List<Address>? addresses,
    bool? isLoading,
    String? error,
    String? selectedAddressId,
  }) {
    return AddressesState(
      addresses: addresses ?? this.addresses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedAddressId: selectedAddressId ?? this.selectedAddressId,
    );
  }

  Address? get selectedAddress {
    if (selectedAddressId == null) return null;
    try {
      return addresses.firstWhere((addr) => addr.id == selectedAddressId);
    } catch (e) {
      return null;
    }
  }
}

class AddressesController extends StateNotifier<AddressesState> {
  AddressesController(this._repository, this._uid)
      : super(const AddressesState()) {
    _loadAddresses();
  }

  final ProfileRepository _repository;
  final String _uid;

  Future<void> _loadAddresses() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final addresses = await _repository.getAddresses(_uid);
      state = state.copyWith(
        isLoading: false,
        addresses: addresses,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addAddress(Address address) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.addAddress(_uid, address);
      state = state.copyWith(
        isLoading: false,
        addresses: [...state.addresses, address],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateAddress(Address address) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.updateAddress(_uid, address);

      final updatedAddresses = state.addresses
          .map((addr) => addr.id == address.id ? address : addr)
          .toList();

      state = state.copyWith(
        isLoading: false,
        addresses: updatedAddresses,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.deleteAddress(_uid, addressId);

      state = state.copyWith(
        isLoading: false,
        addresses:
            state.addresses.where((addr) => addr.id != addressId).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedAddresses = state.addresses.map((addr) {
        if (addr.id == addressId) {
          return addr.copyWith(isDefault: true);
        }
        return addr.copyWith(isDefault: false);
      }).toList();

      for (final addr in updatedAddresses) {
        await _repository.updateAddress(_uid, addr);
      }

      state = state.copyWith(
        isLoading: false,
        addresses: updatedAddresses,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void selectAddress(String addressId) {
    state = state.copyWith(selectedAddressId: addressId);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final addressesControllerProvider =
    StateNotifierProvider.family<AddressesController, AddressesState, String>(
        (ref, uid) {
  final repository = ref.watch(profileRepositoryProvider);
  return AddressesController(repository, uid);
});

// Helper to create a new address with a unique ID
Address createNewAddress({
  required String label,
  required String street,
  required String city,
  required String state,
  required String zipCode,
  String country = 'US',
  double? latitude,
  double? longitude,
}) {
  return Address(
    id: const Uuid().v4(),
    label: label,
    street: street,
    city: city,
    state: state,
    zipCode: zipCode,
    country: country,
    latitude: latitude,
    longitude: longitude,
  );
}
