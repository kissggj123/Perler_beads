import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../models/models.dart';

enum ColumnType {
  code,
  name,
  quantity,
  red,
  green,
  blue,
  hexColor,
  brand,
  category,
  id,
  lastUpdated,
  unknown,
}

class ColumnMapping {
  final int index;
  final ColumnType type;
  final String? headerName;

  const ColumnMapping({
    required this.index,
    required this.type,
    this.headerName,
  });

  String get displayName {
    switch (type) {
      case ColumnType.code:
        return '颜色代码';
      case ColumnType.name:
        return '颜色名称';
      case ColumnType.quantity:
        return '数量';
      case ColumnType.red:
        return '红色值';
      case ColumnType.green:
        return '绿色值';
      case ColumnType.blue:
        return '蓝色值';
      case ColumnType.hexColor:
        return '十六进制颜色';
      case ColumnType.brand:
        return '品牌';
      case ColumnType.category:
        return '分类';
      case ColumnType.id:
        return 'ID';
      case ColumnType.lastUpdated:
        return '更新时间';
      case ColumnType.unknown:
        return headerName ?? '未知列';
    }
  }
}

class SmartImportResult {
  final bool success;
  final String? error;
  final List<InventoryItem> items;
  final List<ColumnMapping> detectedColumns;
  final List<String> headers;
  final List<List<dynamic>> rawData;
  final bool needsManualMapping;

  const SmartImportResult({
    required this.success,
    this.error,
    this.items = const [],
    this.detectedColumns = const [],
    this.headers = const [],
    this.rawData = const [],
    this.needsManualMapping = false,
  });
}

class SmartImportService {
  static final SmartImportService _instance = SmartImportService._internal();
  static SmartImportService get instance => _instance;
  SmartImportService._internal();

  static final Map<String, ColumnType> _columnKeywords = {
    'code': ColumnType.code,
    '编码': ColumnType.code,
    '代码': ColumnType.code,
    '色号': ColumnType.code,
    '编号': ColumnType.code,
    'no': ColumnType.code,
    'id': ColumnType.id,
    'name': ColumnType.name,
    '名称': ColumnType.name,
    '颜色': ColumnType.name,
    '颜色名称': ColumnType.name,
    '色名': ColumnType.name,
    'quantity': ColumnType.quantity,
    '数量': ColumnType.quantity,
    '库存': ColumnType.quantity,
    'qty': ColumnType.quantity,
    'count': ColumnType.quantity,
    'red': ColumnType.red,
    'r': ColumnType.red,
    '红色': ColumnType.red,
    'r值': ColumnType.red,
    'green': ColumnType.green,
    'g': ColumnType.green,
    '绿色': ColumnType.green,
    'g值': ColumnType.green,
    'blue': ColumnType.blue,
    'b': ColumnType.blue,
    '蓝色': ColumnType.blue,
    'b值': ColumnType.blue,
    'hex': ColumnType.hexColor,
    '十六进制': ColumnType.hexColor,
    '颜色值': ColumnType.hexColor,
    'rgb': ColumnType.hexColor,
    '#': ColumnType.hexColor,
    'brand': ColumnType.brand,
    '品牌': ColumnType.brand,
    '厂商': ColumnType.brand,
    'category': ColumnType.category,
    '分类': ColumnType.category,
    '类别': ColumnType.category,
    '类型': ColumnType.category,
    'updated': ColumnType.lastUpdated,
    '更新': ColumnType.lastUpdated,
    '时间': ColumnType.lastUpdated,
    '日期': ColumnType.lastUpdated,
  };

  static final List<RegExp> _codePatterns = [
    RegExp(r'^[A-Z]{1,3}-?\d{1,4}$', caseSensitive: false),
    RegExp(r'^\d{2,4}[A-Z]?$', caseSensitive: false),
    RegExp(r'^[A-Z]{2,3}\d{2,4}$', caseSensitive: false),
  ];

  SmartImportResult parseFile(String content, String fileName) {
    final extension = fileName.toLowerCase().split('.').last;

    if (extension == 'csv') {
      return _parseCsv(content);
    } else if (extension == 'xlsx' || extension == 'xls') {
      return _parseExcel(content);
    } else if (extension == 'json') {
      return _parseJson(content);
    }

    return SmartImportResult(
      success: false,
      error: '不支持的文件格式: $extension',
    );
  }

