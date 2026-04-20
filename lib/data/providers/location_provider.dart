import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _locationLabelPrefKey = 'selected_location_label';
const _defaultLocationLabel = 'Choose location';

final selectedLocationProvider =
    AsyncNotifierProvider<LocationLabelController, String>(
  LocationLabelController.new,
);

class LocationLabelController extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_locationLabelPrefKey) ?? _defaultLocationLabel;
  }

  Future<void> setLocationLabel(String label) async {
    final normalized = label.trim();
    if (normalized.isEmpty) {
      return;
    }

    state = AsyncValue.data(normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationLabelPrefKey, normalized);
  }
}