import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import '../models/models.dart';
import '../services/design_storage_service.dart';
import '../services/settings_service.dart';

final designEditorProvider = StateNotifierProvider<DesignEditorNotifier, DesignEditorState>(
  (ref) {
    final storageService = DesignStorageService();
    final settingsService = SettingsService();
    return DesignEditorNotifier(storageService, settingsService);
  },
);

class DesignEditorNotifier extends StateNotifier<DesignEditorState> {
  final DesignStorageService _storageService;
  final SettingsService _settingsService;

  DesignEditorNotifier(
    this._storageService,
    this._settingsService,
  ) : super(DesignEditorState.initial());

  Future<void> loadDesign(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final design = await _storageService.loadDesign(id);
      if (design != null) {
        state = state.copyWith(
          currentDesign: design,
          isLoading: false,
          hasEverBeenSaved: true,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString(),
      );
    }
  }

  Future<void> loadDesignDirect(BeadDesign design) async {
    state = state.copyWith(isLoading: true);
    try {
      state = state.copyWith(
        currentDesign: design,
        isLoading: false,
        hasEverBeenSaved: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        lastError: e.toString(),
      );
    }
  }

  Future<void> saveDesign() async {
    if (state.currentDesign == null) return;
    state = state.copyWith(isSaving: true);
    try {
      await _storageService.saveDesign(state.currentDesign!);
      state = state.copyWith(
        isSaving: false,
        isDirty: false,
        hasEverBeenSaved: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        lastError: e.toString(),
      );
    }
  }

  void setSelectedColor(BeadColor? color) {
    state = state.copyWith(selectedColor: color);
    if (color != null) {
      final recentColors = List<BeadColor>.from(state.recentColors);
      recentColors.remove(color);
      recentColors.insert(0, color);
      if (recentColors.length > 12) {
        recentColors.removeLast();
      }
      state = state.copyWith(recentColors: recentColors);
    }
  }

  void setToolMode(ToolMode mode) {
    state = state.copyWith(toolMode: mode);
  }

  void toggleGrid() {
    state = state.copyWith(showGrid: !state.showGrid);
  }

  void toggleCoordinates() {
    state = state.copyWith(showCoordinates: !state.showCoordinates);
  }

  void toggleColorCodes() {
    state = state.copyWith(showColorCodes: !state.showColorCodes);
  }

  void togglePreviewMode() {
    state = state.copyWith(isPreviewMode: !state.isPreviewMode);
  }

  void setPreviewMode(bool value) {
    state = state.copyWith(isPreviewMode: value);
  }

  void setCanvasTransform(CanvasTransform transform) {
    state = state.copyWith(canvasTransform: transform);
  }

  void moveCanvas(double dx, double dy) {
    final newOffset = state.canvasTransform.offset + Offset(dx, dy);
    state = state.copyWith(
      canvasTransform: state.canvasTransform.copyWith(offset: newOffset),
    );
  }

  void zoomCanvas(double delta, {Offset? focalPoint}) {
    final currentScale = state.canvasTransform.scale;
    final newScale = (currentScale + delta).clamp(0.25, 4.0);

    if (focalPoint != null && newScale != currentScale && currentScale > 0) {
      final scaleRatio = newScale / currentScale;
      final newOffset = Offset(
        focalPoint.dx -
            (focalPoint.dx - state.canvasTransform.offset.dx) * scaleRatio,
        focalPoint.dy -
            (focalPoint.dy - state.canvasTransform.offset.dy) * scaleRatio,
      );
      state = state.copyWith(
        canvasTransform: state.canvasTransform.copyWith(
          scale: newScale,
          offset: newOffset,
        ),
      );
    } else {
      state = state.copyWith(
        canvasTransform: state.canvasTransform.copyWith(scale: newScale),
      );
    }
  }

  void resetCanvasTransform() {
    state = state.copyWith(canvasTransform: CanvasTransform());
  }

