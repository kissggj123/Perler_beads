import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/bead_color.dart';
import '../models/bead_design.dart';
import '../models/color_palette.dart';

enum DitheringMode { none, floydSteinberg, ordered }

enum AlgorithmStyle { pixelArt, cartoon, realistic }

class ImageLoadResult {
  final img.Image image;
  final int originalWidth;
  final int originalHeight;
  final bool wasResized;

  ImageLoadResult({
    required this.image,
    required this.originalWidth,
    required this.originalHeight,
    required this.wasResized,
  });
}

extension AlgorithmStyleExtension on AlgorithmStyle {
  String get displayName {
    switch (this) {
      case AlgorithmStyle.pixelArt:
        return '像素艺术';
      case AlgorithmStyle.cartoon:
        return '卡通';
      case AlgorithmStyle.realistic:
        return '写实';
    }
  }

  String get description {
    switch (this) {
      case AlgorithmStyle.pixelArt:
        return '强调边缘，减少颜色数量，适合复古像素风格';
      case AlgorithmStyle.cartoon:
        return '平滑颜色过渡，饱和度增强，适合卡通风格';
      case AlgorithmStyle.realistic:
        return '保持原始颜色细节，适合写实风格';
    }
  }
}

class ImageProcessingService {
  static const int maxImageDimension = 4096;
  static const int preferredMaxDimension = 2048;
  static const int maxPixelsForProcessing = 4000000;

  Future<ImageLoadResult?> loadImageWithResize(
    File file, {
    int maxDimension = preferredMaxDimension,
    bool useIsolate = true,
  }) async {
    try {
      final bytes = await file.readAsBytes();

      if (useIsolate && bytes.length > 2 * 1024 * 1024) {
        return await _loadImageWithResizeInIsolate(bytes, maxDimension);
      }

      return _processImageBytes(bytes, maxDimension);
    } catch (e) {
      debugPrint('Error loading image: $e');
      return null;
    }
  }

