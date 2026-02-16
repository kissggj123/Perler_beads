import 'package:flutter/material.dart';
import 'bead_color.dart';

class BeadDesign {
  final String id;
  final String name;
  final int width;
  final int height;
  final List<List<BeadColor?>> grid;
  final DateTime createdAt;
  final DateTime updatedAt;

  BeadDesign({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.grid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BeadDesign.fromJson(Map<String, dynamic> json) {
    try {
      final gridData = json['grid'] as List<dynamic>? ?? [];
      final grid = gridData.map((row) {
        if (row is! List) return <BeadColor?>[];
        return row.map((cell) {
          if (cell == null) return null;
          if (cell is! Map<String, dynamic>) return null;
          try {
            return BeadColor.fromJson(cell);
          } catch (e) {
            debugPrint('解析颜色失败: $e');
            return null;
          }
        }).toList();
      }).toList();

      final width = json['width'] as int? ?? 0;
      final height = json['height'] as int? ?? 0;

      if (width <= 0 || height <= 0) {
        debugPrint('无效的设计尺寸: $width x $height');
      }

      DateTime? createdAt;
      DateTime? updatedAt;

      try {
        createdAt = json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now();
      } catch (e) {
        debugPrint('解析创建时间失败: $e');
        createdAt = DateTime.now();
      }

      try {
        updatedAt = json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now();
      } catch (e) {
        debugPrint('解析更新时间失败: $e');
        updatedAt = DateTime.now();
      }

      return BeadDesign(
        id:
            json['id'] as String? ??
            'unknown_${DateTime.now().millisecondsSinceEpoch}',
        name: json['name'] as String? ?? '未命名设计',
        width: width,
        height: height,
        grid: grid,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      debugPrint('解析设计失败: $e');
      rethrow;
    }
  }

  factory BeadDesign.create({
    required String id,
    required String name,
    required int width,
    required int height,
  }) {
    final grid = List<List<BeadColor?>>.generate(
      height,
      (_) => List<BeadColor?>.filled(width, null),
    );
    final now = DateTime.now();
    return BeadDesign(
      id: id,
      name: name,
      width: width,
      height: height,
      grid: grid,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'width': width,
      'height': height,
      'grid': grid.map((row) {
        return row.map((cell) => cell?.toJson()).toList();
      }).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BeadDesign setBead(int x, int y, BeadColor? color) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return this;
    }

    final newGrid = grid.map((row) => List<BeadColor?>.from(row)).toList();
    newGrid[y][x] = color;

    return BeadDesign(
      id: id,
      name: name,
      width: width,
      height: height,
      grid: newGrid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  BeadColor? getBead(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return null;
    }
    return grid[y][x];
  }

  BeadDesign clearBead(int x, int y) {
    return setBead(x, y, null);
  }

  BeadDesign clearAll() {
    final newGrid = List<List<BeadColor?>>.generate(
      height,
      (_) => List<BeadColor?>.filled(width, null),
    );

    return BeadDesign(
      id: id,
      name: name,
      width: width,
      height: height,
      grid: newGrid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  BeadDesign fillAll(BeadColor color) {
    final newGrid = List<List<BeadColor?>>.generate(
      height,
      (_) => List<BeadColor?>.filled(width, color),
    );

    return BeadDesign(
      id: id,
      name: name,
      width: width,
      height: height,
      grid: newGrid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, int> getBeadCounts() {
    final counts = <String, int>{};

    for (final row in grid) {
      for (final cell in row) {
        if (cell != null) {
          counts[cell.code] = (counts[cell.code] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  Map<BeadColor, int> getBeadCountsWithColors() {
    final counts = <String, int>{};
    final colorMap = <String, BeadColor>{};

    for (final row in grid) {
      for (final cell in row) {
        if (cell != null) {
          counts[cell.code] = (counts[cell.code] ?? 0) + 1;
          colorMap[cell.code] = cell;
        }
      }
    }

    final result = <BeadColor, int>{};
    for (final entry in counts.entries) {
      final color = colorMap[entry.key];
      if (color != null) {
        result[color] = entry.value;
      }
    }

    return result;
  }

  int getTotalBeadCount() {
    int count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell != null) {
          count++;
        }
      }
    }
    return count;
  }

  int getUniqueColorCount() {
    return getBeadCounts().length;
  }

  List<BeadColor> getUsedColors() {
    final colorSet = <String, BeadColor>{};

    for (final row in grid) {
      for (final cell in row) {
        if (cell != null) {
          colorSet[cell.code] = cell;
        }
      }
    }

    return colorSet.values.toList();
  }

  BeadDesign copyWith({
    String? id,
    String? name,
    int? width,
    int? height,
    List<List<BeadColor?>>? grid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BeadDesign(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      grid: grid ?? this.grid.map((row) => List<BeadColor?>.from(row)).toList(),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  BeadDesign resize(int newWidth, int newHeight) {
    final newGrid = List<List<BeadColor?>>.generate(
      newHeight,
      (y) => List<BeadColor?>.generate(newWidth, (x) {
        if (y < height && x < width) {
          return grid[y][x];
        }
        return null;
      }),
    );

    return BeadDesign(
      id: id,
      name: name,
      width: newWidth,
      height: newHeight,
      grid: newGrid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool isValidPosition(int x, int y) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  BeadDesign flipHorizontal() {
    final newGrid = List<List<BeadColor?>>.generate(
      height,
      (y) => List<BeadColor?>.generate(width, (x) => grid[y][width - 1 - x]),
    );

    return BeadDesign(
      id: id,
      name: name,
      width: width,
      height: height,
      grid: newGrid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  BeadDesign flipVertical() {
    final newGrid = List<List<BeadColor?>>.generate(
      height,
      (y) => List<BeadColor?>.generate(width, (x) => grid[height - 1 - y][x]),
    );

    return BeadDesign(
      id: id,
      name: name,
      width: width,
      height: height,
      grid: newGrid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  BeadDesign rotateClockwise() {
    final newWidth = height;
    final newHeight = width;
    final newGrid = List<List<BeadColor?>>.generate(
      newHeight,
      (y) =>
          List<BeadColor?>.generate(newWidth, (x) => grid[height - 1 - x][y]),
    );

    return BeadDesign(
      id: id,
      name: name,
      width: newWidth,
      height: newHeight,
      grid: newGrid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  BeadDesign rotateCounterClockwise() {
    final newWidth = height;
    final newHeight = width;
    final newGrid = List<List<BeadColor?>>.generate(
      newHeight,
      (y) => List<BeadColor?>.generate(newWidth, (x) => grid[x][width - 1 - y]),
    );

    return BeadDesign(
      id: id,
      name: name,
      width: newWidth,
      height: newHeight,
      grid: newGrid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  BeadDesign rotate180() {
    final newGrid = List<List<BeadColor?>>.generate(
      height,
      (y) => List<BeadColor?>.generate(
        width,
        (x) => grid[height - 1 - y][width - 1 - x],
      ),
    );

    return BeadDesign(
      id: id,
      name: name,
      width: width,
      height: height,
      grid: newGrid,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  BeadDesign getSubRegion(int startX, int startY, int endX, int endY) {
    final clampedStartX = startX.clamp(0, width - 1);
    final clampedStartY = startY.clamp(0, height - 1);
    final clampedEndX = endX.clamp(0, width - 1);
    final clampedEndY = endY.clamp(0, height - 1);

    final regionWidth = (clampedEndX - clampedStartX + 1).abs();
    final regionHeight = (clampedEndY - clampedStartY + 1).abs();

    final actualStartX = startX < endX ? clampedStartX : clampedEndX;
    final actualStartY = startY < endY ? clampedStartY : clampedEndY;

    final newGrid = List<List<BeadColor?>>.generate(
      regionHeight,
      (y) => List<BeadColor?>.generate(
        regionWidth,
        (x) => grid[actualStartY + y][actualStartX + x],
      ),
    );

    return BeadDesign(
      id: '${id}_region_${DateTime.now().millisecondsSinceEpoch}',
      name: '$name (选区)',
      width: regionWidth,
      height: regionHeight,
      grid: newGrid,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  BeadDesign pasteRegion(BeadDesign region, int targetX, int targetY) {
    var newDesign = this;

    for (int y = 0; y < region.height; y++) {
      for (int x = 0; x < region.width; x++) {
        final destX = targetX + x;
        final destY = targetY + y;

        if (isValidPosition(destX, destY)) {
          final bead = region.getBead(x, y);
          if (bead != null) {
            newDesign = newDesign.setBead(destX, destY, bead);
          }
        }
      }
    }

    return newDesign;
  }

  @override
  String toString() {
    return 'BeadDesign(id: $id, name: $name, size: ${width}x$height, beads: ${getTotalBeadCount()})';
  }
}
