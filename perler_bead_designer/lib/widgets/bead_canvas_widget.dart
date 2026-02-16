import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/design_editor_provider.dart';
import '../providers/app_provider.dart';

class BeadCanvasWidget extends StatefulWidget {
  final double minScale;
  final double maxScale;

  const BeadCanvasWidget({
    super.key,
    this.minScale = 0.25,
    this.maxScale = 4.0,
  });

  @override
  State<BeadCanvasWidget> createState() => _BeadCanvasWidgetState();
}

class _BeadCanvasWidgetState extends State<BeadCanvasWidget> {
  final TransformationController _transformController =
      TransformationController();
  bool _isDragging = false;
  int? _lastX;
  int? _lastY;
  bool _isPanning = false;
  Offset? _lastPanPosition;
  OverlayEntry? _colorInfoOverlay;
  CanvasTransform? _lastTransform;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTransformFromProvider();
    });
  }

  void _syncTransformFromProvider() {
    final provider = context.read<DesignEditorProvider>();
    final transform = provider.canvasTransform;

    if (_lastTransform == transform) return;
    _lastTransform = transform;

    final safeScale = transform.scale.clamp(0.25, 4.0);
    if (safeScale <= 0) return;

    final matrix = Matrix4.identity();
    matrix.scale(safeScale);
    matrix.translate(transform.offset.dx, transform.offset.dy);
    _transformController.value = matrix;
  }

  @override
  void dispose() {
    _removeColorInfoOverlay();
    _transformController.dispose();
    super.dispose();
  }

  void _handlePanStart(
    DragStartDetails details,
    DesignEditorProvider provider,
    AppProvider appProvider,
  ) {
    if (provider.currentDesign == null) return;
    if (provider.isPreviewMode) return;

    provider.startBatchDrawing();
    final position = _getPositionFromOffset(
      details.localPosition,
      provider,
      appProvider,
    );
    if (position != null) {
      _lastX = position.$1;
      _lastY = position.$2;
      _isDragging = true;
      provider.setBead(position.$1, position.$2);
    }
  }

  void _handlePanUpdate(
    DragUpdateDetails details,
    DesignEditorProvider provider,
    AppProvider appProvider,
  ) {
    if (provider.currentDesign == null) return;
    if (provider.isPreviewMode) return;

    final position = _getPositionFromOffset(
      details.localPosition,
      provider,
      appProvider,
    );
    if (position != null && _isDragging) {
      final x = position.$1;
      final y = position.$2;

      if (x != _lastX || y != _lastY) {
        _lastX = x;
        _lastY = y;
        provider.setBead(x, y);
      }
    }
  }

  void _handlePanEnd(DragEndDetails details, DesignEditorProvider provider) {
    provider.endBatchDrawing();
    _isDragging = false;
    _lastX = null;
    _lastY = null;
  }

  (int, int)? _getPositionFromOffset(
    Offset localPosition,
    DesignEditorProvider provider,
    AppProvider appProvider,
  ) {
    final design = provider.currentDesign;
    if (design == null) return null;

    final transform = _transformController.value;
    final scale = transform.getMaxScaleOnAxis();
    if (scale <= 0) return null;

    Matrix4 invertedTransform;
    try {
      invertedTransform = Matrix4.inverted(transform);
    } catch (e) {
      return null;
    }

    final transformedPoint = MatrixUtils.transformPoint(
      invertedTransform,
      localPosition,
    );

    final cellSize = appProvider.cellSize;
    final x = (transformedPoint.dx / cellSize).floor();
    final y = (transformedPoint.dy / cellSize).floor();

    if (x >= 0 && x < design.width && y >= 0 && y < design.height) {
      return (x, y);
    }
    return null;
  }

  void _removeColorInfoOverlay() {
    _colorInfoOverlay?.remove();
    _colorInfoOverlay = null;
  }

  void _showColorInfo(BeadColor bead, Offset position, BuildContext context) {
    _removeColorInfoOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final globalPosition = renderBox.localToGlobal(position);

    _colorInfoOverlay = OverlayEntry(
      builder: (overlayContext) => Positioned(
        left: globalPosition.dx + 10,
        top: globalPosition.dy + 10,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(overlayContext).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(overlayContext).colorScheme.outline,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: bead.color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bead.name,
                          style: Theme.of(overlayContext).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '代码: ${bead.code}',
                          style: Theme.of(overlayContext).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _buildColorInfoRow(overlayContext, 'HEX', bead.hex),
                _buildColorInfoRow(
                  overlayContext,
                  'RGB',
                  'R:${bead.red} G:${bead.green} B:${bead.blue}',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_colorInfoOverlay!);

    Future.delayed(const Duration(seconds: 3), () {
      _removeColorInfoOverlay();
    });
  }

  Widget _buildColorInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _onPointerDown(
    PointerDownEvent event,
    DesignEditorProvider provider,
    AppProvider appProvider,
  ) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (event.buttons == 1) {
        final position = _getPositionFromOffset(
          event.localPosition,
          provider,
          appProvider,
        );
        if (position != null) {
          if (provider.isPreviewMode) {
            final design = provider.currentDesign;
            if (design != null) {
              final bead = design.getBead(position.$1, position.$2);
              if (bead != null) {
                _showColorInfo(bead, event.localPosition, context);
              }
            }
          } else if (provider.toolMode == ToolMode.select) {
            if (provider.hasSelection &&
                provider.currentSelection!.contains(position.$1, position.$2)) {
              provider.startDraggingSelection(position.$1, position.$2);
            } else {
              provider.clearSelection();
              provider.startSelection(position.$1, position.$2);
              _isSelecting = true;
            }
          } else {
            provider.startBatchDrawing();
            provider.setBead(position.$1, position.$2);
            _lastX = position.$1;
            _lastY = position.$2;
            _isDragging = true;
          }
        }
      } else if (event.buttons == 4) {
        _isPanning = true;
        _lastPanPosition = event.localPosition;
      }
    }
  }

  void _onPointerMove(
    PointerMoveEvent event,
    DesignEditorProvider provider,
    AppProvider appProvider,
  ) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (_isDragging && event.buttons == 1 && !provider.isPreviewMode) {
        final position = _getPositionFromOffset(
          event.localPosition,
          provider,
          appProvider,
        );
        if (position != null) {
          if (position.$1 != _lastX || position.$2 != _lastY) {
            _lastX = position.$1;
            _lastY = position.$2;
            provider.setBead(position.$1, position.$2);
          }
        }
      } else if (_isSelecting && event.buttons == 1) {
        final position = _getPositionFromOffset(
          event.localPosition,
          provider,
          appProvider,
        );
        if (position != null) {
          provider.updateSelection(position.$1, position.$2);
        }
      } else if (provider.isDraggingSelection && event.buttons == 1) {
        final position = _getPositionFromOffset(
          event.localPosition,
          provider,
          appProvider,
        );
        if (position != null) {
          provider.dragSelection(position.$1, position.$2);
        }
      } else if (_isPanning && event.buttons == 4) {
        if (_lastPanPosition != null) {
          final delta = event.localPosition - _lastPanPosition!;
          _lastPanPosition = event.localPosition;
          provider.moveCanvas(delta.dx, delta.dy);
          _syncTransformFromProvider();
        }
      }
    }
  }

  void _onPointerUp(PointerEvent event, DesignEditorProvider provider) {
    if (_isDragging) {
      provider.endBatchDrawing();
    }
    if (_isSelecting) {
      provider.endSelection();
      _isSelecting = false;
    }
    if (provider.isDraggingSelection) {
      provider.endDraggingSelection();
    }
    _isDragging = false;
    _lastX = null;
    _lastY = null;
    _isPanning = false;
    _lastPanPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DesignEditorProvider, AppProvider>(
      builder: (context, provider, appProvider, child) {
        _syncTransformFromProvider();

        final design = provider.currentDesign;

        if (design == null) {
          return const Center(child: Text('请创建或加载一个设计'));
        }

        final cellSize = appProvider.cellSize;
        final canvasWidth = design.width * cellSize;
        final canvasHeight = design.height * cellSize;
        final isPreviewMode = provider.isPreviewMode;

        return Listener(
          onPointerDown: (event) =>
              _onPointerDown(event, provider, appProvider),
          onPointerMove: (event) =>
              _onPointerMove(event, provider, appProvider),
          onPointerUp: (event) => _onPointerUp(event, provider),
          onPointerCancel: (event) => _onPointerUp(event, provider),
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent && !_isDragging) {
              final delta = signal.scrollDelta.dy;
              if (delta != 0 && provider.currentDesign != null) {
                final scaleDelta = delta > 0 ? -0.1 : 0.1;

                final position = signal.localPosition;
                provider.zoomCanvas(scaleDelta, focalPoint: position);
                _syncTransformFromProvider();
              }
            }
          },
          child: GestureDetector(
            onPanStart: (details) =>
                _handlePanStart(details, provider, appProvider),
            onPanUpdate: (details) =>
                _handlePanUpdate(details, provider, appProvider),
            onPanEnd: (details) => _handlePanEnd(details, provider),
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              constrained: false,
              clipBehavior: Clip.hardEdge,
              panEnabled: false,
              scaleEnabled: false,
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: CustomPaint(
                  painter: BeadCanvasPainter(
                    design: design,
                    cellSize: cellSize,
                    showGrid: provider.showGrid,
                    showCoordinates: provider.showCoordinates,
                    showColorCodes: provider.showColorCodes,
                    selectedTool: provider.toolMode,
                    show3DEffect: appProvider.showBead3DEffect,
                    isPreviewMode: isPreviewMode,
                    gridColor: appProvider.gridColor,
                    coordinateFontSize: appProvider.effectiveCoordinateFontSize,
                    selection: provider.currentSelection,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BeadCanvasPainter extends CustomPainter {
  final BeadDesign design;
  final double cellSize;
  final bool showGrid;
  final bool showCoordinates;
  final bool showColorCodes;
  final ToolMode selectedTool;
  final bool show3DEffect;
  final bool isPreviewMode;
  final String gridColor;
  final double coordinateFontSize;
  final Selection? selection;

  late final Paint _backgroundPaint;
  late final Paint _whitePaint;
  late final Paint _gridPaint;
  late final Paint _majorGridPaint;
  late final Paint _highlightPaint;
  late final Paint _shadowPaint;
  late final Paint _selectionPaint;
  late final Paint _selectionFillPaint;

  BeadCanvasPainter({
    required this.design,
    required this.cellSize,
    required this.showGrid,
    required this.showCoordinates,
    required this.showColorCodes,
    required this.selectedTool,
    required this.show3DEffect,
    this.isPreviewMode = false,
    this.gridColor = '#9E9E9E',
    this.coordinateFontSize = 7.0,
    this.selection,
  }) {
    _backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    _whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    _gridPaint = Paint()
      ..color = _parseColor(gridColor)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    _majorGridPaint = Paint()
      ..color = _parseColor(gridColor).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    _shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    _selectionPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    _selectionFillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey.shade400;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawBeads(canvas);
    if (showGrid && !isPreviewMode) {
      _drawGrid(canvas, size);
    }
    if (showCoordinates && cellSize >= 12 && !isPreviewMode) {
      _drawCoordinates(canvas);
    }
    if (showColorCodes && cellSize >= 15) {
      _drawColorCodes(canvas);
    }
    if (selection != null && !isPreviewMode) {
      _drawSelection(canvas);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);
  }

  void _drawBeads(Canvas canvas) {
    final beadPaint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final bead = design.getBead(x, y);
        final rect = Rect.fromLTWH(
          x * cellSize,
          y * cellSize,
          cellSize,
          cellSize,
        );

        if (bead != null) {
          beadPaint.color = bead.color;
          canvas.drawRect(rect, beadPaint);

          if (show3DEffect) {
            canvas.drawRect(
              Rect.fromLTWH(
                rect.left,
                rect.top,
                rect.width * 0.4,
                rect.height * 0.4,
              ),
              _highlightPaint,
            );

            canvas.drawRect(
              Rect.fromLTWH(
                rect.left + rect.width * 0.6,
                rect.top + rect.height * 0.6,
                rect.width * 0.4,
                rect.height * 0.4,
              ),
              _shadowPaint,
            );
          }
        } else {
          canvas.drawRect(rect, _whitePaint);
        }
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    for (int x = 0; x <= design.width; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, design.height * cellSize),
        _gridPaint,
      );
    }

    for (int y = 0; y <= design.height; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(design.width * cellSize, y * cellSize),
        _gridPaint,
      );
    }

    for (int x = 0; x <= design.width; x += 10) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, design.height * cellSize),
        _majorGridPaint,
      );
    }

    for (int y = 0; y <= design.height; y += 10) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(design.width * cellSize, y * cellSize),
        _majorGridPaint,
      );
    }
  }

  void _drawCoordinates(Canvas canvas) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final coordinateBgPaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..style = PaintingStyle.fill;

    final coordinateBgPaintAlt = Paint()
      ..color = const Color(0xFF1976D2)
      ..style = PaintingStyle.fill;

    final padding = cellSize * 0.08;
    final coordinateWidth = cellSize - padding * 2;
    final coordinateHeight = cellSize * 0.55;
    final topOffset = padding;

    for (int x = 0; x < design.width; x++) {
      final isAlt = x % 2 == 0;
      final bgRect = Rect.fromLTWH(
        x * cellSize + padding,
        topOffset,
        coordinateWidth,
        coordinateHeight,
      );

      final rrect = RRect.fromRectAndRadius(
        bgRect,
        Radius.circular(cellSize * 0.08),
      );
      canvas.drawRRect(rrect, isAlt ? coordinateBgPaint : coordinateBgPaintAlt);

      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: coordinateFontSize,
        fontWeight: FontWeight.bold,
        height: 1.0,
      );
      textPainter.text = TextSpan(text: x.toString(), style: textStyle);
      textPainter.layout();

      final textX = x * cellSize + cellSize / 2 - textPainter.width / 2;
      final textY = topOffset + (coordinateHeight - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(textX, textY));
    }

    for (int y = 0; y < design.height; y++) {
      final isAlt = y % 2 == 0;
      final bgRect = Rect.fromLTWH(
        padding,
        y * cellSize + padding,
        coordinateHeight,
        coordinateWidth,
      );

      final rrect = RRect.fromRectAndRadius(
        bgRect,
        Radius.circular(cellSize * 0.08),
      );
      canvas.drawRRect(rrect, isAlt ? coordinateBgPaint : coordinateBgPaintAlt);

      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: coordinateFontSize,
        fontWeight: FontWeight.bold,
        height: 1.0,
      );
      textPainter.text = TextSpan(text: y.toString(), style: textStyle);
      textPainter.layout();

      final textX = padding + (coordinateHeight - textPainter.width) / 2;
      final textY = y * cellSize + cellSize / 2 - textPainter.height / 2;
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  void _drawColorCodes(Canvas canvas) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final bead = design.getBead(x, y);
        if (bead == null) continue;

        final code = bead.code;
        final padding = cellSize * 0.1;
        final availableWidth = cellSize - padding * 2;
        final availableHeight = cellSize - padding * 2;

        double fontSize = cellSize * 0.45;
        if (code.length > 2) {
          fontSize = fontSize * 2.5 / code.length;
        }
        fontSize = fontSize.clamp(5.0, cellSize * 0.5);

        final textColor = _getContrastTextColor(bead.color);
        final outlineColor = _getOutlineColor(bead.color);

        final textStyle = TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          height: 1.0,
          letterSpacing: 0.5,
          shadows: [
            Shadow(
              color: outlineColor,
              offset: const Offset(0.5, 0.5),
              blurRadius: 0.5,
            ),
            Shadow(
              color: outlineColor,
              offset: const Offset(-0.5, -0.5),
              blurRadius: 0.5,
            ),
            Shadow(
              color: outlineColor,
              offset: const Offset(0.5, -0.5),
              blurRadius: 0.5,
            ),
            Shadow(
              color: outlineColor,
              offset: const Offset(-0.5, 0.5),
              blurRadius: 0.5,
            ),
          ],
        );

        textPainter.text = TextSpan(text: code, style: textStyle);
        textPainter.layout();

        final textWidth = textPainter.width;
        final textHeight = textPainter.height;

        if (textWidth > availableWidth || textHeight > availableHeight) {
          final scaleX = availableWidth / textWidth;
          final scaleY = availableHeight / textHeight;
          final scale = scaleX < scaleY ? scaleX : scaleY;
          fontSize = fontSize * scale;

          final adjustedStyle = textStyle.copyWith(fontSize: fontSize);
          textPainter.text = TextSpan(text: code, style: adjustedStyle);
          textPainter.layout();
        }

        final cellCenterX = x * cellSize + cellSize / 2;
        final cellCenterY = y * cellSize + cellSize / 2;
        final textX = cellCenterX - textPainter.width / 2;
        final textY = cellCenterY - textPainter.height / 2;

        textPainter.paint(canvas, Offset(textX, textY));
      }
    }
  }

  Color _getContrastTextColor(Color backgroundColor) {
    final r = (backgroundColor.r * 255.0).round().clamp(0, 255);
    final g = (backgroundColor.g * 255.0).round().clamp(0, 255);
    final b = (backgroundColor.b * 255.0).round().clamp(0, 255);
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

    if (luminance > 0.5) {
      return const Color(0xFF1A1A1A);
    } else {
      return const Color(0xFFFFFFFF);
    }
  }

  Color _getOutlineColor(Color backgroundColor) {
    final r = (backgroundColor.r * 255.0).round().clamp(0, 255);
    final g = (backgroundColor.g * 255.0).round().clamp(0, 255);
    final b = (backgroundColor.b * 255.0).round().clamp(0, 255);
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

    if (luminance > 0.5) {
      return Colors.white.withValues(alpha: 0.4);
    } else {
      return Colors.black.withValues(alpha: 0.4);
    }
  }

  void _drawSelection(Canvas canvas) {
    if (selection == null) return;

    final normalized = selection!.normalized();
    final rect = Rect.fromLTWH(
      normalized.left * cellSize,
      normalized.top * cellSize,
      normalized.width * cellSize,
      normalized.height * cellSize,
    );

    canvas.drawRect(rect, _selectionFillPaint);
    canvas.drawRect(rect, _selectionPaint);

    final dashSize = 5.0;
    final gapSize = 5.0;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawDashedLine(
      canvas,
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      dashSize,
      gapSize,
      paint,
    );
    _drawDashedLine(
      canvas,
      Offset(rect.left, rect.bottom),
      Offset(rect.right, rect.bottom),
      dashSize,
      gapSize,
      paint,
    );
    _drawDashedLine(
      canvas,
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.bottom),
      dashSize,
      gapSize,
      paint,
    );
    _drawDashedLine(
      canvas,
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.bottom),
      dashSize,
      gapSize,
      paint,
    );

    final handleSize = 8.0;
    final handles = [
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.left, rect.bottom),
      Offset(rect.right, rect.bottom),
    ];

    for (final handle in handles) {
      canvas.drawRect(
        Rect.fromCenter(center: handle, width: handleSize, height: handleSize),
        Paint()..color = Colors.blue,
      );
      canvas.drawRect(
        Rect.fromCenter(center: handle, width: handleSize, height: handleSize),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    double dashSize,
    double gapSize,
    Paint paint,
  ) {
    final totalDistance = (end - start).distance;
    if (totalDistance == 0) return;

    final direction = (end - start) / totalDistance;
    var currentDistance = 0.0;

    while (currentDistance < totalDistance) {
      final dashStart = start + direction * currentDistance;
      final dashEndDistance = currentDistance + dashSize;
      final actualDashEndDistance = dashEndDistance > totalDistance
          ? totalDistance
          : dashEndDistance;
      final dashEnd = start + direction * actualDashEndDistance;

      canvas.drawLine(dashStart, dashEnd, paint);
      currentDistance += dashSize + gapSize;
    }
  }

  @override
  bool shouldRepaint(covariant BeadCanvasPainter oldDelegate) {
    return !identical(oldDelegate.design, design) ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showCoordinates != showCoordinates ||
        oldDelegate.showColorCodes != showColorCodes ||
        oldDelegate.selectedTool != selectedTool ||
        oldDelegate.show3DEffect != show3DEffect ||
        oldDelegate.isPreviewMode != isPreviewMode ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.coordinateFontSize != coordinateFontSize ||
        oldDelegate.selection != selection;
  }
}