  SmartImportResult parseWithMapping(
    List<List<dynamic>> data,
    List<ColumnMapping> mappings,
  ) {
    try {
      final items = _convertDataToItems(data, mappings);
      return SmartImportResult(
        success: true,
        items: items,
        detectedColumns: mappings,
        rawData: data,
      );
    } catch (e) {
      return SmartImportResult(
        success: false,
        error: '转换数据失败: $e',
      );
    }
  }

  SmartImportResult _parseCsv(String content) {
    try {
      final separator = _detectSeparator(content);
      final eol = _detectEol(content);

      List<List<dynamic>> rows;

      rows = CsvToListConverter(
        fieldDelimiter: separator,
        eol: eol,
        textDelimiter: '"',
        textEndDelimiter: '"',
        convertEmptyTo: '',
        shouldParseNumbers: false,
      ).convert(content);

      if (rows.isEmpty) {
        return const SmartImportResult(
          success: false,
          error: 'CSV文件为空',
        );
      }

      rows = _cleanCsvRows(rows);

      return _processTabularData(rows);
    } catch (e) {
      return SmartImportResult(
        success: false,
        error: 'CSV解析失败: $e',
      );
    }
  }

  List<List<dynamic>> _cleanCsvRows(List<List<dynamic>> rows) {
    return rows.map((row) {
      return row.map((cell) {
        if (cell == null) return '';
        final str = cell.toString().trim();
        if (str.startsWith('"') && str.endsWith('"')) {
          return str.substring(1, str.length - 1);
        }
        return str;
      }).toList();
    }).where((row) => row.any((cell) => cell.toString().isNotEmpty)).toList();
  }

  SmartImportResult _parseExcel(String content) {
    try {
      final bytes = const Utf8Encoder().convert(content);
      final excel = Excel.decodeBytes(bytes);

      final sheets = excel.tables.keys.toList();
      if (sheets.isEmpty) {
        return const SmartImportResult(
          success: false,
          error: 'Excel文件没有工作表',
        );
      }

      final sheet = excel.tables[sheets.first]!;
      final rows = <List<dynamic>>[];

      for (var i = 0; i < sheet.maxRows; i++) {
        final row = <dynamic>[];
        for (var j = 0; j < sheet.maxColumns; j++) {
          final cell = sheet.cell(CellIndex.indexByString(
            '${String.fromCharCode(65 + j)}${i + 1}',
          ));
          row.add(cell.value?.toString() ?? '');
        }
        rows.add(row);
      }

      if (rows.isEmpty) {
        return const SmartImportResult(
          success: false,
          error: 'Excel工作表为空',
        );
      }

      return _processTabularData(rows);
    } catch (e) {
      return SmartImportResult(
        success: false,
        error: 'Excel解析失败: $e',
      );
    }
  }

  SmartImportResult _parseJson(String content) {
    try {
      final data = jsonDecode(content);

      if (data is Map<String, dynamic>) {
        if (data.containsKey('items')) {
          final inventory = Inventory.fromJson(data);
          return SmartImportResult(
            success: true,
            items: inventory.items,
          );
        }

        final items = <InventoryItem>[];
        for (final entry in data.entries) {
          if (entry.value is Map<String, dynamic>) {
            final itemData = entry.value as Map<String, dynamic>;
            items.add(_parseJsonItem(entry.key, itemData));
          }
        }

        if (items.isNotEmpty) {
          return SmartImportResult(success: true, items: items);
        }
      }

      if (data is List) {
        final items = <InventoryItem>[];
        for (var i = 0; i < data.length; i++) {
          if (data[i] is Map<String, dynamic>) {
            final itemData = data[i] as Map<String, dynamic>;
            items.add(_parseJsonItem('item_$i', itemData));
          }
        }

        if (items.isNotEmpty) {
          return SmartImportResult(success: true, items: items);
        }
      }

      return const SmartImportResult(
        success: false,
        error: 'JSON格式不正确，无法解析库存数据',
      );
    } catch (e) {
      return SmartImportResult(
        success: false,
        error: 'JSON解析失败: $e',
      );
    }
  }

