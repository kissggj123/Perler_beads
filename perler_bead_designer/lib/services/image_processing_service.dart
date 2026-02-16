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

class GpuImageProcessor {
  static bool _isGpuAvailable = false;
  static bool _isInitialized = false;

  static bool get isGpuAvailable => _isGpuAvailable;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _isGpuAvailable = await _checkGpuSupport();
      debugPrint('GPU acceleration available: $_isGpuAvailable');
    } catch (e) {
      debugPrint('GPU initialization failed: $e');
      _isGpuAvailable = false;
    }
  }

  static Future<bool> _checkGpuSupport() async {
    try {
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final paint = Paint()..color = Colors.white;
      canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), paint);
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(1, 1);
      image.dispose();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<ui.Image> processImageWithGpu(
    ui.Image sourceImage, {
    required double brightness,
    required double contrast,
    required double saturation,
  }) async {
    final width = sourceImage.width;
    final height = sourceImage.height;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint();

    final colorFilter = _createColorFilter(brightness, contrast, saturation);
    paint.colorFilter = colorFilter;

    canvas.drawImage(sourceImage, Offset.zero, paint);

    final picture = pictureRecorder.endRecording();
    final resultImage = await picture.toImage(width, height);

    return resultImage;
  }

  static ColorFilter _createColorFilter(
    double brightness,
    double contrast,
    double saturation,
  ) {
    final brightnessMatrix = _brightnessMatrix(brightness);
    final contrastMatrix = _contrastMatrix(contrast);
    final saturationMatrix = _saturationMatrix(saturation);

    var combinedMatrix = _multiplyMatrices(brightnessMatrix, contrastMatrix);
    combinedMatrix = _multiplyMatrices(combinedMatrix, saturationMatrix);

    return ColorFilter.matrix(combinedMatrix);
  }

  static List<double> _brightnessMatrix(double brightness) {
    final b = brightness * 255;
    return [1, 0, 0, 0, b, 0, 1, 0, 0, b, 0, 0, 1, 0, b, 0, 0, 0, 1, 0];
  }

  static List<double> _contrastMatrix(double contrast) {
    final c = 1.0 + contrast;
    final t = (1.0 - c) / 2.0 * 255;
    return [c, 0, 0, 0, t, 0, c, 0, 0, t, 0, 0, c, 0, t, 0, 0, 0, 1, 0];
  }

  static List<double> _saturationMatrix(double saturation) {
    final s = 1.0 + saturation;
    final sr = (1 - s) * 0.2126;
    final sg = (1 - s) * 0.7152;
    final sb = (1 - s) * 0.0722;
    return [
      sr + s,
      sg,
      sb,
      0,
      0,
      sr,
      sg + s,
      sb,
      0,
      0,
      sr,
      sg,
      sb + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  static List<double> _multiplyMatrices(List<double> a, List<double> b) {
    return [
      a[0] * b[0] + a[1] * b[5] + a[2] * b[10] + a[3] * b[15],
      a[0] * b[1] + a[1] * b[6] + a[2] * b[11] + a[3] * b[16],
      a[0] * b[2] + a[1] * b[7] + a[2] * b[12] + a[3] * b[17],
      a[0] * b[3] + a[1] * b[8] + a[2] * b[13] + a[3] * b[18],
      a[0] * b[4] + a[1] * b[9] + a[2] * b[14] + a[3] * b[19] + a[4],

      a[5] * b[0] + a[6] * b[5] + a[7] * b[10] + a[8] * b[15],
      a[5] * b[1] + a[6] * b[6] + a[7] * b[11] + a[8] * b[16],
      a[5] * b[2] + a[6] * b[7] + a[7] * b[12] + a[8] * b[17],
      a[5] * b[3] + a[6] * b[8] + a[7] * b[13] + a[8] * b[18],
      a[5] * b[4] + a[6] * b[9] + a[7] * b[14] + a[8] * b[19] + a[9],

      a[10] * b[0] + a[11] * b[5] + a[12] * b[10] + a[13] * b[15],
      a[10] * b[1] + a[11] * b[6] + a[12] * b[11] + a[13] * b[16],
      a[10] * b[2] + a[11] * b[7] + a[12] * b[12] + a[13] * b[17],
      a[10] * b[3] + a[11] * b[8] + a[12] * b[13] + a[13] * b[18],
      a[10] * b[4] + a[11] * b[9] + a[12] * b[14] + a[13] * b[19] + a[14],

      a[15] * b[0] + a[16] * b[5] + a[17] * b[10] + a[18] * b[15],
      a[15] * b[1] + a[16] * b[6] + a[17] * b[11] + a[18] * b[16],
      a[15] * b[2] + a[16] * b[7] + a[17] * b[12] + a[18] * b[17],
      a[15] * b[3] + a[16] * b[8] + a[17] * b[13] + a[18] * b[18],
      a[15] * b[4] + a[16] * b[9] + a[17] * b[14] + a[18] * b[19] + a[19],

      0,
      0,
      0,
      0,
      1,
    ];
  }

  static Future<ui.Image> applyGpuBlur(ui.Image source, double radius) async {
    final width = source.width;
    final height = source.height;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final paint = Paint()
      ..imageFilter = ui.ImageFilter.blur(
        sigmaX: radius,
        sigmaY: radius,
        tileMode: TileMode.clamp,
      );

    canvas.drawImage(source, Offset.zero, paint);

    final picture = pictureRecorder.endRecording();
    return await picture.toImage(width, height);
  }

  static Future<ui.Image> applyGpuSharpen(
    ui.Image source,
    double strength,
  ) async {
    final width = source.width;
    final height = source.height;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    final k0 = -strength.toDouble();
    final k4 = (1 + 4 * strength).toDouble();

    final paint = Paint()
      ..colorFilter = ColorFilter.matrix([
        1.0 + k0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0 + k4,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0 + k0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ]);

    canvas.drawImage(source, Offset.zero, paint);

    final picture = pictureRecorder.endRecording();
    return await picture.toImage(width, height);
  }
}

class AutoImageAdjustment {
  final double brightness;
  final double contrast;
  final double saturation;
  final double sharpness;
  final String description;
  final double confidence;

  const AutoImageAdjustment({
    required this.brightness,
    required this.contrast,
    required this.saturation,
    this.sharpness = 0.0,
    this.description = '',
    this.confidence = 1.0,
  });

  static const AutoImageAdjustment neutral = AutoImageAdjustment(
    brightness: 0.0,
    contrast: 0.0,
    saturation: 0.0,
  );
}

class ImageAnalyzer {
  static Future<AutoImageAdjustment> analyzeImage(img.Image image) async {
    final analysis = await _analyzeInIsolate(image);

    return _calculateOptimalAdjustments(analysis);
  }

  static Future<_ImageAnalysis> _analyzeInIsolate(img.Image image) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _analyzeImageIsolate,
      _AnalysisData(
        sendPort: receivePort.sendPort,
        imageBytes: img.encodePng(image),
      ),
    );

    final result = await receivePort.first as _ImageAnalysis;
    receivePort.close();
    return result;
  }

  static void _analyzeImageIsolate(_AnalysisData data) {
    final image = img.decodeImage(data.imageBytes);
    if (image == null) {
      data.sendPort.send(_ImageAnalysis.empty());
      return;
    }

    double totalBrightness = 0;
    double totalSaturation = 0;
    int pixelCount = 0;

    final histogramR = List<int>.filled(256, 0);
    final histogramG = List<int>.filled(256, 0);
    final histogramB = List<int>.filled(256, 0);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt().clamp(0, 255);
        final g = pixel.g.toInt().clamp(0, 255);
        final b = pixel.b.toInt().clamp(0, 255);

        histogramR[r]++;
        histogramG[g]++;
        histogramB[b]++;

        final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        totalBrightness += luminance;

        final max = [r, g, b].reduce((a, b) => a > b ? a : b);
        final min = [r, g, b].reduce((a, b) => a < b ? a : b);
        if (max > 0) {
          totalSaturation += (max - min) / max;
        }

        pixelCount++;
      }
    }

    final avgBrightness = totalBrightness / pixelCount;
    final avgSaturation = totalSaturation / pixelCount;

    double variance = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
        variance += pow(luminance - avgBrightness, 2);
      }
    }
    final stdDev = sqrt(variance / pixelCount);
    final avgContrast = stdDev / 128.0;

    final analysis = _ImageAnalysis(
      averageBrightness: avgBrightness / 255.0,
      averageContrast: avgContrast,
      averageSaturation: avgSaturation,
      histogramR: histogramR,
      histogramG: histogramG,
      histogramB: histogramB,
      width: image.width,
      height: image.height,
    );

    data.sendPort.send(analysis);
  }

  static AutoImageAdjustment _calculateOptimalAdjustments(
    _ImageAnalysis analysis,
  ) {
    double brightness = 0.0;
    double contrast = 0.0;
    double saturation = 0.0;
    final List<String> adjustments = [];

    final targetBrightness = 0.5;
    final brightnessDiff = analysis.averageBrightness - targetBrightness;

    if (brightnessDiff.abs() > 0.05) {
      brightness = -brightnessDiff * 0.8;
      brightness = brightness.clamp(-0.5, 0.5);
      if (brightnessDiff > 0) {
        adjustments.add('降低亮度');
      } else {
        adjustments.add('提高亮度');
      }
    }

    final targetContrast = 0.35;
    final contrastDiff = analysis.averageContrast - targetContrast;

    if (contrastDiff.abs() > 0.05) {
      contrast = -contrastDiff * 0.6;
      contrast = contrast.clamp(-0.4, 0.4);
      if (contrastDiff > 0) {
        adjustments.add('降低对比度');
      } else {
        adjustments.add('提高对比度');
      }
    }

    final targetSaturation = 0.5;
    final saturationDiff = analysis.averageSaturation - targetSaturation;

    if (saturationDiff.abs() > 0.1) {
      saturation = -saturationDiff * 0.5;
      saturation = saturation.clamp(-0.4, 0.4);
      if (saturationDiff > 0) {
        adjustments.add('降低饱和度');
      } else {
        adjustments.add('提高饱和度');
      }
    }

    final dynamicRange = _calculateDynamicRange(analysis);
    if (dynamicRange < 0.7) {
      contrast += 0.1;
      adjustments.add('增强动态范围');
    }

    final colorCast = _detectColorCast(analysis);
    if (colorCast.abs() > 0.1) {
      if (colorCast > 0) {
        adjustments.add('检测到暖色调');
      } else {
        adjustments.add('检测到冷色调');
      }
    }

    String description;
    if (adjustments.isEmpty) {
      description = '图像质量良好，无需调整';
    } else {
      description = '建议调整: ${adjustments.join('、')}';
    }

    final confidence = _calculateConfidence(analysis);

    return AutoImageAdjustment(
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      description: description,
      confidence: confidence,
    );
  }

  static double _calculateDynamicRange(_ImageAnalysis analysis) {
    int minR = 255, maxR = 0;
    int minG = 255, maxG = 0;
    int minB = 255, maxB = 0;

    for (int i = 0; i < 256; i++) {
      if (analysis.histogramR[i] > 0) {
        minR = minR < i ? minR : i;
        maxR = maxR > i ? maxR : i;
      }
      if (analysis.histogramG[i] > 0) {
        minG = minG < i ? minG : i;
        maxG = maxG > i ? maxG : i;
      }
      if (analysis.histogramB[i] > 0) {
        minB = minB < i ? minB : i;
        maxB = maxB > i ? maxB : i;
      }
    }

    final rangeR = (maxR - minR) / 255.0;
    final rangeG = (maxG - minG) / 255.0;
    final rangeB = (maxB - minB) / 255.0;

    return (rangeR + rangeG + rangeB) / 3.0;
  }

  static double _detectColorCast(_ImageAnalysis analysis) {
    final avgR = _calculateHistogramAverage(analysis.histogramR);
    final avgB = _calculateHistogramAverage(analysis.histogramB);

    final warmCool = (avgR + avgB) / 2.0;
    return warmCool > 0 ? (avgR - avgB) / warmCool : 0;
  }

  static double _calculateHistogramAverage(List<int> histogram) {
    int total = 0;
    int count = 0;
    for (int i = 0; i < 256; i++) {
      total += i * histogram[i];
      count += histogram[i];
    }
    return count > 0 ? total / count : 0;
  }

  static double _calculateConfidence(_ImageAnalysis analysis) {
    double confidence = 1.0;

    if (analysis.width * analysis.height < 10000) {
      confidence *= 0.8;
    }

    if (analysis.averageBrightness < 0.1 || analysis.averageBrightness > 0.9) {
      confidence *= 0.7;
    }

    if (analysis.averageContrast < 0.1) {
      confidence *= 0.8;
    }

    return confidence.clamp(0.5, 1.0);
  }
}

