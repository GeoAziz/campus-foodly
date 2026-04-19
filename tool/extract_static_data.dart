import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final rootPath = args.isNotEmpty ? args.first : Directory.current.path;
  final extractor = StaticDataExtractor(rootPath: rootPath);
  extractor.run();
}

class StaticDataExtractor {
  StaticDataExtractor({required this.rootPath});

  final String rootPath;
  final JsonEncoder _prettyJson = const JsonEncoder.withIndent('  ');
  final List<Map<String, dynamic>> _rawRecords = [];

  void run() {
    final libDir = Directory(_join(rootPath, 'lib'));
    if (!libDir.existsSync()) {
      stderr.writeln('lib directory not found at: ${libDir.path}');
      exitCode = 2;
      return;
    }

    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in dartFiles) {
      _extractFromFile(file);
    }

    _extractUiConfig();

    final dataRoot = Directory(_join(rootPath, 'data'));
    final rawDir = Directory(_join(dataRoot.path, 'raw'));
    final normalizedDir = Directory(_join(dataRoot.path, 'normalized'));
    final metaDir = Directory(_join(dataRoot.path, 'meta'));
    final extractedAssetsDir = Directory(_join(dataRoot.path, 'assets'));

    dataRoot.createSync(recursive: true);
    rawDir.createSync(recursive: true);
    normalizedDir.createSync(recursive: true);
    metaDir.createSync(recursive: true);
    extractedAssetsDir.createSync(recursive: true);

    _extractAllAssets(extractedAssetsDir);

    final normalized = _buildNormalizedEntities();
    final missingAssets = _validateAssetReferences();

    _writeRawOutputs(rawDir);
    _writeNormalizedOutputs(normalizedDir, normalized);
    _writeMeta(metaDir, normalized, missingAssets);

