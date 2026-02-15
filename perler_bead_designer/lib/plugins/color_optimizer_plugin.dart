import '../models/bead_color.dart';
import '../models/bead_design.dart';
import '../models/plugin_interface.dart';

class ColorOptimizerPlugin implements IPlugin {
  @override
  String get name => 'color_optimizer';

  @override
  String get description => '优化设计中的颜色数量，合并相似颜色以简化设计。支持平滑边缘和对比度增强功能。';

  @override
  String get version => '1.1.0';

  @override
  PluginMetadata get metadata => const PluginMetadata(
    author: 'Perler Bead Designer',
    tags: ['color', 'optimization', 'simplify', 'merge'],
    category: 'color',
  );

  @override
  List<PluginParameter> get parameters => [
    PluginParameterNumber(
      key: 'colorThreshold',
      label: '颜色合并阈值',
      description: '颜色距离小于此值时将被合并（0-100），值越大合并越多',
      defaultValue: 30,
      min: 0,
      max: 100,
      step: 5,
    ),
    PluginParameterBoolean(
      key: 'smoothEdges',
      label: '平滑边缘',
      description: '平滑设计边缘，减少锯齿感',
      defaultValue: true,
    ),
    PluginParameterBoolean(
      key: 'enhanceContrast',
      label: '增强对比度',
      description: '增强颜色之间的对比度，使颜色更加鲜明',
      defaultValue: false,
    ),
    PluginParameterNumber(
      key: 'contrastFactor',
      label: '对比度系数',
      description: '对比度增强系数（1.0-2.0），值越大对比度越强',
      defaultValue: 1.2,
      min: 1.0,
      max: 2.0,
      step: 0.1,
    ),
  ];

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'colorThreshold': 30.0,
      'smoothEdges': true,
      'enhanceContrast': false,
      'contrastFactor': 1.2,
    };
  }

  @override
  bool validateParameters(Map<String, dynamic> params) {
    final threshold = params['colorThreshold'];
    if (threshold == null || threshold is! num) return false;
    if (threshold < 0 || threshold > 100) return false;

    final contrastFactor = params['contrastFactor'];
    if (contrastFactor == null || contrastFactor is! num) return false;
    if (contrastFactor < 1.0 || contrastFactor > 2.0) return false;

    return true;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'version': version,
      'metadata': metadata.toJson(),
      'parameters': parameters.map((p) => p.toJson()).toList(),
    };
  }

  @override
  PluginResult process(BeadDesign design, Map<String, dynamic> params) {
    try {
      final threshold = (params['colorThreshold'] as num).toDouble();
      final smoothEdges = params['smoothEdges'] as bool? ?? true;
      final enhanceContrast = params['enhanceContrast'] as bool? ?? false;
      final contrastFactor = (params['contrastFactor'] as num).toDouble();

      var currentDesign = design;
      final originalColorCount = design.getUniqueColorCount();
      final originalBeadCount = design.getTotalBeadCount();

      if (originalColorCount == 0) {
        return PluginResult.success(design, message: '设计中没有颜色，无需优化');
      }

      currentDesign = _reduceColors(currentDesign, threshold);

      if (smoothEdges) {
        currentDesign = _smoothEdges(currentDesign);
      }

      if (enhanceContrast) {
        currentDesign = _enhanceContrast(currentDesign, contrastFactor);
      }

      final newColorCount = currentDesign.getUniqueColorCount();
      final reducedColors = originalColorCount - newColorCount;

      return PluginResult.success(
        currentDesign,
        message: '颜色优化完成：从 $originalColorCount 种颜色减少到 $newColorCount 种颜色',
        statistics: {
          'original_colors': originalColorCount,
          'new_colors': newColorCount,
          'reduced_colors': reducedColors,
          'reduction_percent': originalColorCount > 0
              ? ((reducedColors / originalColorCount) * 100).toStringAsFixed(1)
              : '0.0',
          'threshold': threshold,
          'total_beads': originalBeadCount,
        },
      );
    } catch (e) {
      return PluginResult.failure(design, '颜色优化失败: ${e.toString()}');
    }
  }

  BeadDesign _reduceColors(BeadDesign design, double threshold) {
    final usedColors = design.getUsedColors();
    if (usedColors.length <= 1) return design;

    final colorGroups = <BeadColor, List<BeadColor>>{};
    final processed = <String>{};

    final sortedColors = usedColors.toList()
      ..sort((a, b) {
        final luminanceA = 0.299 * a.red + 0.587 * a.green + 0.114 * a.blue;
        final luminanceB = 0.299 * b.red + 0.587 * b.green + 0.114 * b.blue;
        return luminanceA.compareTo(luminanceB);
      });

    for (final color in sortedColors) {
      if (processed.contains(color.code)) continue;

      colorGroups[color] = [color];
      processed.add(color.code);

      for (final otherColor in sortedColors) {
        if (processed.contains(otherColor.code)) continue;

        final distance = color.distanceTo(otherColor);
        if (distance < threshold) {
          colorGroups[color]!.add(otherColor);
          processed.add(otherColor.code);
        }
      }
    }

    final colorMapping = <String, BeadColor>{};
    for (final entry in colorGroups.entries) {
      final representative = entry.key;
      for (final color in entry.value) {
        colorMapping[color.code] = representative;
      }
    }

    var newGrid = design.grid.map((row) => List<BeadColor?>.from(row)).toList();
    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final currentColor = design.grid[y][x];
        if (currentColor != null &&
            colorMapping.containsKey(currentColor.code)) {
          newGrid[y][x] = colorMapping[currentColor.code];
        }
      }
    }

    return design.copyWith(grid: newGrid);
  }

  BeadDesign _smoothEdges(BeadDesign design) {
    final newGrid = design.grid
        .map((row) => List<BeadColor?>.from(row))
        .toList();

    for (int y = 1; y < design.height - 1; y++) {
      for (int x = 1; x < design.width - 1; x++) {
        final current = design.grid[y][x];
        if (current == null) continue;

        final neighbors = <BeadColor>[];
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final neighbor = design.grid[y + dy][x + dx];
            if (neighbor != null && neighbor.code != current.code) {
              neighbors.add(neighbor);
            }
          }
        }

        if (neighbors.length >= 5) {
          final colorCounts = <String, int>{};
          final colorMap = <String, BeadColor>{};

          for (final neighbor in neighbors) {
            colorCounts[neighbor.code] = (colorCounts[neighbor.code] ?? 0) + 1;
            colorMap[neighbor.code] = neighbor;
          }

          var maxCount = 0;
          BeadColor? dominantColor;
          for (final entry in colorCounts.entries) {
            if (entry.value > maxCount) {
              maxCount = entry.value;
              dominantColor = colorMap[entry.key];
            }
          }

          if (dominantColor != null && maxCount >= 4) {
            newGrid[y][x] = dominantColor;
          }
        }
      }
    }

    return design.copyWith(grid: newGrid);
  }

  BeadDesign _enhanceContrast(BeadDesign design, double factor) {
    final usedColors = design.getUsedColors();
    if (usedColors.isEmpty) return design;

    int avgR = 0, avgG = 0, avgB = 0;
    int count = 0;

    for (final color in usedColors) {
      avgR += color.red;
      avgG += color.green;
      avgB += color.blue;
      count++;
    }

    if (count == 0) return design;

    avgR = avgR ~/ count;
    avgG = avgG ~/ count;
    avgB = avgB ~/ count;

    final colorMapping = <String, BeadColor>{};
    for (final color in usedColors) {
      int newR = ((color.red - avgR) * factor + avgR).round().clamp(0, 255);
      int newG = ((color.green - avgG) * factor + avgG).round().clamp(0, 255);
      int newB = ((color.blue - avgB) * factor + avgB).round().clamp(0, 255);

      final newCode = 'OPT_${newR}_${newG}_$newB';

      colorMapping[color.code] = BeadColor(
        code: newCode,
        name: '${color.name} (优化)',
        red: newR,
        green: newG,
        blue: newB,
        brand: color.brand,
        category: color.category,
      );
    }

    var newGrid = design.grid.map((row) => List<BeadColor?>.from(row)).toList();
    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final current = design.grid[y][x];
        if (current != null && colorMapping.containsKey(current.code)) {
          newGrid[y][x] = colorMapping[current.code];
        }
      }
    }

    return design.copyWith(grid: newGrid);
  }
}