class _ImageAnalysis {
  final double averageBrightness;
  final double averageContrast;
  final double averageSaturation;
  final List<int> histogramR;
  final List<int> histogramG;
  final List<int> histogramB;
  final int width;
  final int height;

  const _ImageAnalysis({
    required this.averageBrightness,
    required this.averageContrast,
    required this.averageSaturation,
    required this.histogramR,
    required this.histogramG,
    required this.histogramB,
    required this.width,
    required this.height,
  });

  factory _ImageAnalysis.empty() {
    return _ImageAnalysis(
      averageBrightness: 0.5,
      averageContrast: 0.35,
      averageSaturation: 0.5,
      histogramR: List<int>.filled(256, 0),
      histogramG: List<int>.filled(256, 0),
      histogramB: List<int>.filled(256, 0),
      width: 0,
      height: 0,
    );
  }
}

class _AnalysisData {
  final SendPort sendPort;
  final Uint8List imageBytes;

  const _AnalysisData({required this.sendPort, required this.imageBytes});
}

enum DitheringMode { none, floydSteinberg, ordered }

enum AlgorithmStyle { pixelArt, cartoon, realistic }

enum ExperimentalEffect {
  none,
  mosaic,
  oilPainting,
  sketch,
  neon,
  posterize,
  emboss,
  vintage,
  pixelate,
  watercolor,
}