    stdout.writeln('Extraction completed.');
    stdout.writeln('Raw records: ${_rawRecords.length}');
    stdout.writeln('Missing assets: ${missingAssets.length}');
    stdout.writeln('Extracted assets dir: ${extractedAssetsDir.path}');
    stdout.writeln('Output: ${dataRoot.path}');
  }

  void _extractAllAssets(Directory extractedAssetsDir) {
    final assetRoot = Directory(_join(rootPath, 'assets'));
    if (!assetRoot.existsSync()) {
      return;
    }

    final files = assetRoot
        .listSync(recursive: true)
        .whereType<File>()
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (var index = 0; index < files.length; index++) {
      final file = files[index];
      final sourceAssetPath = _relativeFromRoot(file.path);
      if (!sourceAssetPath.startsWith('assets/')) {
        continue;
      }

      final relativeToAssets = sourceAssetPath.substring('assets/'.length);
      final extractedPath = _join(extractedAssetsDir.path, relativeToAssets);
      final extractedFile = File(extractedPath);
      extractedFile.parent.createSync(recursive: true);
      file.copySync(extractedFile.path);

      final stat = file.statSync();
      final bytes = file.readAsBytesSync();
      final extension = sourceAssetPath.contains('.')
          ? sourceAssetPath.substring(sourceAssetPath.lastIndexOf('.') + 1)
          : '';

      _pushRawRecord(
        sourceFile: sourceAssetPath,
        sourceBlock: 'filesystem_assets',
        entity: 'assets_catalog',
        itemIndex: index,
        rawData: {
          'assetPath': sourceAssetPath,
          'fileName': file.uri.pathSegments.isNotEmpty
              ? file.uri.pathSegments.last
              : sourceAssetPath,
          'extension': extension.toLowerCase(),
          'sizeBytes': stat.size,
          'modifiedAtUtc': stat.modified.toUtc().toIso8601String(),
          'contentHash': _fnv1a64HexBytes(bytes),
          'extractedCopyPath': _relativeFromRoot(extractedFile.path),
        },
      );
    }
  }

  void _extractFromFile(File file) {
    final content = file.readAsStringSync();
    final relativePath = _relativeFromRoot(file.path);

    _extractNamedList(content, relativePath,
        variable: 'demoBigImages', entity: 'image_sets');
    _extractNamedList(content, relativePath,
        variable: 'demoMediumCardData', entity: 'restaurants');
    _extractNamedList(content, relativePath,
        variable: '_navitems', entity: 'nav_items');
    _extractNamedList(content, relativePath,
        variable: 'demoData', entity: _entityForDemoData(relativePath));
    _extractNamedList(content, relativePath,
        variable: 'demoItems', entity: 'order_items');
    _extractNamedList(content, relativePath,
        variable: 'demoCategories', entity: 'categories');
    _extractNamedList(content, relativePath,
        variable: 'demoDietaries', entity: 'dietaries');
    _extractNamedList(content, relativePath,
        variable: 'choiceOfTopCookies', entity: 'choice_options');
    _extractNamedList(content, relativePath,
        variable: 'demoTabs', entity: 'tabs');

    _extractListGenerateMap(content, relativePath,
        variable: 'demoData', entity: 'menu_items');

    _extractInlineConstructorRecords(
      content,
      relativePath,
      constructorName: 'RestaurantInfoBigCard',
      entity: 'restaurants',
      datasetName: 'inline_restaurant_cards',
    );
    _extractInlineConstructorRecords(
      content,
      relativePath,
      constructorName: 'ProfileMenuCard',
      entity: 'profile_menu_items',
      datasetName: 'inline_profile_menu',
    );

    _extractScreenLiteralSnapshot(content, relativePath);
  }

  String _entityForDemoData(String filePath) {
    if (filePath.contains('onboarding')) {
      return 'onboarding_slides';
    }
    if (filePath.contains('details/components/iteams.dart')) {
      return 'menu_items';
    }
    return 'misc';
  }

  void _extractScreenLiteralSnapshot(String content, String sourceFile) {
    if (!sourceFile.startsWith('lib/screens/') ||
        !sourceFile.endsWith('.dart')) {
      return;
    }

    final lines = content
        .split('\n')
        .where((line) {
          final trimmed = line.trimLeft();
          return !trimmed.startsWith('import ') &&
              !trimmed.startsWith('export ') &&
              !trimmed.startsWith('part ');
        })
        .toList(growable: false);
    final scanSource = lines.join('\n');

    final strings = _extractQuotedStrings(scanSource)
      ..sort((a, b) => a.compareTo(b));
    final assets = strings
        .where((value) => value.startsWith('assets/'))
        .toSet()
        .toList(growable: false)
      ..sort((a, b) => a.compareTo(b));

    final textLiterals = strings
        .where((value) =>
            !value.startsWith('assets/') &&
            !value.startsWith('package:') &&
            !value.endsWith('.dart'))
        .toList(growable: false)
      ..sort((a, b) => a.compareTo(b));

    _pushRawRecord(
      sourceFile: sourceFile,
      sourceBlock: 'screen_literal_scan',
      entity: 'screen_literals',
      itemIndex: 0,
      rawData: {
        'file': sourceFile,
        'stringLiteralCount': strings.length,
        'textLiteralCount': textLiterals.length,
        'assetLiteralCount': assets.length,
        'textLiterals': textLiterals,
        'assetLiterals': assets,
      },
    );
  }

  List<String> _extractQuotedStrings(String source) {
    final matches = RegExp(
      r'''(?<!\\)(?:"([^"\\]*(?:\\.[^"\\]*)*)"|'([^'\\]*(?:\\.[^'\\]*)*)')''',
      dotAll: true,
    ).allMatches(source);

    final values = <String>{};
    for (final match in matches) {
      final value = match.group(1) ?? match.group(2);
      if (value == null) {
        continue;
      }
      final normalized = value
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\t', '\t')
          .replaceAll(r"\'", "'")
          .replaceAll(r'\"', '"')
          .trim();
      if (normalized.isEmpty) {
        continue;
      }
      values.add(normalized);
    }
    return values.toList(growable: false);
  }

  void _extractNamedList(
    String content,
    String sourceFile, {
    required String variable,
    required String entity,
  }) {
    final assignmentIndex = content.indexOf('$variable =');
    if (assignmentIndex == -1) {
      return;
    }

    final equalsIndex = content.indexOf('=', assignmentIndex);
    if (equalsIndex == -1) {
      return;
    }

    final listStart = content.indexOf('[', equalsIndex);
    if (listStart == -1) {
      return;
    }

    final listLiteral = _extractBalanced(content, listStart, '[', ']');
    if (listLiteral == null) {
      return;
    }

    final records = _parseListLiteral(listLiteral);
    for (var index = 0; index < records.length; index++) {
      final rawData = records[index];
      if (rawData is! Map<String, dynamic>) {
        continue;
      }
      _pushRawRecord(
        sourceFile: sourceFile,
        sourceBlock: variable,
        entity: entity,
        itemIndex: index,
        rawData: rawData,
      );
    }
  }

  void _extractListGenerateMap(
    String content,
    String sourceFile, {
    required String variable,
    required String entity,
  }) {
    final startToken = '$variable = List.generate(';
    final assignmentIndex = content.indexOf(startToken);
    if (assignmentIndex == -1) {
      return;
    }

    final openParen =
        content.indexOf('(', assignmentIndex + startToken.length - 1);
    if (openParen == -1) {
      return;
    }
    final callBody = _extractBalanced(content, openParen, '(', ')');
    if (callBody == null) {
      return;
    }

    final callInner = callBody.substring(1, callBody.length - 1);
    final countMatch = RegExp(r'^\s*(\d+)').firstMatch(callInner);
    if (countMatch == null) {
      return;
    }
    final count = int.parse(countMatch.group(1)!);

    final mapStart = callInner.indexOf('{');
    if (mapStart == -1) {
      return;
    }
    final mapLiteral = _extractBalanced(callInner, mapStart, '{', '}');
    if (mapLiteral == null) {
      return;
    }

    for (var index = 0; index < count; index++) {
      final mapValue = _parseMapLiteral(
        mapLiteral,
        interpolationIndex: index,
      );
      _pushRawRecord(
        sourceFile: sourceFile,
        sourceBlock: '${variable}_List.generate',
        entity: entity,
        itemIndex: index,
        rawData: mapValue,
      );
    }
  }

  void _extractInlineConstructorRecords(
    String content,
    String sourceFile, {
    required String constructorName,
    required String entity,
    required String datasetName,
  }) {
    var searchIndex = 0;
    var itemIndex = 0;
    final token = '$constructorName(';
    while (true) {
      final constructorIndex = content.indexOf(token, searchIndex);
      if (constructorIndex == -1) {
        break;
      }
      final openParen = content.indexOf('(', constructorIndex);
      if (openParen == -1) {
        break;
      }
      final callBody = _extractBalanced(content, openParen, '(', ')');
      if (callBody == null) {
        break;
      }

      final args = callBody.substring(1, callBody.length - 1);
      final map = _parseNamedArguments(args);
      final literalOnly = <String, dynamic>{};
      for (final entry in map.entries) {
        final value = entry.value;
        if (value != null) {
          literalOnly[entry.key] = value;
        }
      }
      if (literalOnly.isNotEmpty) {
        _pushRawRecord(
          sourceFile: sourceFile,
          sourceBlock: datasetName,
          entity: entity,
          itemIndex: itemIndex,
          rawData: literalOnly,
        );
        itemIndex += 1;
      }

      searchIndex = openParen + callBody.length;
    }
  }

  void _extractUiConfig() {
    final file = File(_join(rootPath, 'lib/constants.dart'));
    if (!file.existsSync()) {
      return;
    }
    final content = file.readAsStringSync();
    final sourceFile = _relativeFromRoot(file.path);

    final colorRegex =
        RegExp(r'const\s+(\w+)\s*=\s*Color\((0x[0-9A-Fa-f]+)\);');
    var index = 0;
    for (final match in colorRegex.allMatches(content)) {
      _pushRawRecord(
        sourceFile: sourceFile,
        sourceBlock: 'color_constants',
        entity: 'ui_config',
        itemIndex: index,
        rawData: {
          'name': match.group(1),
          'value': match.group(2),
          'type': 'color',
        },
      );
      index += 1;
    }

    final scalarRegex =
        RegExp(r'const\s+(double|Duration)\s+(\w+)\s*=\s*([^;]+);');
    for (final match in scalarRegex.allMatches(content)) {
      _pushRawRecord(
        sourceFile: sourceFile,
        sourceBlock: 'scalar_constants',
        entity: 'ui_config',
        itemIndex: index,
        rawData: {
          'name': match.group(2),
          'value': match.group(3)?.trim(),
          'type': match.group(1),
        },
      );
      index += 1;
    }
  }

  void _pushRawRecord({
    required String sourceFile,
    required String sourceBlock,
    required String entity,
    required int itemIndex,
    required Map<String, dynamic> rawData,
  }) {
    final sortedRaw = _sortKeysDeep(rawData);
    final sourceKey = '$sourceFile|$sourceBlock|$itemIndex';
    final id = _buildDeterministicId(entity, sourceKey, sortedRaw);
    _rawRecords.add({
      'id': id,
      'entity': entity,
      'source': {
        'file': sourceFile,
        'block': sourceBlock,
        'index': itemIndex,
      },
      'raw': sortedRaw,
    });
  }

  Map<String, List<Map<String, dynamic>>> _buildNormalizedEntities() {
    final entities = <String, List<Map<String, dynamic>>>{};
    for (final record in _rawRecords) {
      final entity = record['entity'] as String;
      final raw = (record['raw'] as Map).cast<String, dynamic>();
      final normalized = _normalizeRecord(entity, raw);
      final normalizedRecord = <String, dynamic>{
        'id': record['id'],
        ...normalized,
      };
      entities.putIfAbsent(entity, () => []).add(normalizedRecord);
    }

    for (final entry in entities.entries) {
      entry.value
          .sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
    }
    return entities;
  }

  Map<String, dynamic> _normalizeRecord(
      String entity, Map<String, dynamic> input) {
    final keyMap = <String, String>{
      'delivertTime': 'deliveryTime',
      'numOfRating': 'ratingCount',
      'numOfItem': 'quantity',
      'svgSrc': 'icon',
      'subTitle': 'subtitle',
      'foodType': 'foodTypes',
    };

    final normalized = <String, dynamic>{};
    for (final entry in input.entries) {
      final targetKey = keyMap[entry.key] ?? entry.key;
      normalized[targetKey] = _normalizeValue(targetKey, entry.value);
    }

    if (entity == 'restaurants') {
      if (normalized['name'] == null && normalized['title'] is String) {
        normalized['name'] = normalized['title'];
      }
      if (normalized['deliveryTime'] == null &&
          normalized['delivertTime'] is num) {
        normalized['deliveryTime'] = normalized['delivertTime'];
      }
    }

    if (entity == 'menu_items') {
      if (normalized['foodTypes'] is String) {
        normalized['foodTypes'] = [normalized['foodTypes']];
      }
    }

    return _sortKeysDeep(normalized);
  }

  dynamic _normalizeValue(String key, dynamic value) {
    if (value is String && value.trim().isEmpty) {
      return value;
    }
    if (value is num) {
      if (key == 'price' || key == 'rating') {
        return value.toDouble();
      }
      return value;
    }
    if (value is List) {
      return value
          .map((item) => _normalizeValue(key, item))
          .toList(growable: false);
    }
    if (value is Map) {
      return _sortKeysDeep(value.cast<String, dynamic>());
    }
    return value;
  }

  List<Map<String, dynamic>> _validateAssetReferences() {
    final assetRoot = Directory(_join(rootPath, 'assets'));
    final knownAssets = <String>{};
    if (assetRoot.existsSync()) {
      for (final file
          in assetRoot.listSync(recursive: true).whereType<File>()) {
        knownAssets.add(_relativeFromRoot(file.path));
      }
    }

    final missing = <Map<String, dynamic>>[];
    for (final record in _rawRecords) {
      final raw = (record['raw'] as Map).cast<String, dynamic>();
      final refs = _collectAssetRefs(raw);
      for (final ref in refs) {
        if (!knownAssets.contains(ref)) {
          missing.add({
            'id': record['id'],
            'entity': record['entity'],
            'asset': ref,
            'source': record['source'],
          });
        }
      }
    }
    return missing;
  }

  Set<String> _collectAssetRefs(dynamic value) {
    final refs = <String>{};
    if (value is String) {
      if (value.startsWith('assets/')) {
        refs.add(value);
      }
      return refs;
    }
    if (value is List) {
      for (final item in value) {
        refs.addAll(_collectAssetRefs(item));
      }
      return refs;
    }
    if (value is Map) {
      for (final item in value.values) {
        refs.addAll(_collectAssetRefs(item));
      }
      return refs;
    }
    return refs;
  }

  void _writeRawOutputs(Directory rawDir) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final record in _rawRecords) {
      final entity = record['entity'] as String;
      grouped.putIfAbsent(entity, () => []).add(record);
    }

    for (final entry in grouped.entries) {
      entry.value
          .sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
      final file = File(_join(rawDir.path, '${entry.key}.json'));
      file.writeAsStringSync('${_prettyJson.convert(entry.value)}\n');
    }
  }

  void _writeNormalizedOutputs(
    Directory normalizedDir,
    Map<String, List<Map<String, dynamic>>> normalized,
  ) {
    for (final entry in normalized.entries) {
      final file = File(_join(normalizedDir.path, '${entry.key}.json'));
      file.writeAsStringSync('${_prettyJson.convert(entry.value)}\n');
    }
  }

  void _writeMeta(
    Directory metaDir,
    Map<String, List<Map<String, dynamic>>> normalized,
    List<Map<String, dynamic>> missingAssets,
  ) {
    final summary = <String, dynamic>{
      'generatedAtUtc': DateTime.now().toUtc().toIso8601String(),
      'rawRecordCount': _rawRecords.length,
      'normalizedEntityCounts': {
        for (final entry in normalized.entries) entry.key: entry.value.length,
      },
      'missingAssetCount': missingAssets.length,
    };

    final sources =
        _rawRecords.map((record) => record['source']).toSet().toList();

    File(_join(metaDir.path, 'summary.json'))
        .writeAsStringSync('${_prettyJson.convert(summary)}\n');
    File(_join(metaDir.path, 'sources.json'))
        .writeAsStringSync('${_prettyJson.convert(sources)}\n');
    File(_join(metaDir.path, 'missing_assets.json'))
        .writeAsStringSync('${_prettyJson.convert(missingAssets)}\n');
  }

  List<dynamic> _parseListLiteral(String listLiteral) {
    final inner = listLiteral.substring(1, listLiteral.length - 1).trim();
    if (inner.isEmpty) {
      return const [];
    }

    final items = _splitTopLevel(inner, ',');
    final parsed = <dynamic>[];
    for (final item in items) {
      final value = item.trim();
      if (value.isEmpty) {
        continue;
      }
      if (value.startsWith('{')) {
        parsed.add(_parseMapLiteral(value));
        continue;
      }
      if (value.startsWith('const Tab(') || value.startsWith('Tab(')) {
        final label = _extractTabLabel(value);
        if (label != null) {
          parsed.add({'title': label});
        }
        continue;
      }
      if (value.startsWith('"') || value.startsWith("'")) {
        parsed.add({'value': _stripQuotes(value)});
        continue;
      }
    }
    return parsed;
  }

  Map<String, dynamic> _parseMapLiteral(
    String mapLiteral, {
    int? interpolationIndex,
  }) {
    final inner = mapLiteral.substring(1, mapLiteral.length - 1).trim();
    final fields = _splitTopLevel(inner, ',');
    final parsed = <String, dynamic>{};
    for (final field in fields) {
      final separator = _findTopLevelColon(field);
      if (separator == -1) {
        continue;
      }
      final rawKey = field.substring(0, separator).trim();
      final rawValue = field.substring(separator + 1).trim();
      final key = _stripQuotes(rawKey);
      final value =
          _parseValue(rawValue, interpolationIndex: interpolationIndex);
      if (value != null) {
        parsed[key] = value;
      }
    }
    return parsed;
  }

  Map<String, dynamic> _parseNamedArguments(String args) {
    final fields = _splitTopLevel(args, ',');
    final parsed = <String, dynamic>{};
    for (final field in fields) {
      final separator = _findTopLevelColon(field);
      if (separator == -1) {
        continue;
      }
      final key = field.substring(0, separator).trim();
      final rawValue = field.substring(separator + 1).trim();
      parsed[key] = _parseValue(rawValue);
    }
    return parsed;
  }

  dynamic _parseValue(String rawValue, {int? interpolationIndex}) {
    var value = rawValue.trim();
    if (value.endsWith(',')) {
      value = value.substring(0, value.length - 1).trim();
    }
    if (value.startsWith('const ')) {
      value = value.substring(6).trim();
    }

    if (value.startsWith('[') && value.endsWith(']')) {
      final inner = value.substring(1, value.length - 1);
      final parts = _splitTopLevel(inner, ',');
      return parts
          .map((part) =>
              _parseValue(part, interpolationIndex: interpolationIndex))
          .where((part) => part != null)
          .toList(growable: false);
    }

    if (value.startsWith('{') && value.endsWith('}')) {
      return _parseMapLiteral(value, interpolationIndex: interpolationIndex);
    }

    final quoted = (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"));
    if (quoted) {
      var text = _stripQuotes(value);
      if (interpolationIndex != null) {
        text =
            text.replaceAllMapped(RegExp(r'\$\{index\s*\+\s*(\d+)\}'), (match) {
          final plus = int.parse(match.group(1)!);
          return '${interpolationIndex + plus}';
        });
      }
      return text;
    }

    if (RegExp(r'^\d+$').hasMatch(value)) {
      return int.parse(value);
    }
    if (RegExp(r'^\d+\.\d+$').hasMatch(value)) {
      return double.parse(value);
    }
    if (value == 'true' || value == 'false') {
      return value == 'true';
    }

    return null;
  }

  String? _extractTabLabel(String tabLiteral) {
    final match =
        RegExp(r'''Text\((?:'|")(.+?)(?:'|")\)''').firstMatch(tabLiteral);
    return match?.group(1);
  }

  String _buildDeterministicId(
    String entity,
    String sourceKey,
    Map<String, dynamic> payload,
  ) {
    final basis = '$entity|$sourceKey|${jsonEncode(payload)}';
    final hash = _fnv1a64(basis);
    return '$entity-${hash.toRadixString(16).padLeft(16, '0')}';
  }

  int _fnv1a64(String input) {
    const int fnvOffset = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    var hash = fnvOffset;
    for (final unit in utf8.encode(input)) {
      hash ^= unit;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash;
  }

  String _fnv1a64HexBytes(List<int> input) {
    const int fnvOffset = 0xcbf29ce484222325;
    const int fnvPrime = 0x100000001b3;
    var hash = fnvOffset;
    for (final unit in input) {
      hash ^= unit;
      hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  Map<String, dynamic> _sortKeysDeep(Map<String, dynamic> map) {
    final sortedKeys = map.keys.toList()..sort();
    final result = <String, dynamic>{};
    for (final key in sortedKeys) {
      final value = map[key];
      if (value is Map<String, dynamic>) {
        result[key] = _sortKeysDeep(value);
      } else if (value is Map) {
        result[key] = _sortKeysDeep(value.cast<String, dynamic>());
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _sortKeysDeep(item);
          }
          if (item is Map) {
            return _sortKeysDeep(item.cast<String, dynamic>());
          }
          return item;
        }).toList(growable: false);
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  List<String> _splitTopLevel(String input, String separator) {
    final result = <String>[];
    var depthParen = 0;
    var depthBracket = 0;
    var depthBrace = 0;
    var inSingleQuote = false;
    var inDoubleQuote = false;
    var start = 0;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      final previous = i > 0 ? input[i - 1] : '';

      if (char == "'" && !inDoubleQuote && previous != r'\') {
        inSingleQuote = !inSingleQuote;
      } else if (char == '"' && !inSingleQuote && previous != r'\') {
        inDoubleQuote = !inDoubleQuote;
      }

      if (inSingleQuote || inDoubleQuote) {
        continue;
      }

      if (char == '(') depthParen += 1;
      if (char == ')') depthParen -= 1;
      if (char == '[') depthBracket += 1;
      if (char == ']') depthBracket -= 1;
      if (char == '{') depthBrace += 1;
      if (char == '}') depthBrace -= 1;

      if (char == separator &&
          depthParen == 0 &&
          depthBracket == 0 &&
          depthBrace == 0) {
        result.add(input.substring(start, i));
        start = i + 1;
      }
    }

    if (start < input.length) {
      result.add(input.substring(start));
    }
    return result;
  }

  int _findTopLevelColon(String input) {
    var depthParen = 0;
    var depthBracket = 0;
    var depthBrace = 0;
    var inSingleQuote = false;
    var inDoubleQuote = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      final previous = i > 0 ? input[i - 1] : '';

      if (char == "'" && !inDoubleQuote && previous != r'\') {
        inSingleQuote = !inSingleQuote;
      } else if (char == '"' && !inSingleQuote && previous != r'\') {
        inDoubleQuote = !inDoubleQuote;
      }

      if (inSingleQuote || inDoubleQuote) {
        continue;
      }

      if (char == '(') depthParen += 1;
      if (char == ')') depthParen -= 1;
      if (char == '[') depthBracket += 1;
      if (char == ']') depthBracket -= 1;
      if (char == '{') depthBrace += 1;
      if (char == '}') depthBrace -= 1;

      if (char == ':' &&
          depthParen == 0 &&
          depthBracket == 0 &&
          depthBrace == 0) {
        return i;
      }
    }
    return -1;
  }

  String? _extractBalanced(
    String input,
    int start,
    String open,
    String close,
  ) {
    if (start < 0 || start >= input.length || input[start] != open) {
      return null;
    }

    var depth = 0;
    var inSingleQuote = false;
    var inDoubleQuote = false;

    for (var i = start; i < input.length; i++) {
      final char = input[i];
      final previous = i > 0 ? input[i - 1] : '';

      if (char == "'" && !inDoubleQuote && previous != r'\') {
        inSingleQuote = !inSingleQuote;
      } else if (char == '"' && !inSingleQuote && previous != r'\') {
        inDoubleQuote = !inDoubleQuote;
      }

      if (inSingleQuote || inDoubleQuote) {
        continue;
      }

      if (char == open) {
        depth += 1;
      } else if (char == close) {
        depth -= 1;
        if (depth == 0) {
          return input.substring(start, i + 1);
        }
      }
    }
    return null;
  }

  String _stripQuotes(String value) {
    var text = value.trim();
    if ((text.startsWith('"') && text.endsWith('"')) ||
        (text.startsWith("'") && text.endsWith("'"))) {
      text = text.substring(1, text.length - 1);
    }
    return text;
  }

  String _relativeFromRoot(String absolutePath) {
    final normalizedRoot =
        rootPath.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = absolutePath.replaceAll('\\', '/');
    if (normalizedPath.startsWith('$normalizedRoot/')) {
      return normalizedPath.substring(normalizedRoot.length + 1);
    }
    return normalizedPath;
  }

  String _join(String left, String right) {
    final normalizedLeft =
        left.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
    final normalizedRight =
        right.replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');
    return '$normalizedLeft/$normalizedRight';
  }
}
