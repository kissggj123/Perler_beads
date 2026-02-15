import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import '../models/bead_design.dart';
import '../models/color_palette.dart';
import '../services/image_processing_service.dart';

enum ProcessingState { idle, loading, processing, completed, error }

class ImageProcessingProvider extends ChangeNotifier {
  final ImageProcessingService _service = ImageProcessingService();

  File? _selectedFile;
  img.Image? _originalImage;
  img.Image? _previewImage;
  ui.Image? _flutterOriginalImage;
  ui.Image? _flutterPreviewImage;

  int _originalImageWidth = 0;
  int _originalImageHeight = 0;
  bool _wasImageResized = false;

  int _outputWidth = 29;
  int _outputHeight = 29;
  bool _maintainAspectRatio = true;
  double _originalAspectRatio = 1.0;

  ProcessingState _state = ProcessingState.idle;
  double _progress = 0.0;
  String? _errorMessage;
  String? _warningMessage;

  BeadDesign? _resultDesign;
  List<ColorAnalysisResult> _colorAnalysis = [];

  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  DitheringMode _ditheringMode = DitheringMode.none;
  AlgorithmStyle _algorithmStyle = AlgorithmStyle.realistic;

  File? get selectedFile => _selectedFile;
  img.Image? get originalImage => _originalImage;
  img.Image? get previewImage => _previewImage;
  ui.Image? get flutterOriginalImage => _flutterOriginalImage;
  ui.Image? get flutterPreviewImage => _flutterPreviewImage;

  int get originalImageWidth => _originalImageWidth;
  int get originalImageHeight => _originalImageHeight;
  bool get wasImageResized => _wasImageResized;

  int get outputWidth => _outputWidth;
  int get outputHeight => _outputHeight;
  bool get maintainAspectRatio => _maintainAspectRatio;
  double get originalAspectRatio => _originalAspectRatio;

  ProcessingState get state => _state;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  String? get warningMessage => _warningMessage;
  BeadDesign? get resultDesign => _resultDesign;
  List<ColorAnalysisResult> get colorAnalysis => _colorAnalysis;

  double get brightness => _brightness;
  double get contrast => _contrast;
  double get saturation => _saturation;
  DitheringMode get ditheringMode => _ditheringMode;
  AlgorithmStyle get algorithmStyle => _algorithmStyle;

  bool get hasImage => _originalImage != null;
  bool get isProcessing =>
      _state == ProcessingState.loading || _state == ProcessingState.processing;
  bool get isCompleted => _state == ProcessingState.completed;