  InventoryItem _parseJsonItem(String id, Map<String, dynamic> data) {
    final code = _extractString(data, ['code', '编码', '色号', 'id']) ?? id;
    final name = _extractString(data, ['name', '名称', '颜色名称', 'color']) ?? code;
    final quantity = _extractInt(data, ['quantity', '数量', '库存', 'qty', 'count']) ?? 0;

    int red = 128, green = 128, blue = 128;

    final hexColor = _extractString(data, ['hex', 'color', '颜色值', '十六进制']);
    if (hexColor != null) {
      final rgb = _parseHexColor(hexColor);
      if (rgb != null) {
        red = rgb[0];
        green = rgb[1];
        blue = rgb[2];
      }
    }

    red = _extractInt(data, ['red', 'r', '红色', 'r值']) ?? red;
    green = _extractInt(data, ['green', 'g', '绿色', 'g值']) ?? green;
    blue = _extractInt(data, ['blue', 'b', '蓝色', 'b值']) ?? blue;

    final brandStr = _extractString(data, ['brand', '品牌', '厂商']);
    final brand = _parseBrand(brandStr);

    final category = _extractString(data, ['category', '分类', '类别']);

    final lastUpdatedStr = _extractString(data, ['lastUpdated', '更新时间', 'updated']);
    final lastUpdated = lastUpdatedStr != null
        ? DateTime.tryParse(lastUpdatedStr) ?? DateTime.now()
        : DateTime.now();

    return InventoryItem(
      id: id,
      beadColor: BeadColor(
        code: code,
        name: name,
        red: red,
        green: green,
        blue: blue,
        brand: brand,
        category: category,
      ),
      quantity: quantity,
      lastUpdated: lastUpdated,
    );
  }

