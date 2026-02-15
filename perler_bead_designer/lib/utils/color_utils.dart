import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bead_color.dart';

class ColorUtils {
  static int _getRed(Color color) => (color.r * 255.0).round().clamp(0, 255);
  static int _getGreen(Color color) => (color.g * 255.0).round().clamp(0, 255);
  static int _getBlue(Color color) => (color.b * 255.0).round().clamp(0, 255);
  static int _getAlpha(Color color) => (color.a * 255.0).round().clamp(0, 255);

  static double calculateColorDistance(Color a, Color b) {
    final rDiff = _getRed(a) - _getRed(b);
    final gDiff = _getGreen(a) - _getGreen(b);
    final bDiff = _getBlue(a) - _getBlue(b);
    return sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff);
  }

  static double calculateColorDistanceWeighted(Color a, Color b) {
    final aRed = _getRed(a);
    final bRed = _getRed(b);
    final rMean = (aRed + bRed) / 2;
    final rDiff = aRed - bRed;
    final gDiff = _getGreen(a) - _getGreen(b);
    final bDiff = _getBlue(a) - _getBlue(b);
    
    final rWeight = 2 + rMean / 256;
    final gWeight = 4.0;
    final bWeight = 2 + (255 - rMean) / 256;
    
    return sqrt(rWeight * rDiff * rDiff + gWeight * gDiff * gDiff + bWeight * bDiff * bDiff);
  }

  static BeadColor findClosestColor(Color target, List<BeadColor> palette) {
    if (palette.isEmpty) {
      throw ArgumentError('Color palette cannot be empty');
    }
    
    BeadColor closestColor = palette.first;
    double minDistance = double.infinity;
    
    for (final beadColor in palette) {
      final distance = calculateColorDistanceWeighted(target, beadColor.color);
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = beadColor;
      }
    }
    
    return closestColor;
  }

  static List<BeadColor> findClosestColors(Color target, List<BeadColor> palette, {int count = 5}) {
    if (palette.isEmpty) {
      return [];
    }
    
    final sortedColors = List<BeadColor>.from(palette);
    sortedColors.sort((a, b) {
      final distanceA = calculateColorDistanceWeighted(target, a.color);
      final distanceB = calculateColorDistanceWeighted(target, b.color);
      return distanceA.compareTo(distanceB);
    });
    
    return sortedColors.take(count).toList();
  }

  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '').replaceAll('0x', '').toUpperCase();
    
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    
    if (hex.length != 8) {
      throw FormatException('Invalid hex color format: $hex');
    }
    
    return Color(int.parse(hex, radix: 16));
  }

  static String colorToHex(Color color, {bool includeAlpha = false}) {
    final red = _getRed(color);
    final green = _getGreen(color);
    final blue = _getBlue(color);
    final alpha = _getAlpha(color);
    
    if (includeAlpha) {
      return '#${alpha.toRadixString(16).padLeft(2, '0')}${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
    }
    return '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  static HSLColor colorToHSL(Color color) {
    return HSLColor.fromColor(color);
  }

  static Color hslToColor(HSLColor hsl) {
    return hsl.toColor();
  }

  static double calculateLuminance(Color color) {
    return color.computeLuminance();
  }

  static bool isLightColor(Color color) {
    return calculateLuminance(color) > 0.5;
  }

  static bool isDarkColor(Color color) {
    return calculateLuminance(color) <= 0.5;
  }

  static Color getContrastColor(Color backgroundColor) {
    return isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }

  static Color blendColors(Color color1, Color color2, double ratio) {
    ratio = ratio.clamp(0.0, 1.0);
    
    final r = (_getRed(color1) * (1 - ratio) + _getRed(color2) * ratio).round();
    final g = (_getGreen(color1) * (1 - ratio) + _getGreen(color2) * ratio).round();
    final b = (_getBlue(color1) * (1 - ratio) + _getBlue(color2) * ratio).round();
    final a = (_getAlpha(color1) * (1 - ratio) + _getAlpha(color2) * ratio).round();
    
    return Color.fromRGBO(r, g, b, a / 255.0);
  }

  static Color lightenColor(Color color, {double amount = 0.1}) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  static Color darkenColor(Color color, {double amount = 0.1}) {
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  static Color saturateColor(Color color, {double amount = 0.1}) {
    final hsl = HSLColor.fromColor(color);
    final newSaturation = (hsl.saturation + amount).clamp(0.0, 1.0);
    return hsl.withSaturation(newSaturation).toColor();
  }

  static Color desaturateColor(Color color, {double amount = 0.1}) {
    final hsl = HSLColor.fromColor(color);
    final newSaturation = (hsl.saturation - amount).clamp(0.0, 1.0);
    return hsl.withSaturation(newSaturation).toColor();
  }

  static List<Color> generateColorPalette(Color startColor, Color endColor, int steps) {
    if (steps < 2) {
      return [startColor];
    }
    
    final palette = <Color>[];
    for (int i = 0; i < steps; i++) {
      final ratio = i / (steps - 1);
      palette.add(blendColors(startColor, endColor, ratio));
    }
    
    return palette;
  }

  static Map<String, dynamic> colorToMap(Color color) {
    return {
      'red': _getRed(color),
      'green': _getGreen(color),
      'blue': _getBlue(color),
      'alpha': _getAlpha(color),
      'hex': colorToHex(color, includeAlpha: true),
    };
  }

  static Color mapToColor(Map<String, dynamic> map) {
    if (map.containsKey('hex')) {
      return hexToColor(map['hex'] as String);
    }
    
    final alpha = (map['alpha'] as int?) ?? 255;
    return Color.fromRGBO(
      map['red'] as int,
      map['green'] as int,
      map['blue'] as int,
      alpha / 255.0,
    );
  }
}
