import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/auth_provider.dart';
import '../models/address.dart';
import '../providers/addresses_controller.dart';

class ProfileAddressAddScreen extends ConsumerStatefulWidget {
  final String? addressId; // null for add, populated for edit

  const ProfileAddressAddScreen({Key? key, this.addressId}) : super(key: key);

  @override
  ConsumerState<ProfileAddressAddScreen> createState() =>
      _ProfileAddressAddScreenState();
}

class _ProfileAddressAddScreenState
    extends ConsumerState<ProfileAddressAddScreen> {
  late TextEditingController _labelController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _countryController;

  Address? _existingAddress;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipCodeController = TextEditingController();
    _countryController = TextEditingController(text: 'US');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _loadExistingAddress(List<Address> addresses) {
    if (widget.addressId == null || _existingAddress != null) return;

    try {
      _existingAddress = addresses.firstWhere(
        (addr) => addr.id == widget.addressId,
      );

      _labelController.text = _existingAddress!.label;
      _streetController.text = _existingAddress!.street;
      _cityController.text = _existingAddress!.city;
      _stateController.text = _existingAddress!.state;
      _zipCodeController.text = _existingAddress!.zipCode;
      _countryController.text = _existingAddress!.country;
    } catch (e) {
      // Address not found
    }
  }

  String? _validateForm() {
    if (_labelController.text.isEmpty) {
      return 'Please enter an address label (e.g., Home, Work)';
    }
    if (_streetController.text.isEmpty) {
      return 'Street address is required';
    }
    if (_cityController.text.isEmpty) {
      return 'City is required';
    }
    if (_stateController.text.isEmpty) {
      return 'State is required';
    }
    if (_zipCodeController.text.isEmpty) {
      return 'ZIP code is required';
    }
    return null;
  }

  Future<void> _saveAddress(
    String userId,
    AddressesController controller,
  ) async {
    final validationError = _validateForm();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    final address = Address(
      id: _existingAddress?.id ?? '',
      label: _labelController.text,
      street: _streetController.text,
      city: _cityController.text,
      state: _stateController.text,
      zipCode: _zipCodeController.text,
      country: _countryController.text,
      isDefault: _existingAddress?.isDefault ?? false,
    );

    if (_existingAddress == null) {
      // Add new address
      await controller.addAddress(address);
    } else {
      // Update existing address
      await controller.updateAddress(address);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Address')),
        body: const Center(child: Text('User not found')),
      );
    }

    final addressesState = ref.watch(addressesControllerProvider(user.id));
    final controller = ref.read(addressesControllerProvider(user.id).notifier);

    // Load existing address if editing
    if (_existingAddress == null && widget.addressId != null) {
      _loadExistingAddress(addressesState.addresses);
    }

    final isEditing = widget.addressId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add Address'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                'Address Label',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  hintText: 'e.g., Home, Work, Other',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Street
              Text(
                'Street Address',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _streetController,
                decoration: InputDecoration(
                  hintText: 'Enter street address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // City and State
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'City',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            hintText: 'City',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'State',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _stateController,
                          decoration: InputDecoration(
                            hintText: 'State',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ZIP Code and Country
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ZIP Code',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _zipCodeController,
                          decoration: InputDecoration(
                            hintText: 'ZIP Code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Country',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _countryController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: addressesState.isLoading
                          ? null
                          : () {
                              _saveAddress(user.id, controller);
                            },
                      child: addressesState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEditing ? 'Update Address' : 'Add Address',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