extension ExperimentalEffectExtension on ExperimentalEffect {
  String get displayName {
    switch (this) {
      case ExperimentalEffect.none:
        return '无效果';
      case ExperimentalEffect.mosaic:
        return '马赛克';
      case ExperimentalEffect.oilPainting:
        return '油画';
      case ExperimentalEffect.sketch:
        return '素描';
      case ExperimentalEffect.neon:
        return '霓虹';
      case ExperimentalEffect.posterize:
        return '海报化';
      case ExperimentalEffect.emboss:
        return '浮雕';
      case ExperimentalEffect.vintage:
        return '复古';
      case ExperimentalEffect.pixelate:
        return '像素化';
      case ExperimentalEffect.watercolor:
        return '水彩';
    }
  }

  String get description {
    switch (this) {
      case ExperimentalEffect.none:
        return '保持原始效果';
      case ExperimentalEffect.mosaic:
        return '将图像分割成小块，每块使用平均颜色';
      case ExperimentalEffect.oilPainting:
        return '模拟油画笔触效果';
      case ExperimentalEffect.sketch:
        return '将图像转换为铅笔素描风格';
      case ExperimentalEffect.neon:
        return '添加发光霓虹灯效果';
      case ExperimentalEffect.posterize:
        return '减少颜色层次，产生海报效果';
      case ExperimentalEffect.emboss:
        return '创建浮雕立体效果';
      case ExperimentalEffect.vintage:
        return '添加复古怀旧滤镜';
      case ExperimentalEffect.pixelate:
        return '大像素块效果';
      case ExperimentalEffect.watercolor:
        return '模拟水彩画效果';
    }
  }

