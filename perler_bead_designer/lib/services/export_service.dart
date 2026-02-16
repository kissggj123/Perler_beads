import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../models/bead_design.dart';
import '../models/inventory.dart';
import '../utils/pdf_generator.dart';

enum ExportFormat {
  png,
  pdf,
  csv,
}

enum MaterialListFormat {
  csv,
  pdf,
}

class ExportResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;

  ExportResult.success(this.filePath)
      : success = true,
        errorMessage = null;

  ExportResult.failure(this.errorMessage)
      : success = false,
        filePath = null;
}

class ExportService {
  static const int defaultScale = 10;
  static const int maxScale = 50;

  static Future<ExportResult> exportToPng(
    BeadDesign design, {
    int scale = defaultScale,
    bool showGrid = false,
    Color? backgroundColor,
    String? customPath,
  }) async {
    try {
      final image = await _generateDesignImage(
        design,
        scale: scale,
        showGrid: showGrid,
        backgroundColor: backgroundColor ?? Colors.white,
      );

      final filePath = customPath ?? await _getSavePath('${design.name}.png', 'PNG 文件', 'png');
      if (filePath == null) {
        return ExportResult.failure('未选择保存位置');
      }

      final file = File(filePath);
      await file.writeAsBytes(image);

      return ExportResult.success(filePath);
    } catch (e) {
      return ExportResult.failure('导出 PNG 失败: $e');
    }
  }

  static Future<ExportResult> exportToPdf(
    BeadDesign design, {
    PdfPageSize pageSize = PdfPageSize.a4,
    PdfOrientation orientation = PdfOrientation.portrait,
    bool showGrid = true,
    bool showCoordinates = true,
    String? customPath,
  }) async {
    try {
      final filePath = customPath ?? await _getSavePath('${design.name}.pdf', 'PDF 文件', 'pdf');
      if (filePath == null) {
        return ExportResult.failure('未选择保存位置');
      }

      await PdfGenerator.generateDesignPdf(
        design,
        pageSize: pageSize,
        orientation: orientation,
        showGrid: showGrid,
        showCoordinates: showCoordinates,
        customPath: filePath,
      );

      return ExportResult.success(filePath);
    } catch (e) {
      return ExportResult.failure('导出 PDF 失败: $e');
    }
  }

  static Future<ExportResult> exportMaterialList(
    BeadDesign design, {
    MaterialListFormat format = MaterialListFormat.csv,
    PdfPageSize pageSize = PdfPageSize.a4,
    PdfOrientation orientation = PdfOrientation.portrait,
    String? customPath,
  }) async {
    try {
      if (format == MaterialListFormat.pdf) {
        final filePath = customPath ?? await _getSavePath('${design.name}_材料清单.pdf', 'PDF 文件', 'pdf');
        if (filePath == null) {
          return ExportResult.failure('未选择保存位置');
        }

        await PdfGenerator.generateMaterialListPdf(
          design,
          pageSize: pageSize,
          orientation: orientation,
          customPath: filePath,
        );

        return ExportResult.success(filePath);
      } else {
        return await _exportMaterialListCsv(design, customPath);
      }
    } catch (e) {
      return ExportResult.failure('导出材料清单失败: $e');
    }
  }

  static Future<ExportResult> exportToImage(
    BeadDesign design, {
    int scale = defaultScale,
    Color backgroundColor = Colors.white,
    String? customPath,
  }) async {
    try {
      final image = await _generateDesignImage(
        design,
        scale: scale,
        showGrid: false,
        backgroundColor: backgroundColor,
      );

      final filePath = customPath ?? await _getSavePath('${design.name}.png', '图片文件', 'png');
      if (filePath == null) {
        return ExportResult.failure('未选择保存位置');
      }

      final file = File(filePath);
      await file.writeAsBytes(image);

      return ExportResult.success(filePath);
    } catch (e) {
      return ExportResult.failure('导出图片失败: $e');
    }
  }

