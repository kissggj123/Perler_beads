import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/bead_color.dart';
import '../models/bead_design.dart';
import '../models/color_palette.dart';

enum DitheringMode {
  none,
  floydSteinberg,
  ordered,
}

class ImageProcessingService {
  Future<img.Image?> loadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      return decodedImage;
    } catch (e) {
      debugPrint('Error loading image: $e');
      return null;
    }
  }

  img.Image resizeImage(img.Image image, int width, int height) {
    return img.copyResize(
      image,
      width: width,
      height: height,
      interpolation: img.Interpolation.average,
    );
  }

  img.Image pixelateImage(img.Image image, int beadWidth, int beadHeight) {
    final pixelWidth = image.width / beadWidth;
    final pixelHeight = image.height / beadHeight;

    final result = img.Image(width: beadWidth, height: beadHeight);

    for (int y = 0; y < beadHeight; y++) {
      for (int x = 0; x < beadWidth; x++) {
        final startX = (x * pixelWidth).round();
        final startY = (y * pixelHeight).round();
        final endX = ((x + 1) * pixelWidth).round().clamp(0, image.width);
        final endY = ((y + 1) * pixelHeight).round().clamp(0, image.height);

        int totalR = 0, totalG = 0, totalB = 0;
        int count = 0;

        for (int py = startY; py < endY; py++) {
          for (int px = startX; px < endX; px++) {
            if (px < image.width && py < image.height) {
              final pixel = image.getPixel(px, py);
              totalR += pixel.r.toInt();
              totalG += pixel.g.toInt();
              totalB += pixel.b.toInt();
              count++;
            }
          }
        }

        if (count > 0) {
          final avgR = (totalR / count).round().clamp(0, 255);
          final avgG = (totalG / count).round().clamp(0, 255);
          final avgB = (totalB / count).round().clamp(0, 255);
          result.setPixel(x, y, img.ColorRgb8(avgR, avgG, avgB));
        }
      }
    }

    return result;
  }

  Future<BeadDesign> convertToBeadDesign(
    img.Image pixelatedImage,
    ColorPalette palette,
    int width,
    int height,
    String designName, {
    DitheringMode ditheringMode = DitheringMode.none,
    void Function(double progress)? onProgress,
  }) async {
    final grid = List<List<BeadColor?>>.generate(
      height,
      (_) => List<BeadColor?>.filled(width, null),
    );

    final totalPixels = width * height;
    var processedPixels = 0;

    if (ditheringMode == DitheringMode.floydSteinberg) {
      return _convertWithFloydSteinbergDithering(
        pixelatedImage,
        palette,
        width,
        height,
        designName,
        onProgress,
      );
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (x < pixelatedImage.width && y < pixelatedImage.height) {
          final pixel = pixelatedImage.getPixel(x, y);
          final r = pixel.r.toInt().clamp(0, 255);
          final g = pixel.g.toInt().clamp(0, 255);
          final b = pixel.b.toInt().clamp(0, 255);

          grid[y][x] = matchColor(r, g, b, palette);
        }

        processedPixels++;
        if (onProgress != null && processedPixels % 100 == 0) {
          onProgress(processedPixels / totalPixels);
          await Future.delayed(Duration.zero);
        }
      }
    }

    final now = DateTime.now();
    return BeadDesign(
      id: 'imported_${now.millisecondsSinceEpoch}',
      name: designName,
      width: width,
      height: height,
      grid: grid,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<BeadDesign> _convertWithFloydSteinbergDithering(
    img.Image sourceImage,
    ColorPalette palette,
    int width,
    int height,
    String designName,
    void Function(double progress)? onProgress,
  ) async {
    final grid = List<List<BeadColor?>>.generate(
      height,
      (_) => List<BeadColor?>.filled(width, null),
    );

    final errorBuffer = List.generate(
      height,
      (_) => List.generate(width, (_) => [0.0, 0.0, 0.0]),
    );

    final totalPixels = width * height;
    var processedPixels = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (x < sourceImage.width && y < sourceImage.height) {
          final pixel = sourceImage.getPixel(x, y);
          var r = pixel.r.toDouble() + errorBuffer[y][x][0];
          var g = pixel.g.toDouble() + errorBuffer[y][x][1];
          var b = pixel.b.toDouble() + errorBuffer[y][x][2];

          r = r.clamp(0.0, 255.0);
          g = g.clamp(0.0, 255.0);
          b = b.clamp(0.0, 255.0);

          final matchedColor = matchColor(r.round(), g.round(), b.round(), palette);
          grid[y][x] = matchedColor;

          if (matchedColor != null) {
            final errorR = r - matchedColor.red;
            final errorG = g - matchedColor.green;
            final errorB = b - matchedColor.blue;

            _distributeError(errorBuffer, x, y, width, height, errorR, errorG, errorB);
          }
        }

        processedPixels++;
        if (onProgress != null && processedPixels % 100 == 0) {
          onProgress(processedPixels / totalPixels);
          await Future.delayed(Duration.zero);
        }
      }
    }

    final now = DateTime.now();
    return BeadDesign(
      id: 'imported_${now.millisecondsSinceEpoch}',
      name: designName,
      width: width,
      height: height,
      grid: grid,
      createdAt: now,
      updatedAt: now,
    );
  }

  void _distributeError(
    List<List<List<double>>> errorBuffer,
    int x, int y, int width, int height,
    double errorR, double errorG, double errorB,
  ) {
    final coefficients = [
      [1, 0, 7.0 / 16.0],
      [-1, 1, 3.0 / 16.0],
      [0, 1, 5.0 / 16.0],
      [1, 1, 1.0 / 16.0],
    ];

    for (final coeff in coefficients) {
      final nx = x + coeff[0].toInt();
      final ny = y + coeff[1].toInt();
      final factor = coeff[2];

      if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
        errorBuffer[ny][nx][0] += errorR * factor;
        errorBuffer[ny][nx][1] += errorG * factor;
        errorBuffer[ny][nx][2] += errorB * factor;
      }
    }
  }

  BeadColor? matchColor(int r, int g, int b, ColorPalette palette) {
    if (palette.isEmpty) return null;

    BeadColor? closestColor;
    double minDistance = double.infinity;

    for (final color in palette.colors) {
      final distance = _calculateColorDistance(
        r, g, b,
        color.red, color.green, color.blue,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color;
      }
    }

    return closestColor;
  }

  double _calculateColorDistance(int r1, int g1, int b1, int r2, int g2, int b2) {
    final dr = r2 - r1;
    final dg = g2 - g1;
    final db = b2 - b1;

    final meanR = (r1 + r2) / 2.0;

    final weightR = 2.0 + meanR / 256.0;
    final weightG = 4.0;
    final weightB = 2.0 + (255.0 - meanR) / 256.0;

    return sqrt(
      weightR * dr * dr +
      weightG * dg * dg +
      weightB * db * db
    );
  }

  Future<ui.Image> imageToFlutterImage(img.Image image) async {
    final completer = Completer<ui.Image>();
    final bytes = img.encodePng(image);
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  Future<List<List<Color>>> getImageColorGrid(
    img.Image image,
    int gridWidth,
    int gridHeight,
  ) async {
    final pixelated = pixelateImage(image, gridWidth, gridHeight);
    final grid = List<List<Color>>.generate(
      gridHeight,
      (_) => List<Color>.filled(gridWidth, Colors.transparent),
    );

    for (int y = 0; y < gridHeight; y++) {
      for (int x = 0; x < gridWidth; x++) {
        if (x < pixelated.width && y < pixelated.height) {
          final pixel = pixelated.getPixel(x, y);
          grid[y][x] = Color.fromRGBO(
            pixel.r.toInt().clamp(0, 255),
            pixel.g.toInt().clamp(0, 255),
            pixel.b.toInt().clamp(0, 255),
            1.0,
          );
        }
      }
    }

    return grid;
  }

  img.Image cropToSquare(img.Image image) {
    final size = image.width < image.height ? image.width : image.height;
    final offsetX = (image.width - size) ~/ 2;
    final offsetY = (image.height - size) ~/ 2;

    return img.copyCrop(
      image,
      x: offsetX,
      y: offsetY,
      width: size,
      height: size,
    );
  }

  img.Image adjustBrightness(img.Image image, double factor) {
    return img.adjustColor(image, brightness: factor);
  }

  img.Image adjustContrast(img.Image image, double factor) {
    return img.adjustColor(image, contrast: factor);
  }

  img.Image adjustSaturation(img.Image image, double factor) {
    return img.adjustColor(image, saturation: factor);
  }

  Map<String, int> analyzeColorUsage(img.Image image, ColorPalette palette) {
    final counts = <String, int>{};

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt().clamp(0, 255);
        final g = pixel.g.toInt().clamp(0, 255);
        final b = pixel.b.toInt().clamp(0, 255);

        final matchedColor = matchColor(r, g, b, palette);
        if (matchedColor != null) {
          counts[matchedColor.code] = (counts[matchedColor.code] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  List<ColorAnalysisResult> analyzeImageColors(
    img.Image image,
    ColorPalette palette,
  ) {
    final colorMap = <String, ColorAnalysisResult>{};

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt().clamp(0, 255);
        final g = pixel.g.toInt().clamp(0, 255);
        final b = pixel.b.toInt().clamp(0, 255);

        final matchedColor = matchColor(r, g, b, palette);
        if (matchedColor != null) {
          if (colorMap.containsKey(matchedColor.code)) {
            colorMap[matchedColor.code]!.count++;
          } else {
            colorMap[matchedColor.code] = ColorAnalysisResult(
              color: matchedColor,
              count: 1,
            );
          }
        }
      }
    }

    final results = colorMap.values.toList();
    results.sort((a, b) => b.count.compareTo(a.count));
    return results;
  }

  img.Image applyImageAdjustments(
    img.Image image, {
    double brightness = 0.0,
    double contrast = 0.0,
    double saturation = 0.0,
  }) {
    var result = image;

    if (brightness != 0.0) {
      result = adjustBrightness(result, brightness);
    }
    if (contrast != 0.0) {
      result = adjustContrast(result, contrast);
    }
    if (saturation != 0.0) {
      result = adjustSaturation(result, saturation);
    }

    return result;
  }
}

class ColorAnalysisResult {
  final BeadColor color;
  int count;

  ColorAnalysisResult({
    required this.color,
    required this.count,
  });

  double get percentage => count / 100.0;
}