  IconData get icon {
    switch (this) {
      case ExperimentalEffect.none:
        return Icons.block;
      case ExperimentalEffect.mosaic:
        return Icons.grid_on;
      case ExperimentalEffect.oilPainting:
        return Icons.brush;
      case ExperimentalEffect.sketch:
        return Icons.draw;
      case ExperimentalEffect.neon:
        return Icons.lightbulb;
      case ExperimentalEffect.posterize:
        return Icons.filter_b_and_w;
      case ExperimentalEffect.emboss:
        return Icons.layers;
      case ExperimentalEffect.vintage:
        return Icons.camera_alt;
      case ExperimentalEffect.pixelate:
        return Icons.apps;
      case ExperimentalEffect.watercolor:
        return Icons.water_drop;
    }
  }
}

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
    if (factor == 0.0) return image;
    return img.adjustColor(image, brightness: factor * 255);
  }

  img.Image adjustContrast(img.Image image, double factor) {
    if (factor == 0.0) return image;
    return img.adjustColor(image, contrast: 1.0 + factor);
  }

  img.Image adjustSaturation(img.Image image, double factor) {
    if (factor == 0.0) return image;
    return img.adjustColor(image, saturation: 1.0 + factor);
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

    result = img.adjustColor(result, contrast: 1.3);
    result = img.adjustColor(result, saturation: 1.2);

    result = _applyEdgeEnhancement(result, strength: 1.5);

    result = _quantizeColors(result, colorLimit);

    return result;
  }

  img.Image _applyCartoonStyle(img.Image image) {
    var result = img.gaussianBlur(image, radius: 1);

    result = img.adjustColor(result, saturation: 1.4);
    result = img.adjustColor(result, contrast: 1.15);
    result = img.adjustColor(result, brightness: 10);

    result = _applyBilateralFilter(result, spatialSigma: 3, colorSigma: 30);

    result = _applyColorSmoothing(result, threshold: 25);

    return result;
  }

  img.Image _applyRealisticStyle(img.Image image) {
    var result = img.adjustColor(image, contrast: 1.05);

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

  img.Image applyExperimentalEffect(
    img.Image image,
    ExperimentalEffect effect, {
    double intensity = 1.0,
  }) {
    switch (effect) {
      case ExperimentalEffect.none:
        return image;
      case ExperimentalEffect.mosaic:
        return _applyMosaicEffect(
          image,
          blockSize: (8 * intensity).round().clamp(4, 32),
        );
      case ExperimentalEffect.oilPainting:
        return _applyOilPaintingEffect(
          image,
          radius: (3 * intensity).round().clamp(1, 8),
        );
      case ExperimentalEffect.sketch:
        return _applySketchEffect(image, intensity: intensity);
      case ExperimentalEffect.neon:
        return _applyNeonEffect(image, intensity: intensity);
      case ExperimentalEffect.posterize:
        return _applyPosterizeEffect(
          image,
          levels: (4 + (1 - intensity) * 4).round().clamp(2, 8),
        );
      case ExperimentalEffect.emboss:
        return _applyEmbossEffect(image, strength: intensity);
      case ExperimentalEffect.vintage:
        return _applyVintageEffect(image, intensity: intensity);
      case ExperimentalEffect.pixelate:
        return _applyPixelateEffect(
          image,
          blockSize: (4 + 8 * intensity).round().clamp(2, 16),
        );
      case ExperimentalEffect.watercolor:
        return _applyWatercolorEffect(image, intensity: intensity);
    }
  }

  img.Image _applyMosaicEffect(img.Image image, {int blockSize = 8}) {
    final result = img.Image(width: image.width, height: image.height);

    for (int by = 0; by < image.height; by += blockSize) {
      for (int bx = 0; bx < image.width; bx += blockSize) {
        int totalR = 0, totalG = 0, totalB = 0;
        int count = 0;

        for (int y = by; y < by + blockSize && y < image.height; y++) {
          for (int x = bx; x < bx + blockSize && x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            totalR += pixel.r.toInt();
            totalG += pixel.g.toInt();
            totalB += pixel.b.toInt();
            count++;
          }
        }

        if (count > 0) {
          final avgR = (totalR / count).round().clamp(0, 255);
          final avgG = (totalG / count).round().clamp(0, 255);
          final avgB = (totalB / count).round().clamp(0, 255);

          for (int y = by; y < by + blockSize && y < image.height; y++) {
            for (int x = bx; x < bx + blockSize && x < image.width; x++) {
              result.setPixel(x, y, img.ColorRgb8(avgR, avgG, avgB));
            }
          }
        }
      }
    }

    return result;
  }

  img.Image _applyOilPaintingEffect(img.Image image, {int radius = 3}) {
    final result = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final intensityCount = List<int>.filled(256, 0);
        final avgR = List<int>.filled(256, 0);
        final avgG = List<int>.filled(256, 0);
        final avgB = List<int>.filled(256, 0);

        for (int ky = -radius; ky <= radius; ky++) {
          for (int kx = -radius; kx <= radius; kx++) {
            final nx = (x + kx).clamp(0, image.width - 1);
            final ny = (y + ky).clamp(0, image.height - 1);

            final pixel = image.getPixel(nx, ny);
            final r = pixel.r.toInt();
            final g = pixel.g.toInt();
            final b = pixel.b.toInt();

            final intensity = ((r + g + b) / 3).round().clamp(0, 255);
            intensityCount[intensity]++;
            avgR[intensity] += r;
            avgG[intensity] += g;
            avgB[intensity] += b;
          }
        }

        int maxCount = 0;
        int maxIndex = 0;
        for (int i = 0; i < 256; i++) {
          if (intensityCount[i] > maxCount) {
            maxCount = intensityCount[i];
            maxIndex = i;
          }
        }

        if (maxCount > 0) {
          final r = (avgR[maxIndex] / maxCount).round().clamp(0, 255);
          final g = (avgG[maxIndex] / maxCount).round().clamp(0, 255);
          final b = (avgB[maxIndex] / maxCount).round().clamp(0, 255);
          result.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }
    }

    return result;
  }

  img.Image _applySketchEffect(img.Image image, {double intensity = 1.0}) {
    final gray = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final grayValue = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b)
            .round()
            .clamp(0, 255);
        gray.setPixel(x, y, img.ColorRgb8(grayValue, grayValue, grayValue));
      }
    }

    final inverted = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = gray.getPixel(x, y);
        final inv = 255 - pixel.r.toInt();
        inverted.setPixel(x, y, img.ColorRgb8(inv, inv, inv));
      }
    }

    final blurred = img.gaussianBlur(
      inverted,
      radius: (10 * intensity).round().clamp(3, 20),
    );

    final result = img.Image(width: image.width, height: image.height);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final grayPixel = gray.getPixel(x, y);
        final blurPixel = blurred.getPixel(x, y);

        final g = grayPixel.r.toInt();
        final b = blurPixel.r.toInt();

        int newValue;
        if (b == 255) {
          newValue = 255;
        } else {
          newValue = (g * 255 / (255 - b)).round().clamp(0, 255);
        }

        result.setPixel(x, y, img.ColorRgb8(newValue, newValue, newValue));
      }
    }

    return result;
  }

  img.Image _applyNeonEffect(img.Image image, {double intensity = 1.0}) {
    final edges = _detectEdges(image);

    final result = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final edgeValue = edges.getPixel(x, y).r.toInt();
        final pixel = image.getPixel(x, y);

        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final edgeFactor = (edgeValue / 255.0) * intensity;

        final neonR = (r * 0.3 + edgeFactor * 255).round().clamp(0, 255);
        final neonG = (g * 0.3 + edgeFactor * 200).round().clamp(0, 255);
        final neonB = (b * 0.3 + edgeFactor * 255).round().clamp(0, 255);

        result.setPixel(x, y, img.ColorRgb8(neonR, neonG, neonB));
      }
    }

    return img.adjustColor(
      result,
      saturation: 1.0 + 0.5 * intensity,
      brightness: 25,
    );
  }

  img.Image _detectEdges(img.Image image) {
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
        double gx = 0, gy = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final nx = (x + kx).clamp(0, image.width - 1);
            final ny = (y + ky).clamp(0, image.height - 1);

            final pixel = image.getPixel(nx, ny);
            final gray = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b);

            gx += gray * sobelX[ky + 1][kx + 1];
            gy += gray * sobelY[ky + 1][kx + 1];
          }
        }

        final magnitude = sqrt(gx * gx + gy * gy).clamp(0.0, 255.0).round();
        result.setPixel(x, y, img.ColorRgb8(magnitude, magnitude, magnitude));
      }
    }

    return result;
  }

  img.Image _applyPosterizeEffect(img.Image image, {int levels = 4}) {
    final result = img.Image(width: image.width, height: image.height);
    final step = 255 / (levels - 1);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        final r = (pixel.r.toInt() / step).round() * step;
        final g = (pixel.g.toInt() / step).round() * step;
        final b = (pixel.b.toInt() / step).round() * step;

        result.setPixel(
          x,
          y,
          img.ColorRgb8(
            r.round().clamp(0, 255),
            g.round().clamp(0, 255),
            b.round().clamp(0, 255),
          ),
        );
      }
    }

    return result;
  }

  img.Image _applyEmbossEffect(img.Image image, {double strength = 1.0}) {
    final result = img.Image(width: image.width, height: image.height);

    final kernel = [
      [-2, -1, 0],
      [-1, 1, 1],
      [0, 1, 2],
    ];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        double sumR = 0, sumG = 0, sumB = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final nx = (x + kx).clamp(0, image.width - 1);
            final ny = (y + ky).clamp(0, image.height - 1);

            final pixel = image.getPixel(nx, ny);
            final weight = kernel[ky + 1][kx + 1] * strength;

            sumR += pixel.r.toInt() * weight;
            sumG += pixel.g.toInt() * weight;
            sumB += pixel.b.toInt() * weight;
          }
        }

        final r = (sumR + 128).round().clamp(0, 255);
        final g = (sumG + 128).round().clamp(0, 255);
        final b = (sumB + 128).round().clamp(0, 255);

        result.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    return result;
  }

  img.Image _applyVintageEffect(img.Image image, {double intensity = 1.0}) {
    final result = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final vintageR = (r * 0.393 + g * 0.769 + b * 0.189).round().clamp(
          0,
          255,
        );
        final vintageG = (r * 0.349 + g * 0.686 + b * 0.168).round().clamp(
          0,
          255,
        );
        final vintageB = (r * 0.272 + g * 0.534 + b * 0.131).round().clamp(
          0,
          255,
        );

        final finalR = (r * (1 - intensity) + vintageR * intensity)
            .round()
            .clamp(0, 255);
        final finalG = (g * (1 - intensity) + vintageG * intensity)
            .round()
            .clamp(0, 255);
        final finalB = (b * (1 - intensity) + vintageB * intensity)
            .round()
            .clamp(0, 255);

        result.setPixel(x, y, img.ColorRgb8(finalR, finalG, finalB));
      }
    }

    final noise = img.Image(width: image.width, height: image.height);
    final random = Random(42);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = result.getPixel(x, y);
        final noiseValue = (random.nextDouble() - 0.5) * 30 * intensity;

        final r = (pixel.r.toInt() + noiseValue).round().clamp(0, 255);
        final g = (pixel.g.toInt() + noiseValue).round().clamp(0, 255);
        final b = (pixel.b.toInt() + noiseValue).round().clamp(0, 255);

        noise.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    return noise;
  }

  img.Image _applyPixelateEffect(img.Image image, {int blockSize = 8}) {
    final result = img.Image(width: image.width, height: image.height);

    for (int by = 0; by < image.height; by += blockSize) {
      for (int bx = 0; bx < image.width; bx += blockSize) {
        final pixel = image.getPixel(
          (bx + blockSize / 2).round().clamp(0, image.width - 1),
          (by + blockSize / 2).round().clamp(0, image.height - 1),
        );

        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        for (int y = by; y < by + blockSize && y < image.height; y++) {
          for (int x = bx; x < bx + blockSize && x < image.width; x++) {
            result.setPixel(x, y, img.ColorRgb8(r, g, b));
          }
        }
      }
    }

    return result;
  }

  img.Image _applyWatercolorEffect(img.Image image, {double intensity = 1.0}) {
    var result = img.gaussianBlur(image, radius: 2);

    result = _applyMedianFilter(
      result,
      radius: (3 * intensity).round().clamp(1, 5),
    );

    result = img.adjustColor(
      result,
      saturation: 1.0 + 0.2 * intensity,
      contrast: 1.1,
    );

    return result;
  }

  img.Image _applyMedianFilter(img.Image image, {int radius = 3}) {
    final result = img.Image(width: image.width, height: image.height);

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final redValues = <int>[];
        final greenValues = <int>[];
        final blueValues = <int>[];

        for (int ky = -radius; ky <= radius; ky++) {
          for (int kx = -radius; kx <= radius; kx++) {
            final nx = (x + kx).clamp(0, image.width - 1);
            final ny = (y + ky).clamp(0, image.height - 1);

            final pixel = image.getPixel(nx, ny);
            redValues.add(pixel.r.toInt());
            greenValues.add(pixel.g.toInt());
            blueValues.add(pixel.b.toInt());
          }
        }

        redValues.sort();
        greenValues.sort();
        blueValues.sort();

        final mid = redValues.length ~/ 2;
        result.setPixel(
          x,
          y,
          img.ColorRgb8(redValues[mid], greenValues[mid], blueValues[mid]),
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
