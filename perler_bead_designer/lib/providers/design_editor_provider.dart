import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/design_storage_service.dart';
import '../services/settings_service.dart';

enum ToolMode { draw, erase, fill }

class CanvasTransform {
  final double scale;
  final Offset offset;

  CanvasTransform({this.scale = 1.0, this.offset = Offset.zero});

  CanvasTransform copyWith({double? scale, Offset? offset}) {
    return CanvasTransform(
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CanvasTransform &&
        other.scale == scale &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(scale, offset);
}

class ShortcutSettings {
  final String moveUp;
  final String moveDown;
  final String moveLeft;
  final String moveRight;
  final String zoomIn;
  final String zoomOut;
  final String resetView;

  ShortcutSettings({
    this.moveUp = 'W',
    this.moveDown = 'S',
    this.moveLeft = 'A',
    this.moveRight = 'D',
    this.zoomIn = 'Q',
    this.zoomOut = 'E',
    this.resetView = 'R',
  });

  factory ShortcutSettings.fromSettings(SettingsService settings) {
    return ShortcutSettings(
      moveUp: settings.getStringSetting('shortcut_move_up') ?? 'W',
      moveDown: settings.getStringSetting('shortcut_move_down') ?? 'S',
      moveLeft: settings.getStringSetting('shortcut_move_left') ?? 'A',
      moveRight: settings.getStringSetting('shortcut_move_right') ?? 'D',
      zoomIn: settings.getStringSetting('shortcut_zoom_in') ?? 'Q',
      zoomOut: settings.getStringSetting('shortcut_zoom_out') ?? 'E',
      resetView: settings.getStringSetting('shortcut_reset_view') ?? 'R',
    );
  }

  Future<void> saveToSettings(SettingsService settings) async {
    await settings.setStringSetting('shortcut_move_up', moveUp);
    await settings.setStringSetting('shortcut_move_down', moveDown);
    await settings.setStringSetting('shortcut_move_left', moveLeft);
    await settings.setStringSetting('shortcut_move_right', moveRight);
    await settings.setStringSetting('shortcut_zoom_in', zoomIn);
    await settings.setStringSetting('shortcut_zoom_out', zoomOut);
    await settings.setStringSetting('shortcut_reset_view', resetView);
  }

  Map<String, String> toJson() {
    return {
      'moveUp': moveUp,
      'moveDown': moveDown,
      'moveLeft': moveLeft,
      'moveRight': moveRight,
      'zoomIn': zoomIn,
      'zoomOut': zoomOut,
      'resetView': resetView,
    };
  }
}

class EditorHistory {
  final BeadDesign design;
  final String? description;
  final DateTime timestamp;

  EditorHistory({required this.design, this.description, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

class DesignEditorProvider extends ChangeNotifier {
  BeadDesign? _currentDesign;
  BeadColor? _selectedColor;
  ToolMode _toolMode = ToolMode.draw;
  bool _showGrid = true;
  bool _showCoordinates = false;
  bool _showColorCodes = false;
  bool _isDirty = false;
  bool _hasEverBeenSaved = false;

  final List<EditorHistory> _undoStack = [];
  final List<EditorHistory> _redoStack = [];
  static const int _maxHistorySize = 50;

  final DesignStorageService _storageService = DesignStorageService();

  final List<BeadColor> _recentColors = [];
  static const int _maxRecentColors = 12;

  CanvasTransform _canvasTransform = CanvasTransform();
  static const double minScale = 0.25;
  static const double maxScale = 4.0;
  static const double moveStep = 50.0;
  static const double zoomStep = 0.1;

  ShortcutSettings _shortcutSettings = ShortcutSettings();

  bool _isBatchDrawing = false;
  bool _hasBatchChanges = false;
  BeadDesign? _batchStartDesign;
  bool _isPreviewMode = false;

  bool get isBatchDrawing => _isBatchDrawing;

  BeadDesign? get currentDesign => _currentDesign;
  BeadColor? get selectedColor => _selectedColor;
  ToolMode get toolMode => _toolMode;
  bool get showGrid => _showGrid;
  bool get showCoordinates => _showCoordinates;
  bool get showColorCodes => _showColorCodes;
  bool get isPreviewMode => _isPreviewMode;
  bool get isDirty =>
      _isDirty || (!_hasEverBeenSaved && _currentDesign != null);
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  List<BeadColor> get recentColors => List.unmodifiable(_recentColors);

  bool get hasDesign => _currentDesign != null;
  int get width => _currentDesign?.width ?? 0;
  int get height => _currentDesign?.height ?? 0;
  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  CanvasTransform get canvasTransform => _canvasTransform;
  ShortcutSettings get shortcutSettings => _shortcutSettings;

  void loadShortcutSettings(SettingsService settings) {
    _shortcutSettings = ShortcutSettings.fromSettings(settings);
    notifyListeners();
  }

  Future<void> updateShortcutSettings(ShortcutSettings settings) async {
    _shortcutSettings = settings;
    await settings.saveToSettings(SettingsService());
    notifyListeners();
  }

  void setCanvasTransform(CanvasTransform transform) {
    _canvasTransform = transform;
    notifyListeners();
  }

  void moveCanvas(double dx, double dy) {
    _canvasTransform = _canvasTransform.copyWith(
      offset: _canvasTransform.offset + Offset(dx, dy),
    );
    notifyListeners();
  }

  void zoomCanvas(double delta, {Offset? focalPoint}) {
    final newScale = (_canvasTransform.scale + delta).clamp(minScale, maxScale);

    if (focalPoint != null && newScale != _canvasTransform.scale) {
      final scaleRatio = newScale / _canvasTransform.scale;
      final newOffset = Offset(
        focalPoint.dx -
            (focalPoint.dx - _canvasTransform.offset.dx) * scaleRatio,
        focalPoint.dy -
            (focalPoint.dy - _canvasTransform.offset.dy) * scaleRatio,
      );
      _canvasTransform = CanvasTransform(scale: newScale, offset: newOffset);
    } else {
      _canvasTransform = _canvasTransform.copyWith(scale: newScale);
    }
    notifyListeners();
  }

  void resetCanvasTransform() {
    _canvasTransform = CanvasTransform();
    notifyListeners();
  }

  void handleKeyboardMove(String key) {
    final settings = _shortcutSettings;
    if (key.toUpperCase() == settings.moveUp) {
      moveCanvas(0, moveStep);
    } else if (key.toUpperCase() == settings.moveDown) {
      moveCanvas(0, -moveStep);
    } else if (key.toUpperCase() == settings.moveLeft) {
      moveCanvas(moveStep, 0);
    } else if (key.toUpperCase() == settings.moveRight) {
      moveCanvas(-moveStep, 0);
    } else if (key.toUpperCase() == settings.zoomIn) {
      zoomCanvas(zoomStep);
    } else if (key.toUpperCase() == settings.zoomOut) {
      zoomCanvas(-zoomStep);
    } else if (key.toUpperCase() == settings.resetView) {
      resetCanvasTransform();
    }
  }

  void createNewDesign({
    required String name,
    required int width,
    required int height,
  }) {
    final id = 'design_${DateTime.now().millisecondsSinceEpoch}';
    _currentDesign = BeadDesign.create(
      id: id,
      name: name,
      width: width,
      height: height,
    );
    _undoStack.clear();
    _redoStack.clear();
    _isDirty = false;
    _hasEverBeenSaved = false;
    notifyListeners();
  }

  Future<bool> loadDesign(String id) async {
    final design = await _storageService.loadDesign(id);
    if (design != null) {
      _currentDesign = design;
      _undoStack.clear();
      _redoStack.clear();
      _isDirty = false;
      _hasEverBeenSaved = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> loadDesignDirect(BeadDesign design) async {
    _currentDesign = design;
    _undoStack.clear();
    _redoStack.clear();
    _isDirty = false;
    _hasEverBeenSaved = true;
    notifyListeners();
    return true;
  }

  Future<bool> saveDesign() async {
    if (_currentDesign == null) return false;

    try {
      await _storageService.saveDesign(_currentDesign!);
      _isDirty = false;
      _hasEverBeenSaved = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('保存设计失败: $e');
      return false;
    }
  }

  void setSelectedColor(BeadColor? color) {
    _selectedColor = color;
    if (color != null) {
      _addToRecentColors(color);
    }
    notifyListeners();
  }

  void _addToRecentColors(BeadColor color) {
    _recentColors.remove(color);
    _recentColors.insert(0, color);
    if (_recentColors.length > _maxRecentColors) {
      _recentColors.removeLast();
    }
  }

  void setToolMode(ToolMode mode) {
    _toolMode = mode;
    notifyListeners();
  }

  void toggleGrid() {
    _showGrid = !_showGrid;
    notifyListeners();
  }

  void toggleCoordinates() {
    _showCoordinates = !_showCoordinates;
    notifyListeners();
  }

  void toggleColorCodes() {
    _showColorCodes = !_showColorCodes;
    notifyListeners();
  }

  void togglePreviewMode() {
    _isPreviewMode = !_isPreviewMode;
    notifyListeners();
  }

  void setPreviewMode(bool value) {
    _isPreviewMode = value;
    notifyListeners();
  }

  void _pushToUndoStack({String? description}) {
    if (_currentDesign == null) return;

    _undoStack.add(
      EditorHistory(design: _currentDesign!, description: description),
    );

    if (_undoStack.length > _maxHistorySize) {
      _undoStack.removeAt(0);
    }

    _redoStack.clear();
  }

  void startBatchDrawing() {
    if (_isBatchDrawing) return;
    _isBatchDrawing = true;
    _hasBatchChanges = false;
    _batchStartDesign = _currentDesign;
  }

  void endBatchDrawing() {
    if (!_isBatchDrawing) return;

    if (_hasBatchChanges && _batchStartDesign != null) {
      _undoStack.add(
        EditorHistory(design: _batchStartDesign!, description: '批量绘制'),
      );
      if (_undoStack.length > _maxHistorySize) {
        _undoStack.removeAt(0);
      }
      _redoStack.clear();
    }

    _isBatchDrawing = false;
    _hasBatchChanges = false;
    _batchStartDesign = null;
  }

  void setBead(int x, int y) {
    if (_currentDesign == null) return;
    if (!_currentDesign!.isValidPosition(x, y)) return;

    final currentBead = _currentDesign!.getBead(x, y);

    switch (_toolMode) {
      case ToolMode.draw:
        _handleDrawTool(x, y, currentBead);
        break;
      case ToolMode.erase:
        _handleEraseTool(x, y, currentBead);
        break;
      case ToolMode.fill:
        _handleFillTool(x, y, currentBead);
        break;
    }
  }

  void _handleDrawTool(int x, int y, BeadColor? currentBead) {
    if (_selectedColor == null) return;
    if (currentBead?.code == _selectedColor!.code) return;

    if (!_isBatchDrawing) {
      _pushToUndoStack(description: '绘制拼豆');
    } else if (!_hasBatchChanges) {
      _batchStartDesign = _currentDesign;
      _hasBatchChanges = true;
    }

    _currentDesign = _currentDesign!.setBead(x, y, _selectedColor);
    _isDirty = true;
    notifyListeners();
  }

  void _handleEraseTool(int x, int y, BeadColor? currentBead) {
    if (currentBead == null) return;

    if (!_isBatchDrawing) {
      _pushToUndoStack(description: '擦除拼豆');
    } else if (!_hasBatchChanges) {
      _batchStartDesign = _currentDesign;
      _hasBatchChanges = true;
    }

    _currentDesign = _currentDesign!.clearBead(x, y);
    _isDirty = true;
    notifyListeners();
  }

  void _handleFillTool(int x, int y, BeadColor? currentBead) {
    if (_selectedColor == null) return;
    _fillArea(x, y, currentBead, _selectedColor!);
  }

  void _fillArea(
    int startX,
    int startY,
    BeadColor? targetColor,
    BeadColor fillColor,
  ) {
    if (_currentDesign == null) return;
    if (targetColor?.code == fillColor.code) return;

    _pushToUndoStack(description: '填充区域');

    final visited = <String>{};
    final stack = <Point<int>>[Point(startX, startY)];
    var newDesign = _currentDesign!;

    while (stack.isNotEmpty) {
      final point = stack.removeLast();
      final x = point.x;
      final y = point.y;

      if (!newDesign.isValidPosition(x, y)) continue;

      final key = '$x,$y';
      if (visited.contains(key)) continue;
      visited.add(key);

      final currentBead = newDesign.getBead(x, y);
      if (currentBead?.code != targetColor?.code) continue;

      newDesign = newDesign.setBead(x, y, fillColor);

      stack.add(Point(x + 1, y));
      stack.add(Point(x - 1, y));
      stack.add(Point(x, y + 1));
      stack.add(Point(x, y - 1));
    }

    _currentDesign = newDesign;
    _isDirty = true;
    notifyListeners();
  }

  void clearBead(int x, int y) {
    if (_currentDesign == null) return;
    if (!_currentDesign!.isValidPosition(x, y)) return;

    final currentBead = _currentDesign!.getBead(x, y);
    if (currentBead == null) return;

    _pushToUndoStack(description: '清除拼豆');
    _currentDesign = _currentDesign!.clearBead(x, y);
    _isDirty = true;
    notifyListeners();
  }

  void clearAllBeads() {
    if (_currentDesign == null) return;

    _pushToUndoStack(description: '清空画布');
    _currentDesign = _currentDesign!.clearAll();
    _isDirty = true;
    notifyListeners();
  }

  void fillAllBeads() {
    if (_currentDesign == null) return;
    if (_selectedColor == null) return;

    _pushToUndoStack(description: '填充全部');
    _currentDesign = _currentDesign!.fillAll(_selectedColor!);
    _isDirty = true;
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty || _currentDesign == null) return;

    _redoStack.add(EditorHistory(design: _currentDesign!));
    _currentDesign = _undoStack.removeLast().design;
    _isDirty = true;
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty || _currentDesign == null) return;

    _undoStack.add(EditorHistory(design: _currentDesign!));
    _currentDesign = _redoStack.removeLast().design;
    _isDirty = true;
    notifyListeners();
  }

  void resizeDesign(int newWidth, int newHeight) {
    if (_currentDesign == null) return;
    if (newWidth <= 0 || newHeight <= 0) return;

    _pushToUndoStack(description: '调整大小');
    _currentDesign = _currentDesign!.resize(newWidth, newHeight);
    _isDirty = true;
    notifyListeners();
  }

  void renameDesign(String newName) {
    if (_currentDesign == null) return;
    if (newName.trim().isEmpty) return;

    _currentDesign = _currentDesign!.copyWith(name: newName.trim());
    _isDirty = true;
    notifyListeners();
  }

  Map<BeadColor, int> getBeadStatistics() {
    if (_currentDesign == null) return {};
    return _currentDesign!.getBeadCountsWithColors();
  }

  int getTotalBeadCount() {
    return _currentDesign?.getTotalBeadCount() ?? 0;
  }

  int getUniqueColorCount() {
    return _currentDesign?.getUniqueColorCount() ?? 0;
  }

  List<BeadColor> getUsedColors() {
    if (_currentDesign == null) return [];
    return _currentDesign!.getUsedColors();
  }

  Map<String, int> compareWithInventory(Inventory inventory) {
    final stats = getBeadStatistics();
    final comparison = <String, int>{};

    for (final entry in stats.entries) {
      final colorCode = entry.key.code;
      final required = entry.value;
      final available = inventory.getTotalQuantityForColor(colorCode);
      final difference = available - required;
      comparison[colorCode] = difference;
    }

    return comparison;
  }

  List<MapEntry<BeadColor, int>> getInsufficientColors(Inventory inventory) {
    final stats = getBeadStatistics();
    final insufficient = <MapEntry<BeadColor, int>>[];

    for (final entry in stats.entries) {
      final colorCode = entry.key.code;
      final required = entry.value;
      final available = inventory.getTotalQuantityForColor(colorCode);

      if (available < required) {
        insufficient.add(MapEntry(entry.key, required - available));
      }
    }

    return insufficient;
  }

  String getHistoryDescription() {
    if (_undoStack.isEmpty) return '无历史记录';
    return '可撤销 ${_undoStack.length} 步';
  }

  String getRedoDescription() {
    if (_redoStack.isEmpty) return '无可重做操作';
    return '可重做 ${_redoStack.length} 步';
  }

  void reset() {
    _currentDesign = null;
    _selectedColor = null;
    _toolMode = ToolMode.draw;
    _undoStack.clear();
    _redoStack.clear();
    _isDirty = false;
    notifyListeners();
  }
}

class Point<T> {
  final T x;
  final T y;

  Point(this.x, this.y);
}