  void setBead(int x, int y) {
    if (state.currentDesign == null) return;
    if (!state.currentDesign!.isValidPosition(x, y)) return;

    final currentBead = state.currentDesign!.getBead(x, y);

    switch (state.toolMode) {
      case ToolMode.draw:
        _handleDrawTool(x, y, currentBead);
        break;
      case ToolMode.erase:
        _handleEraseTool(x, y, currentBead);
        break;
      case ToolMode.fill:
        _handleFillTool(x, y, currentBead);
        break;
      case ToolMode.select:
        break;
    }
  }

  void _handleDrawTool(int x, int y, BeadColor? currentBead) {
    if (state.selectedColor == null) return;
    if (currentBead?.code == state.selectedColor!.code) return;

    final newDesign = state.currentDesign!.setBead(x, y, state.selectedColor);
    _updateDesign(newDesign, '绘制拼豆');
  }

  void _handleEraseTool(int x, int y, BeadColor? currentBead) {
    if (currentBead == null) return;

    final newDesign = state.currentDesign!.clearBead(x, y);
    _updateDesign(newDesign, '擦除拼豆');
  }

  void _handleFillTool(int x, int y, BeadColor? currentBead) {
    if (state.selectedColor == null) return;
    final newDesign = state.currentDesign!.clone();
    _fillArea(x, y, currentBead, state.selectedColor!, newDesign);
    _updateDesign(newDesign, '填充区域');
  }

  void _fillArea(
    int startX,
    int startY,
    BeadColor? targetColor,
    BeadColor fillColor,
    BeadDesign design,
  ) {
    if (targetColor?.code == fillColor.code) return;

    final visited = <String>{};
    final stack = <Point<int>>[Point(startX, startY)];

    while (stack.isNotEmpty) {
      final point = stack.removeLast();
      final x = point.x;
      final y = point.y;

      if (!design.isValidPosition(x, y)) continue;

      final key = '$x,$y';
      if (visited.contains(key)) continue;
      visited.add(key);

      final currentBead = design.getBead(x, y);
      if (currentBead?.code != targetColor?.code) continue;

      design = design.setBead(x, y, fillColor);

      stack.add(Point(x + 1, y));
      stack.add(Point(x - 1, y));
      stack.add(Point(x, y + 1));
      stack.add(Point(x, y - 1));
    }
  }

  void _updateDesign(BeadDesign newDesign, String description) {
    if (state.currentDesign == null) return;

    final newHistory = [
      ...state.history,
      EditorHistory(design: state.currentDesign!, description: description),
    ];
    if (newHistory.length > 50) {
      newHistory.removeAt(0);
    }

    state = state.copyWith(
      currentDesign: newDesign,
      history: newHistory,
      redoStack: [],
      isDirty: true,
    );
  }

  void undo() {
    if (state.history.isEmpty || state.currentDesign == null) return;

    final newHistory = List<EditorHistory>.from(state.history);
    final previousDesign = newHistory.removeLast().design;

    state = state.copyWith(
      currentDesign: previousDesign,
      history: newHistory,
      redoStack: [EditorHistory(design: state.currentDesign!), ...state.redoStack],
      isDirty: true,
    );
  }

  void redo() {
    if (state.redoStack.isEmpty || state.currentDesign == null) return;

    final newRedoStack = List<EditorHistory>.from(state.redoStack);
    final nextDesign = newRedoStack.removeLast().design;

    state = state.copyWith(
      currentDesign: nextDesign,
      history: [
        ...state.history,
        EditorHistory(design: state.currentDesign!),
      ],
      redoStack: newRedoStack,
      isDirty: true,
    );
  }

  void resizeDesign(int newWidth, int newHeight) {
    if (state.currentDesign == null) return;
    if (newWidth <= 0 || newHeight <= 0) return;

    final newDesign = state.currentDesign!.resize(newWidth, newHeight);
    _updateDesign(newDesign, '调整大小');
  }

