import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/design_editor_provider.dart';
import '../providers/app_provider.dart';

class BeadCanvasWidget extends StatefulWidget {
  final double cellSize;
  final double minScale;
  final double maxScale;

  const BeadCanvasWidget({
    super.key,
    this.cellSize = 20.0,
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
    final matrix = Matrix4.identity();
    matrix.translate(transform.offset.dx, transform.offset.dy);
    matrix.scale(transform.scale);
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
  ) {
    if (provider.currentDesign == null) return;
    if (provider.isPreviewMode) return;

    provider.startBatchDrawing();
    final position = _getPositionFromOffset(details.localPosition, provider);
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
  ) {
    if (provider.currentDesign == null) return;
    if (provider.isPreviewMode) return;

    final position = _getPositionFromOffset(details.localPosition, provider);
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
  ) {
    final design = provider.currentDesign;
    if (design == null) return null;

    final transform = _transformController.value;
    final invertedTransform = Matrix4.inverted(transform);
    final transformedPoint = MatrixUtils.transformPoint(
      invertedTransform,
      localPosition,
    );

    final cellSize = widget.cellSize;
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
                          style: Theme.of(overlayContext).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                _buildColorInfoRow(overlayContext, 'RGB', 'R:${bead.red} G:${bead.green} B:${bead.blue}'),
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
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event, DesignEditorProvider provider) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (event.buttons == 1) {
        final position = _getPositionFromOffset(
          event.localPosition,
          provider,
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

  void _onPointerMove(PointerMoveEvent event, DesignEditorProvider provider) {
    if (event.kind == PointerDeviceKind.mouse) {
      if (_isDragging && event.buttons == 1 && !provider.isPreviewMode) {
        final position = _getPositionFromOffset(
          event.localPosition,
          provider,
        );
        if (position != null) {
          if (position.$1 != _lastX || position.$2 != _lastY) {
            _lastX = position.$1;
            _lastY = position.$2;
            provider.setBead(position.$1, position.$2);
          }
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
        final design = provider.currentDesign;

        if (design == null) {
          return const Center(child: Text('请创建或加载一个设计'));
        }

        final canvasWidth = design.width * widget.cellSize;
        final canvasHeight = design.height * widget.cellSize;
        final isPreviewMode = provider.isPreviewMode;

        return Listener(
          onPointerDown: (event) => _onPointerDown(event, provider),
          onPointerMove: (event) => _onPointerMove(event, provider),
          onPointerUp: (event) => _onPointerUp(event, provider),
          onPointerCancel: (event) => _onPointerUp(event, provider),
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent && !_isDragging) {
              final delta = signal.scrollDelta.dy;
              if (delta != 0) {
                final scaleDelta = delta > 0 ? -0.1 : 0.1;

                final position = signal.localPosition;
                provider.zoomCanvas(scaleDelta, focalPoint: position);
                _syncTransformFromProvider();
              }
            }
          },
          child: GestureDetector(
            onPanStart: (details) => _handlePanStart(details, provider),
            onPanUpdate: (details) => _handlePanUpdate(details, provider),
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
                    cellSize: widget.cellSize,
                    showGrid: provider.showGrid,
                    showCoordinates: provider.showCoordinates,
                    showColorCodes: provider.showColorCodes,
                    selectedTool: provider.toolMode,
                    show3DEffect: appProvider.showBead3DEffect,
                    isPreviewMode: isPreviewMode,
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

  late final Paint _backgroundPaint;
  late final Paint _whitePaint;
  late final Paint _gridPaint;
  late final Paint _majorGridPaint;
  late final Paint _highlightPaint;
  late final Paint _shadowPaint;

  BeadCanvasPainter({
    required this.design,
    required this.cellSize,
    required this.showGrid,
    required this.showCoordinates,
    required this.showColorCodes,
    required this.selectedTool,
    required this.show3DEffect,
    this.isPreviewMode = false,
  }) {
    _backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    _whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    _gridPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    _majorGridPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    _shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
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
    if (showColorCodes && cellSize >= 18) {
      _drawColorCodes(canvas);
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

    final textStyle = TextStyle(
      color: Colors.grey.shade700,
      fontSize: cellSize * 0.35,
      fontWeight: FontWeight.w500,
    );

    for (int x = 0; x < design.width; x += 5) {
      textPainter.text = TextSpan(text: x.toString(), style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x * cellSize + cellSize / 2 - textPainter.width / 2,
          cellSize * 0.1,
        ),
      );
    }

    for (int y = 5; y < design.height; y += 5) {
      textPainter.text = TextSpan(text: y.toString(), style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          cellSize * 0.1,
          y * cellSize + cellSize / 2 - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawColorCodes(Canvas canvas) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final fontSize = cellSize * 0.35;

    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final bead = design.getBead(x, y);
        if (bead == null) continue;

        final textColor = bead.isLight ? Colors.black87 : Colors.white;
        final textStyle = TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        );

        textPainter.text = TextSpan(text: bead.code, style: textStyle);
        textPainter.layout();

        final centerX = x * cellSize + cellSize / 2 - textPainter.width / 2;
        final centerY = y * cellSize + cellSize / 2 - textPainter.height / 2;

        textPainter.paint(canvas, Offset(centerX, centerY));
      }
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
        oldDelegate.isPreviewMode != isPreviewMode;
  }
}
