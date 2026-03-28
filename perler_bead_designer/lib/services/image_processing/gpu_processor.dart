import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';

class GpuImageProcessor {
  static bool _isGpuAvailable = false;
  static bool _isInitialized = false;

  static bool get isGpuAvailable => _isGpuAvailable;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _isGpuAvailable = await _checkGpuSupport();
    } catch (e) {
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
