
import 'package:image/image.dart' as img;

enum AlgorithmStyle { pixelArt, cartoon, realistic }

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

class AlgorithmStyleService {
  static img.Image applyAlgorithmStyle(
    img.Image image,
    AlgorithmStyle style,
  ) {
    switch (style) {
      case AlgorithmStyle.pixelArt:
        return _applyPixelArtStyle(image);
      case AlgorithmStyle.cartoon:
        return _applyCartoonStyle(image);
      case AlgorithmStyle.realistic:
        return image;
    }
  }

  static img.Image _applyPixelArtStyle(img.Image image) {
    final width = image.width;
    final height = image.height;

    final result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);

        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final avg = (r + g + b) ~/ 3;
        final quantized = (avg ~/ 32) * 32;

        final newPixel = img.ColorRgb8(
          quantized.clamp(0, 255),
          quantized.clamp(0, 255),
          quantized.clamp(0, 255),
        );

        result.setPixel(x, y, newPixel);
      }
    }

    return result;
  }

  static img.Image _applyCartoonStyle(img.Image image) {
    final width = image.width;
    final height = image.height;

    final result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);

        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final max = [r, g, b].reduce((a, b) => a > b ? a : b);
        final min = [r, g, b].reduce((a, b) => a < b ? a : b);
        final _ = max - min;

        final newR = ((r / 255) * 200 + 55).round().clamp(0, 255);
        final newG = ((g / 255) * 200 + 55).round().clamp(0, 255);
        final newB = ((b / 255) * 200 + 55).round().clamp(0, 255);

        final newPixel = img.ColorRgb8(newR, newG, newB);
        result.setPixel(x, y, newPixel);
      }
    }

    return result;
  }
}