  String? _extractString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        return data[key]?.toString();
      }
    }
    return null;
  }

  int? _extractInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) {
        final value = data[key];
        if (value is int) return value;
        if (value is double) return value.round();
        return int.tryParse(value.toString());
      }
    }
    return null;
  }

  SmartImportResult _processTabularData(List<List<dynamic>> rows) {
    if (rows.isEmpty) {
      return const SmartImportResult(
        success: false,
        error: '数据为空',
      );
    }

    final hasHeader = _detectHeaderRow(rows[0]);
    final headers = hasHeader
        ? rows[0].map((e) => e.toString()).toList()
        : List.generate(rows[0].length, (i) => '列${i + 1}');

    final dataRows = hasHeader ? rows.sublist(1) : rows;

    final mappings = _detectColumnMappings(headers, dataRows);

    final essentialColumns = [ColumnType.code, ColumnType.name, ColumnType.quantity];
    final detectedEssential = mappings.where((m) => essentialColumns.contains(m.type)).map((m) => m.type).toSet();

    if (detectedEssential.length < 2) {
      return SmartImportResult(
        success: false,
        error: '无法自动识别足够的列，请手动选择列映射',
        detectedColumns: mappings,
        headers: headers,
        rawData: rows,
        needsManualMapping: true,
      );
    }

    final items = _convertDataToItems(dataRows, mappings);

    return SmartImportResult(
      success: true,
      items: items,
      detectedColumns: mappings,
      headers: headers,
      rawData: rows,
    );
  }

  List<ColumnMapping> _detectColumnMappings(
    List<String> headers,
    List<List<dynamic>> sampleData,
  ) {
    final mappings = <ColumnMapping>[];

    for (var i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      final detectedType = _detectColumnType(header, i, sampleData);

      mappings.add(ColumnMapping(
        index: i,
        type: detectedType,
        headerName: headers[i],
      ));
    }

    return mappings;
  }

  ColumnType _detectColumnType(
    String header,
    int columnIndex,
    List<List<dynamic>> sampleData,
  ) {
    for (final entry in _columnKeywords.entries) {
      if (header.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    if (sampleData.isNotEmpty) {
      final columnValues = sampleData
          .take(10)
          .where((row) => columnIndex < row.length)
          .map((row) => row[columnIndex].toString())
          .toList();

      if (columnValues.isNotEmpty) {
        final detectedType = _detectColumnTypeByValues(columnValues);
        if (detectedType != ColumnType.unknown) {
          return detectedType;
        }
      }
    }

    return ColumnType.unknown;
  }

  ColumnType _detectColumnTypeByValues(List<String> values) {
    if (values.isEmpty) return ColumnType.unknown;

    int hexCount = 0;
    int codeCount = 0;
    int numberCount = 0;
    int brandCount = 0;

    for (final value in values) {
      final trimmed = value.trim();

      if (_isHexColor(trimmed)) {
        hexCount++;
      }

      if (_isColorCode(trimmed)) {
        codeCount++;
      }

      if (int.tryParse(trimmed) != null) {
        numberCount++;
      }

      if (_isBrand(trimmed)) {
        brandCount++;
      }
    }

    final threshold = values.length * 0.6;

    if (hexCount >= threshold) return ColumnType.hexColor;
    if (codeCount >= threshold) return ColumnType.code;
    if (brandCount >= threshold) return ColumnType.brand;

    if (numberCount >= threshold) {
      final numbers = values
          .where((v) => int.tryParse(v) != null)
          .map((v) => int.parse(v))
          .toList();

      if (numbers.isNotEmpty) {
        final avg = numbers.reduce((a, b) => a + b) / numbers.length;
        if (avg <= 255) {
          return ColumnType.quantity;
        }
      }
    }

    return ColumnType.unknown;
  }

  bool _detectHeaderRow(List<dynamic> row) {
    if (row.isEmpty) return false;

    int textCount = 0;
    int numberCount = 0;

    for (final cell in row) {
      final str = cell.toString().trim();
      if (str.isEmpty) continue;

      if (int.tryParse(str) != null) {
        numberCount++;
      } else if (double.tryParse(str) == null) {
        textCount++;
      }
    }

    return textCount > numberCount;
  }

  List<InventoryItem> _convertDataToItems(
    List<List<dynamic>> dataRows,
    List<ColumnMapping> mappings,
  ) {
    final items = <InventoryItem>[];

    final codeMapping = mappings.firstWhere(
      (m) => m.type == ColumnType.code,
      orElse: () => mappings.first,
    );
    final nameMapping = mappings.firstWhere(
      (m) => m.type == ColumnType.name,
      orElse: () => codeMapping,
    );
    final quantityMapping = mappings.firstWhere(
      (m) => m.type == ColumnType.quantity,
      orElse: () => ColumnMapping(index: -1, type: ColumnType.quantity),
    );
    final redMapping = mappings.firstWhere(
      (m) => m.type == ColumnType.red,
      orElse: () => ColumnMapping(index: -1, type: ColumnType.red),
    );
    final greenMapping = mappings.firstWhere(
      (m) => m.type == ColumnType.green,
      orElse: () => ColumnMapping(index: -1, type: ColumnType.green),
    );
    final blueMapping = mappings.firstWhere(
      (m) => m.type == ColumnType.blue,
      orElse: () => ColumnMapping(index: -1, type: ColumnType.blue),
    );
    final hexMapping = mappings.firstWhere(
      (m) => m.type == ColumnType.hexColor,
      orElse: () => ColumnMapping(index: -1, type: ColumnType.hexColor),
    );
    final brandMapping = mappings.firstWhere(
      (m) => m.type == ColumnType.brand,
      orElse: () => ColumnMapping(index: -1, type: ColumnType.brand),
    );
    final categoryMapping = mappings.firstWhere(
      (m) => m.type == ColumnType.category,
      orElse: () => ColumnMapping(index: -1, type: ColumnType.category),
    );
    final idMapping = mappings.firstWhere(
      (m) => m.type == ColumnType.id,
      orElse: () => ColumnMapping(index: -1, type: ColumnType.id),
    );

    for (var i = 0; i < dataRows.length; i++) {
      final row = dataRows[i];
      if (row.isEmpty) continue;

      final code = _getCellValue(row, codeMapping.index, 'CODE_$i');
      final name = _getCellValue(row, nameMapping.index, code);
      final quantityStr = _getCellValue(row, quantityMapping.index, '0');
      final quantity = int.tryParse(quantityStr.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

      int red = 128, green = 128, blue = 128;

      final hexValue = _getCellValue(row, hexMapping.index, '');
      if (hexValue.isNotEmpty) {
        final rgb = _parseHexColor(hexValue);
        if (rgb != null) {
          red = rgb[0];
          green = rgb[1];
          blue = rgb[2];
        }
      }

      red = int.tryParse(_getCellValue(row, redMapping.index, '')) ?? red;
      green = int.tryParse(_getCellValue(row, greenMapping.index, '')) ?? green;
      blue = int.tryParse(_getCellValue(row, blueMapping.index, '')) ?? blue;

      final brandStr = _getCellValue(row, brandMapping.index, '');
      final brand = _parseBrand(brandStr);

      final category = _getCellValue(row, categoryMapping.index, '');
      final id = _getCellValue(row, idMapping.index, '');

      final beadColor = BeadColor(
        code: code,
        name: name,
        red: red.clamp(0, 255),
        green: green.clamp(0, 255),
        blue: blue.clamp(0, 255),
        brand: brand,
        category: category.isNotEmpty ? category : null,
      );

      items.add(InventoryItem(
        id: id.isNotEmpty ? id : 'import_${DateTime.now().millisecondsSinceEpoch}_$i',
        beadColor: beadColor,
        quantity: quantity,
        lastUpdated: DateTime.now(),
      ));
    }

    return items;
  }

  String _getCellValue(List<dynamic> row, int index, String defaultValue) {
    if (index < 0 || index >= row.length) return defaultValue;
    final value = row[index];
    if (value == null) return defaultValue;
    return value.toString().trim();
  }

  bool _isHexColor(String value) {
    final hex = value.trim();
    return RegExp(r'^#?[0-9A-Fa-f]{6}$').hasMatch(hex) ||
        RegExp(r'^#?[0-9A-Fa-f]{3}$').hasMatch(hex);
  }

  bool _isColorCode(String value) {
    final code = value.trim();
    for (final pattern in _codePatterns) {
      if (pattern.hasMatch(code)) return true;
    }
    return false;
  }

  bool _isBrand(String value) {
    final lower = value.toLowerCase().trim();
    return BeadBrand.values.any((b) => b.name.toLowerCase() == lower);
  }

  List<int>? _parseHexColor(String hex) {
    var cleaned = hex.trim();
    if (cleaned.startsWith('#')) {
      cleaned = cleaned.substring(1);
    }

    if (cleaned.length == 3) {
      final r = int.parse(cleaned[0] + cleaned[0], radix: 16);
      final g = int.parse(cleaned[1] + cleaned[1], radix: 16);
      final b = int.parse(cleaned[2] + cleaned[2], radix: 16);
      return [r, g, b];
    }

    if (cleaned.length == 6) {
      final r = int.parse(cleaned.substring(0, 2), radix: 16);
      final g = int.parse(cleaned.substring(2, 4), radix: 16);
      final b = int.parse(cleaned.substring(4, 6), radix: 16);
      return [r, g, b];
    }

    return null;
  }

  BeadBrand _parseBrand(String? value) {
    if (value == null || value.isEmpty) return BeadBrand.generic;

    final lower = value.toLowerCase().trim();
    return BeadBrand.values.firstWhere(
      (b) => b.name.toLowerCase() == lower,
      orElse: () => BeadBrand.generic,
    );
  }

  String _detectEol(String content) {
    if (content.contains('\r\n')) return '\r\n';
    if (content.contains('\r')) return '\r';
    return '\n';
  }

  String _detectSeparator(String content) {
    final firstLine = content.split(_detectEol(content)).first;

    final separators = [',', ';', '\t', '|'];
    int maxCount = 0;
    String detected = ',';

    for (final sep in separators) {
      final count = sep.allMatches(firstLine).length;
      if (count > maxCount) {
        maxCount = count;
        detected = sep;
      }
    }

    return detected;
  }

  List<ColumnMapping> createDefaultMappings(int columnCount) {
    return List.generate(
      columnCount,
      (i) => ColumnMapping(
        index: i,
        type: ColumnType.unknown,
        headerName: '列${i + 1}',
      ),
    );
  }

  List<ColumnType> getAvailableColumnTypes() {
    return ColumnType.values.where((t) => t != ColumnType.unknown).toList();
  }
}
