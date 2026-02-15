import '../models/bead_color.dart';
import '../models/bead_design.dart';
import '../models/plugin_interface.dart';

class OutlinePlugin implements IPlugin {
  @override
  String get name => 'outline';

  @override
  String get description => '自动添加轮廓和边缘检测，支持添加轮廓、边缘检测和提取轮廓三种模式。';

  @override
  String get version => '1.1.0';

  @override
  PluginMetadata get metadata => const PluginMetadata(
    author: 'Perler Bead Designer',
    tags: ['outline', 'edge', 'border', 'contour'],
    category: 'effect',
  );

  @override
  List<PluginParameter> get parameters => [
    PluginParameterSelect(
      key: 'mode',
      label: '轮廓模式',
      description: '选择轮廓处理模式',
      defaultValue: 'add_outline',
      options: [
        const SelectOption(value: 'add_outline', label: '添加轮廓'),
        const SelectOption(value: 'detect_edges', label: '边缘检测'),
        const SelectOption(value: 'extract_outline', label: '提取轮廓'),
      ],
    ),
    PluginParameterNumber(
      key: 'outlineThickness',
      label: '轮廓厚度',
      description: '轮廓线条的厚度（1-3像素）',
      defaultValue: 1,
      min: 1,
      max: 3,
      step: 1,
    ),
    PluginParameterBoolean(
      key: 'useCustomColor',
      label: '使用自定义颜色',
      description: '使用自定义轮廓颜色（默认黑色）',
      defaultValue: false,
    ),
    PluginParameterNumber(
      key: 'outlineColorR',
      label: '轮廓颜色 R',
      description: '轮廓颜色的红色分量（0-255）',
      defaultValue: 0,
      min: 0,
      max: 255,
      step: 1,
    ),
    PluginParameterNumber(
      key: 'outlineColorG',
      label: '轮廓颜色 G',
      description: '轮廓颜色的绿色分量（0-255）',
      defaultValue: 0,
      min: 0,
      max: 255,
      step: 1,
    ),
    PluginParameterNumber(
      key: 'outlineColorB',
      label: '轮廓颜色 B',
      description: '轮廓颜色的蓝色分量（0-255）',
      defaultValue: 0,
      min: 0,
      max: 255,
      step: 1,
    ),
    PluginParameterBoolean(
      key: 'detectInnerEdges',
      label: '检测内部边缘',
      description: '是否检测设计内部的边缘（颜色边界）',
      defaultValue: false,
    ),
  ];

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'mode': 'add_outline',
      'outlineThickness': 1.0,
      'useCustomColor': false,
      'outlineColorR': 0.0,
      'outlineColorG': 0.0,
      'outlineColorB': 0.0,
      'detectInnerEdges': false,
    };
  }

  @override
  bool validateParameters(Map<String, dynamic> params) {
    final mode = params['mode'];
    if (mode == null || mode is! String) return false;
    if (!['add_outline', 'detect_edges', 'extract_outline'].contains(mode)) {
      return false;
    }

    final thickness = params['outlineThickness'];
    if (thickness == null || thickness is! num) return false;
    if (thickness < 1 || thickness > 3) return false;

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
      final mode = params['mode'] as String;
      final thickness = (params['outlineThickness'] as num).toInt();
      final useCustomColor = params['useCustomColor'] as bool? ?? false;
      final outlineR = (params['outlineColorR'] as num?)?.toInt() ?? 0;
      final outlineG = (params['outlineColorG'] as num?)?.toInt() ?? 0;
      final outlineB = (params['outlineColorB'] as num?)?.toInt() ?? 0;
      final detectInnerEdges = params['detectInnerEdges'] as bool? ?? false;

      final originalBeadCount = design.getTotalBeadCount();

      if (originalBeadCount == 0) {
        return PluginResult.success(design, message: '设计中没有拼豆，无法处理轮廓');
      }

      BeadDesign result;
      String message;

      switch (mode) {
        case 'add_outline':
          result = _addOutline(
            design,
            thickness,
            useCustomColor,
            outlineR,
            outlineG,
            outlineB,
          );
          message = '已添加轮廓，厚度: $thickness 像素';
          break;
        case 'detect_edges':
          result = _detectEdges(design, detectInnerEdges);
          message = detectInnerEdges ? '已检测所有边缘（包括内部边界）' : '已检测外部边缘';
          break;
        case 'extract_outline':
          result = _extractOutline(design, thickness);
          message = '已提取轮廓';
          break;
        default:
          result = design;
          message = '未知模式';
      }

      final resultBeadCount = result.getTotalBeadCount();

      return PluginResult.success(
        result,
        message: message,
        statistics: {
          'mode': _getModeName(mode),
          'thickness': thickness,
          'original_beads': originalBeadCount,
          'result_beads': resultBeadCount,
          'beads_changed': (resultBeadCount - originalBeadCount).abs(),
        },
      );
    } catch (e) {
      return PluginResult.failure(design, '轮廓处理失败: ${e.toString()}');
    }
  }

  String _getModeName(String mode) {
    switch (mode) {
      case 'add_outline':
        return '添加轮廓';
      case 'detect_edges':
        return '边缘检测';
      case 'extract_outline':
        return '提取轮廓';
      default:
        return mode;
    }
  }

  BeadDesign _addOutline(
    BeadDesign design,
    int thickness,
    bool useCustomColor,
    int r,
    int g,
    int b,
  ) {
    final outlineColor = BeadColor(
      code: 'OUTLINE_${r}_${g}_$b',
      name: '轮廓色',
      red: r,
      green: g,
      blue: b,
      brand: BeadBrand.generic,
      category: 'outline',
    );

    final outlinePositions = <List<int>>[];

    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final current = design.grid[y][x];
        if (current == null) {
          if (_hasAdjacentBead(design, x, y)) {
            outlinePositions.add([x, y]);
          }
        }
      }
    }

    for (int t = 1; t < thickness; t++) {
      final additionalPositions = <List<int>>[];
      for (final pos in outlinePositions.toList()) {
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final nx = pos[0] + dx;
            final ny = pos[1] + dy;
            if (nx >= 0 && nx < design.width && ny >= 0 && ny < design.height) {
              if (design.grid[ny][nx] == null &&
                  !_containsPosition(outlinePositions, nx, ny) &&
                  !_containsPosition(additionalPositions, nx, ny)) {
                additionalPositions.add([nx, ny]);
              }
            }
          }
        }
      }
      outlinePositions.addAll(additionalPositions);
    }

    final newGrid = design.grid
        .map((row) => List<BeadColor?>.from(row))
        .toList();
    for (final pos in outlinePositions) {
      newGrid[pos[1]][pos[0]] = outlineColor;
    }

    return design.copyWith(grid: newGrid);
  }

  BeadDesign _detectEdges(BeadDesign design, bool detectInnerEdges) {
    final edgePositions = <List<int>>[];

    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final current = design.grid[y][x];
        if (current == null) continue;

        if (_isEdgePosition(design, x, y)) {
          edgePositions.add([x, y]);
        } else if (detectInnerEdges && _isColorBoundary(design, x, y)) {
          edgePositions.add([x, y]);
        }
      }
    }

    final newGrid = List.generate(
      design.height,
      (y) => List.generate(design.width, (x) {
        if (_containsPosition(edgePositions, x, y)) {
          return design.grid[y][x];
        }
        return null;
      }),
    );

    return design.copyWith(grid: newGrid);
  }

  BeadDesign _extractOutline(BeadDesign design, int thickness) {
    final outlinePositions = <List<int>>[];

    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final current = design.grid[y][x];
        if (current == null) continue;

        if (_isEdgePosition(design, x, y)) {
          outlinePositions.add([x, y]);
        }
      }
    }

    for (int t = 1; t < thickness; t++) {
      final innerPositions = <List<int>>[];
      for (final pos in outlinePositions.toList()) {
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final nx = pos[0] + dx;
            final ny = pos[1] + dy;
            if (nx >= 0 && nx < design.width && ny >= 0 && ny < design.height) {
              if (design.grid[ny][nx] != null &&
                  !_containsPosition(outlinePositions, nx, ny) &&
                  !_containsPosition(innerPositions, nx, ny)) {
                innerPositions.add([nx, ny]);
              }
            }
          }
        }
      }
      outlinePositions.addAll(innerPositions);
    }

    final newGrid = List.generate(
      design.height,
      (y) => List.generate(design.width, (x) {
        if (_containsPosition(outlinePositions, x, y)) {
          return design.grid[y][x];
        }
        return null;
      }),
    );

    return design.copyWith(grid: newGrid);
  }

  bool _hasAdjacentBead(BeadDesign design, int x, int y) {
    final directions = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    for (final dir in directions) {
      final nx = x + dir[0];
      final ny = y + dir[1];
      if (nx >= 0 && nx < design.width && ny >= 0 && ny < design.height) {
        if (design.grid[ny][nx] != null) {
          return true;
        }
      }
    }
    return false;
  }

  bool _isEdgePosition(BeadDesign design, int x, int y) {
    final directions = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    for (final dir in directions) {
      final nx = x + dir[0];
      final ny = y + dir[1];
      if (nx < 0 || nx >= design.width || ny < 0 || ny >= design.height) {
        return true;
      }
      if (design.grid[ny][nx] == null) {
        return true;
      }
    }
    return false;
  }

  bool _isColorBoundary(BeadDesign design, int x, int y) {
    final current = design.grid[y][x];
    if (current == null) return false;

    final directions = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];

    for (final dir in directions) {
      final nx = x + dir[0];
      final ny = y + dir[1];
      if (nx >= 0 && nx < design.width && ny >= 0 && ny < design.height) {
        final neighbor = design.grid[ny][nx];
        if (neighbor != null && neighbor.code != current.code) {
          return true;
        }
      }
    }
    return false;
  }

  bool _containsPosition(List<List<int>> positions, int x, int y) {
    return positions.any((pos) => pos[0] == x && pos[1] == y);
  }
}
