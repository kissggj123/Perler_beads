import 'dart:ui';
import 'dart:math';
import 'bead_color.dart';

class ColorPalette {
  final String id;
  final String name;
  final List<BeadColor> colors;
  final bool isDefault;

  const ColorPalette({
    required this.id,
    required this.name,
    required this.colors,
    this.isDefault = false,
  });

  factory ColorPalette.fromJson(Map<String, dynamic> json) {
    final colorsList = json['colors'] as List<dynamic>? ?? [];
    return ColorPalette(
      id: json['id'] as String,
      name: json['name'] as String,
      colors: colorsList
          .map((color) => BeadColor.fromJson(color as Map<String, dynamic>))
          .toList(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colors': colors.map((color) => color.toJson()).toList(),
      'isDefault': isDefault,
    };
  }

  ColorPalette addColor(BeadColor color) {
    if (colors.any((c) => c.code == color.code)) {
      return this;
    }
    return ColorPalette(
      id: id,
      name: name,
      colors: [...colors, color],
      isDefault: isDefault,
    );
  }

  ColorPalette removeColor(String colorCode) {
    return ColorPalette(
      id: id,
      name: name,
      colors: colors.where((color) => color.code != colorCode).toList(),
      isDefault: isDefault,
    );
  }

  ColorPalette updateColor(BeadColor updatedColor) {
    final newColors = colors.map((color) {
      if (color.code == updatedColor.code) {
        return updatedColor;
      }
      return color;
    }).toList();

    return ColorPalette(
      id: id,
      name: name,
      colors: newColors,
      isDefault: isDefault,
    );
  }

  BeadColor? findClosestColor(Color targetColor) {
    if (colors.isEmpty) return null;

    BeadColor? closestColor;
    double minDistance = double.infinity;

    for (final color in colors) {
      final dr = color.red - ((targetColor.r * 255.0).round().clamp(0, 255));
      final dg = color.green - ((targetColor.g * 255.0).round().clamp(0, 255));
      final db = color.blue - ((targetColor.b * 255.0).round().clamp(0, 255));
      final distance = sqrt(dr * dr + dg * dg + db * db);
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color;
      }
    }

    return closestColor;
  }

  BeadColor? findClosestColorToBeadColor(BeadColor targetColor) {
    if (colors.isEmpty) return null;

    BeadColor? closestColor;
    double minDistance = double.infinity;

    for (final color in colors) {
      if (color.code == targetColor.code) {
        return color;
      }
      final dr = color.red - targetColor.red;
      final dg = color.green - targetColor.green;
      final db = color.blue - targetColor.blue;
      final distance = sqrt(dr * dr + dg * dg + db * db);
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color;
      }
    }

    return closestColor;
  }

  BeadColor? findClosestColorToRgb(int r, int g, int b) {
    if (colors.isEmpty) return null;

    BeadColor? closestColor;
    double minDistance = double.infinity;

    for (final color in colors) {
      final dr = color.red - r;
      final dg = color.green - g;
      final db = color.blue - b;
      final distance = sqrt(dr * dr + dg * dg + db * db);
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color;
      }
    }

    return closestColor;
  }

  BeadColor? getColorByCode(String colorCode) {
    try {
      return colors.firstWhere((color) => color.code == colorCode);
    } catch (_) {
      return null;
    }
  }

  BeadColor? getColorByHex(String hex) {
    final normalizedHex = hex.startsWith('#') ? hex : '#$hex';
    try {
      return colors.firstWhere((color) => color.hexCode.toLowerCase() == normalizedHex.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  bool hasColor(String colorCode) {
    return colors.any((color) => color.code == colorCode);
  }

  List<BeadColor> searchColors(String query) {
    final lowerQuery = query.toLowerCase();
    return colors.where((color) {
      return color.name.toLowerCase().contains(lowerQuery) ||
          color.code.toLowerCase().contains(lowerQuery) ||
          color.hexCode.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<BeadColor> getLightColors() {
    return colors.where((color) {
      final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
      return luminance > 0.5;
    }).toList();
  }

  List<BeadColor> getDarkColors() {
    return colors.where((color) {
      final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
      return luminance <= 0.5;
    }).toList();
  }

  ColorPalette copyWith({
    String? id,
    String? name,
    List<BeadColor>? colors,
    bool? isDefault,
  }) {
    return ColorPalette(
      id: id ?? this.id,
      name: name ?? this.name,
      colors: colors ?? List<BeadColor>.from(this.colors),
      isDefault: isDefault ?? this.isDefault,
    );
  }

  int get colorCount => colors.length;

  bool get isEmpty => colors.isEmpty;

  bool get isNotEmpty => colors.isNotEmpty;

  static ColorPalette empty({String? id, String? name}) {
    return ColorPalette(
      id: id ?? 'empty',
      name: name ?? 'Empty Palette',
      colors: const [],
      isDefault: false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ColorPalette && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ColorPalette(id: $id, name: $name, colorCount: $colorCount, isDefault: $isDefault)';
  }
}