  Future<ImageLoadResult?> _loadImageWithResizeInIsolate(
    Uint8List bytes,
    int maxDimension,
  ) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _isolateImageProcessor,
      _IsolateData(
        sendPort: receivePort.sendPort,
        bytes: bytes,
        maxDimension: maxDimension,
      ),
    );

    final result = await receivePort.first as Map<String, dynamic>?;
    receivePort.close();

    if (result == null) return null;

    return ImageLoadResult(
      image: result['image'] as img.Image,
      originalWidth: result['originalWidth'] as int,
      originalHeight: result['originalHeight'] as int,
      wasResized: result['wasResized'] as bool,
    );
  }

  static void _isolateImageProcessor(_IsolateData data) {
    final result = _processImageBytesStatic(data.bytes, data.maxDimension);
    data.sendPort.send(result);
  }

  static Map<String, dynamic>? _processImageBytesStatic(
    Uint8List bytes,
    int maxDimension,
  ) {
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) return null;

    final originalWidth = decodedImage.width;
    final originalHeight = decodedImage.height;

    bool wasResized = false;
    img.Image processedImage = decodedImage;

    if (originalWidth > maxDimension || originalHeight > maxDimension) {
      final aspectRatio = originalWidth / originalHeight;
      int newWidth, newHeight;

      if (aspectRatio > 1) {
        newWidth = maxDimension;
        newHeight = (maxDimension / aspectRatio).round();
      } else {
        newHeight = maxDimension;
        newWidth = (maxDimension * aspectRatio).round();
      }

      processedImage = img.copyResize(
        decodedImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.average,
      );
      wasResized = true;
    }

    return {
      'image': processedImage,
      'originalWidth': originalWidth,
      'originalHeight': originalHeight,
      'wasResized': wasResized,
    };
  }

  ImageLoadResult? _processImageBytes(Uint8List bytes, int maxDimension) {
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      return null;
    }

    final originalWidth = decodedImage.width;
    final originalHeight = decodedImage.height;
    final totalPixels = originalWidth * originalHeight;

    bool wasResized = false;
    img.Image processedImage = decodedImage;

    if (originalWidth > maxDimension || originalHeight > maxDimension) {
      final aspectRatio = originalWidth / originalHeight;
      int newWidth, newHeight;

      if (aspectRatio > 1) {
        newWidth = maxDimension;
        newHeight = (maxDimension / aspectRatio).round();
      } else {
        newHeight = maxDimension;
        newWidth = (maxDimension * aspectRatio).round();
      }

      processedImage = img.copyResize(
        decodedImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.average,
      );
      wasResized = true;
      debugPrint(
        'Image resized from ${originalWidth}x$originalHeight to ${newWidth}x$newHeight',
      );
    }

    return ImageLoadResult(
      image: processedImage,
      originalWidth: originalWidth,
      originalHeight: originalHeight,
      wasResized: wasResized,
    );
  }

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

  bool isImageTooLarge(int width, int height) {
    return width > maxImageDimension ||
        height > maxImageDimension ||
        (width * height) > maxPixelsForProcessing;
  }

  String getImageSizeWarning(int width, int height) {
    if (width > maxImageDimension || height > maxImageDimension) {
      return '图片尺寸过大 (${width}x$height)，已自动缩放';
    }
    if ((width * height) > maxPixelsForProcessing) {
      return '图片像素过多，已自动优化处理';
    }
    return '';
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

          final matchedColor = matchColor(
            r.round(),
            g.round(),
            b.round(),
            palette,
          );
          grid[y][x] = matchedColor;

          if (matchedColor != null) {
            final errorR = r - matchedColor.red;
            final errorG = g - matchedColor.green;
            final errorB = b - matchedColor.blue;

            _distributeError(
              errorBuffer,
              x,
              y,
              width,
              height,
              errorR,
              errorG,
              errorB,
            );
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
    int x,
    int y,
    int width,
    int height,
    double errorR,
    double errorG,
    double errorB,
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
        r,
        g,
        b,
        color.red,
        color.green,
        color.blue,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color;
      }
    }

    return closestColor;
  }

  double _calculateColorDistance(
    int r1,
    int g1,
    int b1,
    int r2,
    int g2,
    int b2,
  ) {
    final dr = r2 - r1;
    final dg = g2 - g1;
    final db = b2 - b1;

    final meanR = (r1 + r2) / 2.0;

    final weightR = 2.0 + meanR / 256.0;
    final weightG = 4.0;
    final weightB = 2.0 + (255.0 - meanR) / 256.0;

    return sqrt(weightR * dr * dr + weightG * dg * dg + weightB * db * db);
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

  img.Image applyAlgorithmStyle(
    img.Image image,
    AlgorithmStyle style, {
    int colorLimit = 16,
  }) {
    switch (style) {
      case AlgorithmStyle.pixelArt:
        return _applyPixelArtStyle(image, colorLimit: colorLimit);
      case AlgorithmStyle.cartoon:
        return _applyCartoonStyle(image);
      case AlgorithmStyle.realistic:
        return _applyRealisticStyle(image);
    }
  }

  img.Image _applyPixelArtStyle(img.Image image, {int colorLimit = 16}) {
    var result = img.copyResize(
      image,
      width: image.width,
      height: image.height,
    );

    result = img.adjustColor(result, contrast: 0.3);
    result = img.adjustColor(result, saturation: 0.2);

    result = _applyEdgeEnhancement(result, strength: 1.5);

    result = _quantizeColors(result, colorLimit);

    return result;
  }

  img.Image _applyCartoonStyle(img.Image image) {
    var result = img.gaussianBlur(image, radius: 1);

    result = img.adjustColor(result, saturation: 0.4);
    result = img.adjustColor(result, contrast: 0.15);
    result = img.adjustColor(result, brightness: 0.05);

    result = _applyBilateralFilter(result, spatialSigma: 3, colorSigma: 30);

    result = _applyColorSmoothing(result, threshold: 25);

    return result;
  }

  img.Image _applyRealisticStyle(img.Image image) {
    var result = img.adjustColor(image, contrast: 0.05);

    return result;
  }

  img.Image _applyEdgeEnhancement(img.Image image, {double strength = 1.0}) {
    final result = img.Image(width: image.width, height: image.height);

    final sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];

    final sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt().clamp(0, 255);
        final g = pixel.g.toInt().clamp(0, 255);
        final b = pixel.b.toInt().clamp(0, 255);

        double edgeR = 0, edgeG = 0, edgeB = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final nx = (x + kx).clamp(0, image.width - 1);
            final ny = (y + ky).clamp(0, image.height - 1);

            final neighborPixel = image.getPixel(nx, ny);
            final nr = neighborPixel.r.toInt();
            final ng = neighborPixel.g.toInt();
            final nb = neighborPixel.b.toInt();

            final kernelX = sobelX[ky + 1][kx + 1].toDouble();
            final kernelY = sobelY[ky + 1][kx + 1].toDouble();

            edgeR += nr * kernelX + nr * kernelY;
            edgeG += ng * kernelX + ng * kernelY;
            edgeB += nb * kernelX + nb * kernelY;
          }
        }

        final edgeMagnitude = sqrt(
          edgeR * edgeR + edgeG * edgeG + edgeB * edgeB,
        );
        final edgeFactor = 1.0 + (edgeMagnitude / 255.0) * strength * 0.3;

        final newR = (r * edgeFactor).round().clamp(0, 255);
        final newG = (g * edgeFactor).round().clamp(0, 255);
        final newB = (b * edgeFactor).round().clamp(0, 255);

        result.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }

    return result;
  }

  img.Image _quantizeColors(img.Image image, int colorLimit) {
    final colorMap = <int, int>{};
    final colorCounts = <int, int>{};

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = (pixel.r.toInt() / 32).floor() * 32;
        final g = (pixel.g.toInt() / 32).floor() * 32;
        final b = (pixel.b.toInt() / 32).floor() * 32;

        final quantizedColor = (r << 16) | (g << 8) | b;
        colorCounts[quantizedColor] = (colorCounts[quantizedColor] ?? 0) + 1;
      }
    }

    final sortedColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topColors = sortedColors.take(colorLimit).map((e) => e.key).toList();

    for (int i = 0; i < topColors.length; i++) {
      colorMap[topColors[i]] = i;
    }

    final result = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final quantizedColor = _findClosestColor(r, g, b, topColors);

        final qr = (quantizedColor >> 16) & 0xFF;
        final qg = (quantizedColor >> 8) & 0xFF;
        final qb = quantizedColor & 0xFF;

        result.setPixel(x, y, img.ColorRgb8(qr, qg, qb));
      }
    }

    return result;
  }

  int _findClosestColor(int r, int g, int b, List<int> colors) {
    int closestColor = colors.first;
    double minDistance = double.infinity;

    for (final color in colors) {
      final cr = (color >> 16) & 0xFF;
      final cg = (color >> 8) & 0xFF;
      final cb = color & 0xFF;

      final distance = sqrt(pow(r - cr, 2) + pow(g - cg, 2) + pow(b - cb, 2));

      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color;
      }
    }

    return closestColor;
  }

  img.Image _applyBilateralFilter(
    img.Image image, {
    double spatialSigma = 3.0,
    double colorSigma = 30.0,
  }) {
    final result = img.Image(width: image.width, height: image.height);
    final radius = (spatialSigma * 2).round();

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final centerPixel = image.getPixel(x, y);
        final cr = centerPixel.r.toDouble();
        final cg = centerPixel.g.toDouble();
        final cb = centerPixel.b.toDouble();

        double sumR = 0, sumG = 0, sumB = 0;
        double weightSum = 0;

        for (int ky = -radius; ky <= radius; ky++) {
          for (int kx = -radius; kx <= radius; kx++) {
            final nx = (x + kx).clamp(0, image.width - 1);
            final ny = (y + ky).clamp(0, image.height - 1);

            final neighborPixel = image.getPixel(nx, ny);
            final nr = neighborPixel.r.toDouble();
            final ng = neighborPixel.g.toDouble();
            final nb = neighborPixel.b.toDouble();

            final spatialDist = sqrt(kx * kx.toDouble() + ky * ky.toDouble());
            final colorDist = sqrt(
              pow(cr - nr, 2) + pow(cg - ng, 2) + pow(cb - nb, 2),
            );

            final spatialWeight = exp(
              -(spatialDist * spatialDist) / (2 * spatialSigma * spatialSigma),
            );
            final colorWeight = exp(
              -(colorDist * colorDist) / (2 * colorSigma * colorSigma),
            );
            final weight = spatialWeight * colorWeight;

            sumR += nr * weight;
            sumG += ng * weight;
            sumB += nb * weight;
            weightSum += weight;
          }
        }

        final newR = (sumR / weightSum).round().clamp(0, 255);
        final newG = (sumG / weightSum).round().clamp(0, 255);
        final newB = (sumB / weightSum).round().clamp(0, 255);

        result.setPixel(x, y, img.ColorRgb8(newR, newG, newB));
      }
    }

    return result;
  }

  img.Image _applyColorSmoothing(img.Image image, {int threshold = 25}) {
    final result = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final smoothedR = (r / threshold).round() * threshold;
        final smoothedG = (g / threshold).round() * threshold;
        final smoothedB = (b / threshold).round() * threshold;

        result.setPixel(
          x,
          y,
          img.ColorRgb8(
            smoothedR.clamp(0, 255),
            smoothedG.clamp(0, 255),
            smoothedB.clamp(0, 255),
          ),
        );
      }
    }

    return result;
  }
}

class ColorAnalysisResult {
  final BeadColor color;
  int count;

  ColorAnalysisResult({required this.color, required this.count});

  double get percentage => count / 100.0;
}

class _IsolateData {
  final SendPort sendPort;
  final Uint8List bytes;
  final int maxDimension;

  _IsolateData({
    required this.sendPort,
    required this.bytes,
    required this.maxDimension,
  });
}
