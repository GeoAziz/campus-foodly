import 'dart:convert';
import 'dart:io';

void main() {
  final repoRoot = File.fromUri(Platform.script).parent.parent;
  final normalizedDir = Directory('${repoRoot.path}/data/normalized');

  final restaurants = _readJsonList('${normalizedDir.path}/restaurants.json');
  final restaurantDetails =
      _readJsonList('${normalizedDir.path}/restaurant_details.json');
  final featuredItems =
      _readJsonList('${normalizedDir.path}/featured_items.json');
  final menuTabs = _readJsonList('${normalizedDir.path}/menu_tabs.json');
  final menuItems = _readJsonList('${normalizedDir.path}/menu_items.json');

  final restaurantIds = restaurants
      .map((row) => row['id']?.toString() ?? '')
      .where((id) => id.isNotEmpty)
      .toList(growable: false);

  final scopedCounts = <String, Map<String, int>>{};
  for (final restaurantId in restaurantIds) {
    scopedCounts[restaurantId] = {
      'restaurant_details':
          _countForRestaurant(restaurantDetails, restaurantId),
      'featured_items': _countForRestaurant(featuredItems, restaurantId),
      'menu_tabs': _countForRestaurant(menuTabs, restaurantId),
      'menu_items': _countForRestaurant(menuItems, restaurantId),
    };
  }

  final missingRestaurants = <String>[];
  for (final entry in scopedCounts.entries) {
    final missingSections = entry.value.entries
        .where((section) => section.value == 0)
        .map((section) => section.key)
        .toList(growable: false);

    if (missingSections.isNotEmpty) {
      missingRestaurants.add(
        '${entry.key}: ${missingSections.join(', ')}',
      );
    }
  }

  stdout.writeln('Partner content validation');
  stdout.writeln('Restaurants: ${restaurantIds.length}');
  stdout.writeln(
      'Scoped restaurant_details: ${restaurantDetails.where((row) => _restaurantIdOf(row).isNotEmpty).length}');
  stdout.writeln(
      'Scoped featured_items: ${featuredItems.where((row) => _restaurantIdOf(row).isNotEmpty).length}');
  stdout.writeln(
      'Scoped menu_tabs: ${menuTabs.where((row) => _restaurantIdOf(row).isNotEmpty).length}');
  stdout.writeln(
      'Scoped menu_items: ${menuItems.where((row) => _restaurantIdOf(row).isNotEmpty).length}');

  if (missingRestaurants.isEmpty) {
    stdout.writeln('All restaurants have scoped content for every section.');
    exitCode = 0;
    return;
  }

  stdout.writeln('Missing partner-specific content:');
  for (final line in missingRestaurants) {
    stdout.writeln(' - $line');
  }
  exitCode = 1;
}

List<Map<String, dynamic>> _readJsonList(String path) {
  final raw = File(path).readAsStringSync();
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw FormatException('Expected a JSON list in $path');
  }

  return decoded
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList(growable: false);
}

String _restaurantIdOf(Map<String, dynamic> row) {
  final restaurantId = row['restaurantId'];
  return restaurantId?.toString() ?? '';
}

int _countForRestaurant(List<Map<String, dynamic>> rows, String restaurantId) {
  return rows.where((row) => _restaurantIdOf(row) == restaurantId).length;
}
