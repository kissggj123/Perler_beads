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
    final gridData = json['grid'] as List<dynamic>? ?? [];
    final grid = gridData.map((row) {
      final rowData = row as List<dynamic>;
      return rowData.map((cell) {
        if (cell == null) return null;
        return BeadColor.fromJson(cell as Map<String, dynamic>);
      }).toList();
    }).toList();

    return BeadDesign(
      id: json['id'] as String,
      name: json['name'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      grid: grid,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
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
      (y) => List<BeadColor?>.generate(
        newWidth,
        (x) {
          if (y < height && x < width) {
            return grid[y][x];
          }
          return null;
        },
      ),
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

  @override
  String toString() {
    return 'BeadDesign(id: $id, name: $name, size: ${width}x$height, beads: ${getTotalBeadCount()})';
  }
}