  void renameDesign(String newName) {
    if (state.currentDesign == null) return;
    if (newName.trim().isEmpty) return;

    final newDesign = state.currentDesign!.copyWith(name: newName.trim());
    state = state.copyWith(currentDesign: newDesign, isDirty: true);
  }

  void clearAllBeads() {
    if (state.currentDesign == null) return;

    final newDesign = state.currentDesign!.clearAll();
    _updateDesign(newDesign, '清空画布');
  }

  void fillAllBeads() {
    if (state.currentDesign == null) return;
    if (state.selectedColor == null) return;

    final newDesign = state.currentDesign!.fillAll(state.selectedColor!);
    _updateDesign(newDesign, '填充全部');
  }

  void clearBead(int x, int y) {
    if (state.currentDesign == null) return;
    if (!state.currentDesign!.isValidPosition(x, y)) return;

    final currentBead = state.currentDesign!.getBead(x, y);
    if (currentBead == null) return;

    final newDesign = state.currentDesign!.clearBead(x, y);
    _updateDesign(newDesign, '清除拼豆');
  }

  void dispose() {
    super.dispose();
  }
}

class DesignEditorState {
  final BeadDesign? currentDesign;
  final BeadColor? selectedColor;
  final ToolMode toolMode;
  final bool showGrid;
  final bool showCoordinates;
  final bool showColorCodes;
  final bool isPreviewMode;
  final bool isDirty;
  final bool hasEverBeenSaved;
  final bool isLoading;
  final bool isSaving;
  final String lastError;
  final List<EditorHistory> history;
  final List<EditorHistory> redoStack;
  final List<BeadColor> recentColors;
  final CanvasTransform canvasTransform;
  final int maxHistorySize;

  const DesignEditorState({
    this.currentDesign,
    this.selectedColor,
    this.toolMode = ToolMode.draw,
    this.showGrid = true,
    this.showCoordinates = false,
    this.showColorCodes = false,
    this.isPreviewMode = false,
    this.isDirty = false,
    this.hasEverBeenSaved = false,
    this.isLoading = false,
    this.isSaving = false,
    this.lastError = '',
    this.history = const [],
    this.redoStack = const [],
    this.recentColors = const [],
    this.canvasTransform = const CanvasTransform(),
    this.maxHistorySize = 50,
  });

  factory DesignEditorState.initial() {
    return const DesignEditorState();
  }

  DesignEditorState copyWith({
    BeadDesign? currentDesign,
    BeadColor? selectedColor,
    ToolMode? toolMode,
    bool? showGrid,
    bool? showCoordinates,
    bool? showColorCodes,
    bool? isPreviewMode,
    bool? isDirty,
    bool? hasEverBeenSaved,
    bool? isLoading,
    bool? isSaving,
    String? lastError,
    List<EditorHistory>? history,
    List<EditorHistory>? redoStack,
    List<BeadColor>? recentColors,
    CanvasTransform? canvasTransform,
    int? maxHistorySize,
  }) {
    return DesignEditorState(
      currentDesign: currentDesign ?? this.currentDesign,
      selectedColor: selectedColor ?? this.selectedColor,
      toolMode: toolMode ?? this.toolMode,
      showGrid: showGrid ?? this.showGrid,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showColorCodes: showColorCodes ?? this.showColorCodes,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
      isDirty: isDirty ?? this.isDirty,
      hasEverBeenSaved: hasEverBeenSaved ?? this.hasEverBeenSaved,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      lastError: lastError ?? this.lastError,
      history: history ?? this.history,
      redoStack: redoStack ?? this.redoStack,
      recentColors: recentColors ?? this.recentColors,
      canvasTransform: canvasTransform ?? this.canvasTransform,
      maxHistorySize: maxHistorySize ?? this.maxHistorySize,
    );
  }

  int get width => currentDesign?.width ?? 0;
  int get height => currentDesign?.height ?? 0;
  bool get hasDesign => currentDesign != null;
  bool get canUndo => history.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  int get undoCount => history.length;
  int get redoCount => redoStack.length;
}
