import 'dart:math';
import '../models/bead_color.dart';
import '../models/bead_design.dart';
import '../models/plugin_interface.dart';

class DitheringPlugin implements IPlugin {
  @override
  String get name => 'dithering';

  @override
  String get description => '使用抖动算法改善颜色过渡效果，支持 Floyd-Steinberg、有序抖动和 Atkinson 三种算法。';

  @override
  String get version => '1.1.0';

  @override
  PluginMetadata get metadata => const PluginMetadata(
        author: 'Perler Bead Designer',
        tags: ['dithering', 'color', 'transition', 'gradient'],
        category: 'color',
      );

  @override
  List<PluginParameter> get parameters => [
        PluginParameterSelect(
          key: 'algorithm',
          label: '抖动算法',
          description: '选择抖动算法类型',
          defaultValue: 'floyd_steinberg',
          options: [
            const SelectOption(value: 'floyd_steinberg', label: 'Floyd-Steinberg (推荐)'),
            const SelectOption(value: 'ordered', label: '有序抖动'),
            const SelectOption(value: 'atkinson', label: 'Atkinson (复古风格)'),
          ],
        ),
        PluginParameterNumber(
          key: 'intensity',
          label: '抖动强度',
          description: '抖动效果的强度（0.0-1.0），值越大效果越明显',
          defaultValue: 1.0,
          min: 0.0,
          max: 1.0,
          step: 0.1,
        ),
        PluginParameterBoolean(
          key: 'preserveColors',
          label: '保留原色',
          description: '尽可能保留原始颜色，减少颜色变化',
          defaultValue: true,
        ),
      ];

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'algorithm': 'floyd_steinberg',
      'intensity': 1.0,
      'preserveColors': true,
    };
  }

  @override
  bool validateParameters(Map<String, dynamic> params) {
    final algorithm = params['algorithm'];
    if (algorithm == null || algorithm is! String) return false;
    if (!['floyd_steinberg', 'ordered', 'atkinson'].contains(algorithm)) {
      return false;
    }

    final intensity = params['intensity'];
    if (intensity == null || intensity is! num) return false;
    if (intensity < 0.0 || intensity > 1.0) return false;

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
      final algorithm = params['algorithm'] as String;
      final intensity = (params['intensity'] as num).toDouble();
      final preserveColors = params['preserveColors'] as bool? ?? true;

      final usedColors = design.getUsedColors();
      if (usedColors.isEmpty) {
        return PluginResult.success(design, message: '设计中没有颜色，无需处理');
      }

      final originalBeadCount = design.getTotalBeadCount();
      final originalColorCount = design.getUniqueColorCount();

      BeadDesign result;
      switch (algorithm) {
        case 'floyd_steinberg':
          result = _floydSteinbergDither(design, usedColors, intensity, preserveColors);
          break;
        case 'ordered':
          result = _orderedDither(design, usedColors, intensity, preserveColors);
          break;
        case 'atkinson':
          result = _atkinsonDither(design, usedColors, intensity, preserveColors);
          break;
        default:
          result = _floydSteinbergDither(design, usedColors, intensity, preserveColors);
      }

      final newColorCount = result.getUniqueColorCount();

      return PluginResult.success(
        result,
        message: '抖动处理完成，使用 ${_getAlgorithmName(algorithm)} 算法',
        statistics: {
          'algorithm': _getAlgorithmName(algorithm),
          'intensity': '${(intensity * 100).toStringAsFixed(0)}%',
          'original_colors': originalColorCount,
          'result_colors': newColorCount,
          'total_beads': originalBeadCount,
        },
      );
    } catch (e) {
      return PluginResult.failure(design, '抖动处理失败: ${e.toString()}');
    }
  }

  String _getAlgorithmName(String algorithm) {
    switch (algorithm) {
      case 'floyd_steinberg':
        return 'Floyd-Steinberg';
      case 'ordered':
        return '有序抖动';
      case 'atkinson':
        return 'Atkinson';
      default:
        return algorithm;
    }
  }

  BeadDesign _floydSteinbergDither(
    BeadDesign design,
    List<BeadColor> palette,
    double intensity,
    bool preserveColors,
  ) {
    final width = design.width;
    final height = design.height;

    final errors = List.generate(
      height,
      (_) => List.generate(width, (_) => <double>[0, 0, 0]),
    );

    final newGrid = design.grid.map((row) => List<BeadColor?>.from(row)).toList();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final current = design.grid[y][x];
        if (current == null) continue;

        final oldR = current.red + errors[y][x][0];
        final oldG = current.green + errors[y][x][1];
        final oldB = current.blue + errors[y][x][2];

        final newColor = _findClosestColor(
          oldR.clamp(0, 255).round(),
          oldG.clamp(0, 255).round(),
          oldB.clamp(0, 255).round(),
          palette,
          preserveColors ? current : null,
        );

        newGrid[y][x] = newColor;

        final errR = (oldR - newColor.red) * intensity;
        final errG = (oldG - newColor.green) * intensity;
        final errB = (oldB - newColor.blue) * intensity;

        if (x + 1 < width) {
          errors[y][x + 1][0] += errR * 7 / 16;
          errors[y][x + 1][1] += errG * 7 / 16;
          errors[y][x + 1][2] += errB * 7 / 16;
        }
        if (y + 1 < height) {
          if (x > 0) {
            errors[y + 1][x - 1][0] += errR * 3 / 16;
            errors[y + 1][x - 1][1] += errG * 3 / 16;
            errors[y + 1][x - 1][2] += errB * 3 / 16;
          }
          errors[y + 1][x][0] += errR * 5 / 16;
          errors[y + 1][x][1] += errG * 5 / 16;
          errors[y + 1][x][2] += errB * 5 / 16;
          if (x + 1 < width) {
            errors[y + 1][x + 1][0] += errR * 1 / 16;
            errors[y + 1][x + 1][1] += errG * 1 / 16;
            errors[y + 1][x + 1][2] += errB * 1 / 16;
          }
        }
      }
    }

    return design.copyWith(grid: newGrid);
  }

  BeadDesign _orderedDither(
    BeadDesign design,
    List<BeadColor> palette,
    double intensity,
    bool preserveColors,
  ) {
    const bayerMatrix = [
      [0, 8, 2, 10],
      [12, 4, 14, 6],
      [3, 11, 1, 9],
      [15, 7, 13, 5],
    ];

    final newGrid = design.grid.map((row) => List<BeadColor?>.from(row)).toList();
    final matrixSize = bayerMatrix.length;

    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final current = design.grid[y][x];
        if (current == null) continue;

        final threshold = (bayerMatrix[y % matrixSize][x % matrixSize] / 16 - 0.5) * 64 * intensity;

        final adjustedR = (current.red + threshold).clamp(0, 255).round();
        final adjustedG = (current.green + threshold).clamp(0, 255).round();
        final adjustedB = (current.blue + threshold).clamp(0, 255).round();

        newGrid[y][x] = _findClosestColor(
          adjustedR,
          adjustedG,
          adjustedB,
          palette,
          preserveColors ? current : null,
        );
      }
    }

    return design.copyWith(grid: newGrid);
  }

  BeadDesign _atkinsonDither(
    BeadDesign design,
    List<BeadColor> palette,
    double intensity,
    bool preserveColors,
  ) {
    final width = design.width;
    final height = design.height;

    final errors = List.generate(
      height,
      (_) => List.generate(width, (_) => <double>[0, 0, 0]),
    );

    final newGrid = design.grid.map((row) => List<BeadColor?>.from(row)).toList();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final current = design.grid[y][x];
        if (current == null) continue;

        final oldR = current.red + errors[y][x][0];
        final oldG = current.green + errors[y][x][1];
        final oldB = current.blue + errors[y][x][2];

        final newColor = _findClosestColor(
          oldR.clamp(0, 255).round(),
          oldG.clamp(0, 255).round(),
          oldB.clamp(0, 255).round(),
          palette,
          preserveColors ? current : null,
        );

        newGrid[y][x] = newColor;

        final errR = (oldR - newColor.red) * intensity / 8;
        final errG = (oldG - newColor.green) * intensity / 8;
        final errB = (oldB - newColor.blue) * intensity / 8;

        final positions = [
          [0, 1],
          [0, 2],
          [1, -1],
          [1, 0],
          [1, 1],
          [2, 0],
        ];

        for (final pos in positions) {
          final ny = y + pos[0];
          final nx = x + pos[1];
          if (ny >= 0 && ny < height && nx >= 0 && nx < width) {
            errors[ny][nx][0] += errR;
            errors[ny][nx][1] += errG;
            errors[ny][nx][2] += errB;
          }
        }
      }
    }

    return design.copyWith(grid: newGrid);
  }

  BeadColor _findClosestColor(
    int r,
    int g,
    int b,
    List<BeadColor> palette,
    BeadColor? preferredColor,
  ) {
    if (preferredColor != null && palette.contains(preferredColor)) {
      final distance = sqrt(
        pow(r - preferredColor.red, 2) +
            pow(g - preferredColor.green, 2) +
            pow(b - preferredColor.blue, 2),
      );
      if (distance < 30) {
        return preferredColor;
      }
    }

    BeadColor? closest;
    double minDistance = double.infinity;

    for (final color in palette) {
      final distance = sqrt(
        pow(r - color.red, 2) +
            pow(g - color.green, 2) +
            pow(b - color.blue, 2),
      );
      if (distance < minDistance) {
        minDistance = distance;
        closest = color;
      }
    }

    return closest ?? palette.first;
  }
}
