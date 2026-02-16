import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import '../models/bead_design.dart';
import '../models/color_palette.dart';
import '../services/image_processing_service.dart'
    show
        DitheringMode,
        AlgorithmStyle,
        ExperimentalEffect,
        ImageProcessingService,
        ColorAnalysisResult,
        GpuImageProcessor,
        AutoImageAdjustment,
        ImageAnalyzer;

enum ProcessingState { idle, loading, processing, completed, error }

class RecommendedSize {
  final int width;
  final int height;
  final String label;
  final String description;
  final int beadCount;

  const RecommendedSize({
    required this.width,
    required this.height,
    required this.label,
    required this.description,
    required this.beadCount,
  });

  double get aspectRatio => width / height;

  @override
  String toString() => '$width×$height ($label)';
}

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

  RecommendedSize? _recommendedSize;
  List<RecommendedSize> _alternativeSizes = [];

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
  ExperimentalEffect _experimentalEffect = ExperimentalEffect.none;
  double _effectIntensity = 1.0;

  bool _enableGpuAcceleration = true;
  bool _autoAdjustEnabled = false;
  AutoImageAdjustment? _autoAdjustment;
  bool _isAnalyzing = false;
  String? _autoAdjustDescription;

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
  RecommendedSize? get recommendedSize => _recommendedSize;
  List<RecommendedSize> get alternativeSizes => _alternativeSizes;

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
  ExperimentalEffect get experimentalEffect => _experimentalEffect;
  double get effectIntensity => _effectIntensity;

  bool get hasImage => _originalImage != null;
  bool get isProcessing =>
      _state == ProcessingState.loading || _state == ProcessingState.processing;
  bool get isCompleted => _state == ProcessingState.completed;

  bool get enableGpuAcceleration => _enableGpuAcceleration;
  bool get autoAdjustEnabled => _autoAdjustEnabled;
  AutoImageAdjustment? get autoAdjustment => _autoAdjustment;
  bool get isAnalyzing => _isAnalyzing;
  String? get autoAdjustDescription => _autoAdjustDescription;
  bool get isGpuAvailable => GpuImageProcessor.isGpuAvailable;

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

      _calculateRecommendedSizes();

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

      if (_experimentalEffect != ExperimentalEffect.none) {
        processedImage = _service.applyExperimentalEffect(
          processedImage,
          _experimentalEffect,
          intensity: _effectIntensity,
        );
      }

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

      if (_experimentalEffect != ExperimentalEffect.none) {
        processedImage = _service.applyExperimentalEffect(
          processedImage,
          _experimentalEffect,
          intensity: _effectIntensity,
        );
      }

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

  void setBrightness(double value, {bool generatePreview = true}) {
    _brightness = value.clamp(-1.0, 1.0);
    if (generatePreview) {
      _generatePreview();
    }
    notifyListeners();
  }

  void setContrast(double value, {bool generatePreview = true}) {
    _contrast = value.clamp(-1.0, 1.0);
    if (generatePreview) {
      _generatePreview();
    }
    notifyListeners();
  }

  void setSaturation(double value, {bool generatePreview = true}) {
    _saturation = value.clamp(-1.0, 1.0);
    if (generatePreview) {
      _generatePreview();
    }
    notifyListeners();
  }

  void setEffectIntensity(double intensity, {bool generatePreview = true}) {
    _effectIntensity = intensity.clamp(0.1, 2.0);
    if (generatePreview) {
      _generatePreview();
    }
    notifyListeners();
  }

  Future<void> applyPreview() async {
    await _generatePreview();
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

  void setExperimentalEffect(ExperimentalEffect effect) {
    _experimentalEffect = effect;
    _generatePreview();
    notifyListeners();
  }

  void resetAdjustments() {
    _brightness = 0.0;
    _contrast = 0.0;
    _saturation = 0.0;
    _ditheringMode = DitheringMode.none;
    _algorithmStyle = AlgorithmStyle.realistic;
    _experimentalEffect = ExperimentalEffect.none;
    _effectIntensity = 1.0;
    _generatePreview();
    notifyListeners();
  }

  void _adjustHeightToMaintainAspectRatio() {
    _outputHeight = (_outputWidth / _originalAspectRatio).round().clamp(1, 500);
  }

  void _adjustWidthToMaintainAspectRatio() {
    _outputWidth = (_outputHeight * _originalAspectRatio).round().clamp(1, 500);
  }

  void _calculateRecommendedSizes() {
    if (_originalImage == null) return;

    final imageWidth = _originalImage!.width;
    final imageHeight = _originalImage!.height;
    final aspectRatio = imageWidth / imageHeight;

    _alternativeSizes = [];

    final targetBeadCounts = [
      {'count': 400, 'label': '迷你', 'description': '适合初学者快速完成'},
      {'count': 841, 'label': '小号', 'description': '标准小号拼豆板'},
      {'count': 1225, 'label': '中号', 'description': '平衡细节与工作量'},
      {'count': 2500, 'label': '大号', 'description': '适合复杂图案'},
      {'count': 5000, 'label': '超大', 'description': '专业级精细作品'},
    ];

    RecommendedSize? bestMatch;
    double minDifference = double.infinity;

    for (final target in targetBeadCounts) {
      final targetCount = target['count'] as int;
      final label = target['label'] as String;
      final description = target['description'] as String;

      int width, height;
      if (aspectRatio >= 1) {
        width = sqrt(targetCount * aspectRatio).round();
        height = (width / aspectRatio).round();
      } else {
        height = sqrt(targetCount / aspectRatio).round();
        width = (height * aspectRatio).round();
      }

      width = width.clamp(10, 500);
      height = height.clamp(10, 500);

      final actualCount = width * height;
      final size = RecommendedSize(
        width: width,
        height: height,
        label: label,
        description: description,
        beadCount: actualCount,
      );

      _alternativeSizes.add(size);

      final difference = (actualCount - targetCount).abs().toDouble();
      if (difference < minDifference) {
        minDifference = difference;
        bestMatch = size;
      }
    }

    _recommendedSize = bestMatch;

    if (_recommendedSize != null) {
      _outputWidth = _recommendedSize!.width;
      _outputHeight = _recommendedSize!.height;
    }
  }

  void applyRecommendedSize(RecommendedSize size) {
    _outputWidth = size.width;
    _outputHeight = size.height;
    _generatePreview();
    notifyListeners();
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
    _experimentalEffect = ExperimentalEffect.none;
    _effectIntensity = 1.0;
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

  void setEnableGpuAcceleration(bool enable) {
    _enableGpuAcceleration = enable;
    notifyListeners();
  }

  void setAutoAdjustEnabled(bool enable) {
    _autoAdjustEnabled = enable;
    if (enable && _originalImage != null && _autoAdjustment == null) {
      analyzeAndAutoAdjust();
    } else if (!enable) {
      resetAdjustments();
    }
    notifyListeners();
  }

  Future<void> analyzeAndAutoAdjust() async {
    if (_originalImage == null || _isAnalyzing) return;

    _isAnalyzing = true;
    _autoAdjustDescription = '正在分析图像...';
    notifyListeners();

    try {
      _autoAdjustment = await ImageAnalyzer.analyzeImage(_originalImage!);

      if (_autoAdjustEnabled && _autoAdjustment != null) {
        _brightness = _autoAdjustment!.brightness;
        _contrast = _autoAdjustment!.contrast;
        _saturation = _autoAdjustment!.saturation;
        _autoAdjustDescription = _autoAdjustment!.description;

        await _generatePreview();
      }
    } catch (e) {
      debugPrint('Error analyzing image: $e');
      _autoAdjustDescription = '分析失败';
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void applyAutoAdjustment() {
    if (_autoAdjustment == null) return;

    _brightness = _autoAdjustment!.brightness;
    _contrast = _autoAdjustment!.contrast;
    _saturation = _autoAdjustment!.saturation;
    _generatePreview();
    notifyListeners();
  }

  Future<void> initializeGpuProcessor() async {
    await GpuImageProcessor.initialize();
    notifyListeners();
  }

  Future<ui.Image?> processWithGpu() async {
    if (_flutterOriginalImage == null) return null;
    if (!_enableGpuAcceleration || !GpuImageProcessor.isGpuAvailable) {
      return null;
    }

    try {
      return await GpuImageProcessor.processImageWithGpu(
        _flutterOriginalImage!,
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
      );
    } catch (e) {
      debugPrint('GPU processing failed: $e');
      return null;
    }
  }

  Map<String, dynamic> getProcessingInfo() {
    return {
      'gpuEnabled': _enableGpuAcceleration,
      'gpuAvailable': GpuImageProcessor.isGpuAvailable,
      'autoAdjustEnabled': _autoAdjustEnabled,
      'hasAutoAdjustment': _autoAdjustment != null,
      'currentAdjustments': {
        'brightness': _brightness,
        'contrast': _contrast,
        'saturation': _saturation,
      },
      'imageSize': '$_originalImageWidth x $_originalImageHeight',
      'outputSize': '$_outputWidth x $_outputHeight',
    };
  }
}