  Future<void> selectImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        await _loadImageFile(file);
      }
    } catch (e) {
      _setError('选择图片失败: $e');
    }
  }

  Future<void> selectImageFromFile(File file) async {
    await _loadImageFile(file);
  }

  Future<void> _loadImageFile(File file) async {
    _setState(ProcessingState.loading);
    _selectedFile = file;
    _warningMessage = null;

    try {
      final loadResult = await _service.loadImageWithResize(file);

      if (loadResult == null) {
        _setError('无法加载图片，请确保文件是有效的图片格式');
        return;
      }

      _originalImage = loadResult.image;
      _originalImageWidth = loadResult.originalWidth;
      _originalImageHeight = loadResult.originalHeight;
      _wasImageResized = loadResult.wasResized;

      if (loadResult.wasResized) {
        _warningMessage =
            '图片已自动缩放: ${loadResult.originalWidth}x${loadResult.originalHeight} → ${loadResult.image.width}x${loadResult.image.height}';
      }

      _originalAspectRatio = _originalImage!.width / _originalImage!.height;

      if (_maintainAspectRatio) {
        _adjustHeightToMaintainAspectRatio();
      }

      _flutterOriginalImage = await _service.imageToFlutterImage(
        _originalImage!,
      );

      await _generatePreview();

      _setState(ProcessingState.completed);
    } catch (e) {
      _setError('加载图片失败: $e');
    }
  }

  Future<void> _generatePreview() async {
    if (_originalImage == null) return;

    try {
      var processedImage = _service.applyImageAdjustments(
        _originalImage!,
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
      );

      processedImage = _service.applyAlgorithmStyle(
        processedImage,
        _algorithmStyle,
      );

      _previewImage = _service.pixelateImage(
        processedImage,
        _outputWidth,
        _outputHeight,
      );

      _flutterPreviewImage = await _service.imageToFlutterImage(_previewImage!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error generating preview: $e');
    }
  }

  Future<BeadDesign?> processImage(
    ColorPalette palette, {
    String? designName,
  }) async {
    if (_originalImage == null || _previewImage == null) {
      _setError('没有可处理的图片');
      return null;
    }

    _setState(ProcessingState.processing);
    _progress = 0.0;

    try {
      var processedImage = _service.applyImageAdjustments(
        _originalImage!,
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
      );

      processedImage = _service.applyAlgorithmStyle(
        processedImage,
        _algorithmStyle,
      );

      final pixelatedImage = _service.pixelateImage(
        processedImage,
        _outputWidth,
        _outputHeight,
      );

      final design = await _service.convertToBeadDesign(
        pixelatedImage,
        palette,
        _outputWidth,
        _outputHeight,
        designName ?? '导入设计',
        ditheringMode: _ditheringMode,
        onProgress: (progress) {
          _progress = progress;
          notifyListeners();
        },
      );

      _resultDesign = design;
      _colorAnalysis = _service.analyzeImageColors(pixelatedImage, palette);
      _setState(ProcessingState.completed);
      _progress = 1.0;

      return design;
    } catch (e) {
      _setError('处理图片失败: $e');
      return null;
    }
  }

  void setOutputSize(int width, int height) {
    _outputWidth = width.clamp(1, 500);
    _outputHeight = height.clamp(1, 500);

    if (_maintainAspectRatio && _originalImage != null) {
      _adjustHeightToMaintainAspectRatio();
    }

    _generatePreview();
    notifyListeners();
  }

  void setOutputWidth(int width) {
    _outputWidth = width.clamp(1, 500);

    if (_maintainAspectRatio && _originalImage != null) {
      _adjustHeightToMaintainAspectRatio();
    }

    _generatePreview();
    notifyListeners();
  }

  void setOutputHeight(int height) {
    _outputHeight = height.clamp(1, 500);

    if (_maintainAspectRatio && _originalImage != null) {
      _adjustWidthToMaintainAspectRatio();
    }

    _generatePreview();
    notifyListeners();
  }

  void setMaintainAspectRatio(bool value) {
    _maintainAspectRatio = value;

    if (value && _originalImage != null) {
      _adjustHeightToMaintainAspectRatio();
      _generatePreview();
    }

    notifyListeners();
  }

  void setBrightness(double value) {
    _brightness = value.clamp(-1.0, 1.0);
    _generatePreview();
    notifyListeners();
  }

  void setContrast(double value) {
    _contrast = value.clamp(-1.0, 1.0);
    _generatePreview();
    notifyListeners();
  }

  void setSaturation(double value) {
    _saturation = value.clamp(-1.0, 1.0);
    _generatePreview();
    notifyListeners();
  }

  void setDitheringMode(DitheringMode mode) {
    _ditheringMode = mode;
    notifyListeners();
  }

  void setAlgorithmStyle(AlgorithmStyle style) {
    _algorithmStyle = style;
    _generatePreview();
    notifyListeners();
  }

  void resetAdjustments() {
    _brightness = 0.0;
    _contrast = 0.0;
    _saturation = 0.0;
    _ditheringMode = DitheringMode.none;
    _algorithmStyle = AlgorithmStyle.realistic;
    _generatePreview();
    notifyListeners();
  }

  void _adjustHeightToMaintainAspectRatio() {
    _outputHeight = (_outputWidth / _originalAspectRatio).round().clamp(1, 500);
  }

  void _adjustWidthToMaintainAspectRatio() {
    _outputWidth = (_outputHeight * _originalAspectRatio).round().clamp(1, 500);
  }

  Future<void> analyzeColors(ColorPalette palette) async {
    if (_previewImage == null) return;

    _colorAnalysis = _service.analyzeImageColors(_previewImage!, palette);
    notifyListeners();
  }

  void clearImage() {
    _selectedFile = null;
    _originalImage = null;
    _previewImage = null;
    _flutterOriginalImage = null;
    _flutterPreviewImage = null;
    _originalImageWidth = 0;
    _originalImageHeight = 0;
    _wasImageResized = false;
    _resultDesign = null;
    _colorAnalysis = [];
    _progress = 0.0;
    _errorMessage = null;
    _warningMessage = null;
    _setState(ProcessingState.idle);
  }

  void clearWarning() {
    _warningMessage = null;
    notifyListeners();
  }

  void reset() {
    clearImage();
    _outputWidth = 29;
    _outputHeight = 29;
    _maintainAspectRatio = true;
    _originalAspectRatio = 1.0;
    _brightness = 0.0;
    _contrast = 0.0;
    _saturation = 0.0;
    _ditheringMode = DitheringMode.none;
    _algorithmStyle = AlgorithmStyle.realistic;
    notifyListeners();
  }

  void _setState(ProcessingState state) {
    _state = state;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(ProcessingState.error);
  }

  void clearError() {
    _errorMessage = null;
    if (_state == ProcessingState.error) {
      _setState(ProcessingState.idle);
    }
  }

  List<int> getCommonSizes() {
    return [29, 35, 50, 75, 100];
  }

  Map<String, int> getSizePresets() {
    return {
      '小 (29x29)': 29,
      '中 (50x50)': 50,
      '大 (75x75)': 75,
      '超大 (100x100)': 100,
    };
  }

  void applyPreset(int size) {
    _outputWidth = size;
    if (_maintainAspectRatio && _originalImage != null) {
      _adjustHeightToMaintainAspectRatio();
    } else {
      _outputHeight = size;
    }
    _generatePreview();
    notifyListeners();
  }

  int get totalBeadCount => _outputWidth * _outputHeight;

  String get dimensionInfo => '$_outputWidth × $_outputHeight';

  Color? getPixelColor(int gridX, int gridY) {
    if (_previewImage == null) return null;

    if (gridX < 0 ||
        gridX >= _outputWidth ||
        gridY < 0 ||
        gridY >= _outputHeight) {
      return null;
    }

    final cellWidth = _previewImage!.width / _outputWidth;
    final cellHeight = _previewImage!.height / _outputHeight;

    final pixelX = (gridX * cellWidth + cellWidth / 2).round().clamp(
      0,
      _previewImage!.width - 1,
    );
    final pixelY = (gridY * cellHeight + cellHeight / 2).round().clamp(
      0,
      _previewImage!.height - 1,
    );

    final pixel = _previewImage!.getPixel(pixelX, pixelY);

    return Color.fromARGB(
      pixel.a.toInt(),
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    );
  }
}