  static Future<Uint8List> _generateDesignImage(
    BeadDesign design, {
    required int scale,
    required bool showGrid,
    required Color backgroundColor,
  }) async {
    final beadSize = scale.clamp(1, maxScale);
    final imageWidth = design.width * beadSize;
    final imageHeight = design.height * beadSize;

    final image = img.Image(width: imageWidth, height: imageHeight);

    final bgColor = img.ColorRgba8(
      (backgroundColor.r * 255.0).round().clamp(0, 255),
      (backgroundColor.g * 255.0).round().clamp(0, 255),
      (backgroundColor.b * 255.0).round().clamp(0, 255),
      (backgroundColor.a * 255.0).round().clamp(0, 255),
    );
    img.fill(image, color: bgColor);

    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final bead = design.grid[y][x];
        final startX = x * beadSize;
        final startY = y * beadSize;

        if (bead != null) {
          final beadColor = img.ColorRgba8(bead.red, bead.green, bead.blue, 255);
          img.fillRect(
            image,
            x1: startX,
            y1: startY,
            x2: startX + beadSize - 1,
            y2: startY + beadSize - 1,
            color: beadColor,
          );
        }

        if (showGrid) {
          final gridColor = img.ColorRgba8(200, 200, 200, 255);
          img.drawRect(
            image,
            x1: startX,
            y1: startY,
            x2: startX + beadSize - 1,
            y2: startY + beadSize - 1,
            color: gridColor,
          );
        }
      }
    }

    return Uint8List.fromList(img.encodePng(image, level: 9));
  }

  static Future<ExportResult> _exportMaterialListCsv(
    BeadDesign design,
    String? customPath,
  ) async {
    try {
      final beadCounts = design.getBeadCountsWithColors();
      final sortedColors = beadCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final totalBeads = sortedColors.fold(0, (sum, e) => sum + e.value);

      final rows = <List<dynamic>>[
        ['设计名称', design.name],
        ['尺寸', '${design.width} × ${design.height}'],
        ['总拼豆数', totalBeads],
        ['颜色种类', sortedColors.length],
        [],
        ['颜色代码', '颜色名称', '十六进制', '数量', '占比(%)'],
      ];

      for (final entry in sortedColors) {
        final color = entry.key;
        final count = entry.value;
        final percentage = (count / totalBeads * 100).toStringAsFixed(2);

        rows.add([
          color.code,
          color.name,
          color.hexCode,
          count,
          percentage,
        ]);
      }

      final csvData = const ListToCsvConverter().convert(rows);

      final filePath = customPath ?? await _getSavePath('${design.name}_材料清单.csv', 'CSV 文件', 'csv');
      if (filePath == null) {
        return ExportResult.failure('未选择保存位置');
      }

      final file = File(filePath);
      await file.writeAsString(csvData);

      return ExportResult.success(filePath);
    } catch (e) {
      return ExportResult.failure('导出 CSV 失败: $e');
    }
  }

  static Future<String?> _getSavePath(
    String suggestedName,
    String dialogTitle,
    String extension,
  ) async {
    String? outputPath;

    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: [extension],
      );
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final safeName = suggestedName.replaceAll(RegExp(r'[^\w.\s-]'), '_');
      outputPath = '${directory.path}/$safeName';
    }

    return outputPath;
  }

  static Future<Uint8List?> generatePreviewImage(
    BeadDesign design, {
    int scale = 5,
    bool showGrid = true,
    Color backgroundColor = Colors.white,
  }) async {
    try {
      return await _generateDesignImage(
        design,
        scale: scale,
        showGrid: showGrid,
        backgroundColor: backgroundColor,
      );
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic> getMaterialListData(
    BeadDesign design, {
    Inventory? inventory,
  }) {
    final beadCounts = design.getBeadCountsWithColors();
    final sortedColors = beadCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalBeads = sortedColors.fold(0, (sum, e) => sum + e.value);

    final items = <Map<String, dynamic>>[];

    for (final entry in sortedColors) {
      final color = entry.key;
      final count = entry.value;
      final percentage = (count / totalBeads * 100).toStringAsFixed(2);

      int? stockQuantity;
      bool hasStock = false;
      bool sufficient = false;

      if (inventory != null) {
        final inventoryItem = inventory.findByColorCode(color.code);
        if (inventoryItem != null) {
          stockQuantity = inventoryItem.quantity;
          hasStock = true;
          sufficient = stockQuantity >= count;
        }
      }

      items.add({
        'color': color,
        'count': count,
        'percentage': percentage,
        'stockQuantity': stockQuantity,
        'hasStock': hasStock,
        'sufficient': sufficient,
      });
    }

    return {
      'designName': design.name,
      'designSize': '${design.width} × ${design.height}',
      'totalBeads': totalBeads,
      'colorCount': sortedColors.length,
      'items': items,
    };
  }
}
