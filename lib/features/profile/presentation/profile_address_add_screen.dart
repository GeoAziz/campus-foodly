import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';

import '../../../data/providers/auth_provider.dart';
import '../../../data/services/location_service.dart';
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
  final _locationService = LocationService();
  late TextEditingController _labelController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _countryController;

  Address? _existingAddress;
  double? _latitude;
  double? _longitude;
  bool _isFetchingCurrentLocation = false;
  bool _locationPromptShown = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _zipCodeController = TextEditingController();
    _countryController = TextEditingController(text: 'US');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.addressId == null) {
        _showCurrentLocationPrompt();
      }
    });
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

  Future<void> _showCurrentLocationPrompt() async {
    if (_locationPromptShown) return;
    _locationPromptShown = true;

    final useCurrentLocation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Use current location?'),
          content: const Text(
            'We can turn on Location and prefill this address from where you are now. You can still edit the details before saving.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Enter manually'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Use current location'),
            ),
          ],
        );
      },
    );

    if (useCurrentLocation == true && mounted) {
      await _prefillFromCurrentLocation();
    }
  }

  void _setIfBlank(TextEditingController controller, String value) {
    if (controller.text.trim().isEmpty && value.trim().isNotEmpty) {
      controller.text = value;
    }
  }

  String _streetFromPlacemark(Placemark placemark) {
    final parts = <String>[
      placemark.subThoroughfare ?? '',
      placemark.thoroughfare ?? '',
    ].where((part) => part.trim().isNotEmpty).toList();

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    return placemark.name ?? '';
  }

  String? _locationCoordinatesLabel() {
    if (_latitude == null || _longitude == null) {
      return null;
    }

    return '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}';
  }

  Future<void> _prefillFromCurrentLocation() async {
    setState(() {
      _isFetchingCurrentLocation = true;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      _setIfBlank(_labelController, 'Current location');
      if (placemark != null) {
        _setIfBlank(_streetController, _streetFromPlacemark(placemark));
        _setIfBlank(_cityController,
            placemark.locality ?? placemark.subAdministrativeArea ?? '');
        _setIfBlank(_stateController, placemark.administrativeArea ?? '');
        _setIfBlank(_zipCodeController, placemark.postalCode ?? '');
        _setIfBlank(_countryController,
            placemark.isoCountryCode ?? placemark.country ?? 'US');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Current location added. Please review the address before saving.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
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

    final address = _existingAddress == null
        ? createNewAddress(
            label: _labelController.text,
            street: _streetController.text,
            city: _cityController.text,
            state: _stateController.text,
            zipCode: _zipCodeController.text,
            country: _countryController.text,
            latitude: _latitude,
            longitude: _longitude,
          )
        : _existingAddress!.copyWith(
            label: _labelController.text,
            street: _streetController.text,
            city: _cityController.text,
            state: _stateController.text,
            zipCode: _zipCodeController.text,
            country: _countryController.text,
            latitude: _latitude,
            longitude: _longitude,
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
              if (!isEditing) ...[
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Speed this up with your location',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Allow location access and we will prefill the address for you. You can edit everything before saving.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isFetchingCurrentLocation
                                ? null
                                : _prefillFromCurrentLocation,
                            icon: _isFetchingCurrentLocation
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(
                              _isFetchingCurrentLocation
                                  ? 'Checking location...'
                                  : 'Use current location',
                            ),
                          ),
                        ),
                        if (_latitude != null && _longitude != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.place_outlined, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Captured from current location',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (_locationCoordinatesLabel() != null)
                                        Text(
                                          _locationCoordinatesLabel()!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _isFetchingCurrentLocation
                                      ? null
                                      : _prefillFromCurrentLocation,
                                  child: const Text('Refresh'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
                      onPressed:
                          addressesState.isLoading || _isFetchingCurrentLocation
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
