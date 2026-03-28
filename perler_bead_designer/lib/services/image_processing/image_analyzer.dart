import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

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
