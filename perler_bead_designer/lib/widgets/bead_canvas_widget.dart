import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/design_editor_provider.dart';

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

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _handlePanStart(
    DragStartDetails details,
    DesignEditorProvider provider,
  ) {
    if (provider.currentDesign == null) return;

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

  void _handlePanEnd(DragEndDetails details) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<DesignEditorProvider>(
      builder: (context, provider, child) {
        final design = provider.currentDesign;

        if (design == null) {
          return const Center(child: Text('请创建或加载一个设计'));
        }

        final canvasWidth = design.width * widget.cellSize;
        final canvasHeight = design.height * widget.cellSize;

        return Listener(
          onPointerDown: (event) {
            if (event.kind == PointerDeviceKind.mouse && event.buttons == 1) {
              final position = _getPositionFromOffset(
                event.localPosition,
                provider,
              );
              if (position != null) {
                provider.setBead(position.$1, position.$2);
                _lastX = position.$1;
                _lastY = position.$2;
                _isDragging = true;
              }
            }
          },
          onPointerMove: (event) {
            if (_isDragging &&
                event.kind == PointerDeviceKind.mouse &&
                event.buttons == 1) {
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
            }
          },
          onPointerUp: (event) {
            _isDragging = false;
            _lastX = null;
            _lastY = null;
          },
          onPointerSignal: (signal) {
            if (signal is PointerScrollEvent) {
              final delta = signal.scrollDelta.dy;
              if (delta != 0) {
                final currentScale = _transformController.value
                    .getMaxScaleOnAxis();
                final scaleDelta = delta > 0 ? 0.9 : 1.1;
                final newScale = (currentScale * scaleDelta).clamp(
                  widget.minScale,
                  widget.maxScale,
                );

                final position = signal.localPosition;
                final transform = _transformController.value;

                final newTransform = Matrix4.identity()
                  ..translate(position.dx, position.dy)
                  ..scale(newScale / currentScale)
                  ..translate(-position.dx, -position.dy)
                  ..multiply(transform);

                _transformController.value = newTransform;
              }
            }
          },
          child: GestureDetector(
            onPanStart: (details) => _handlePanStart(details, provider),
            onPanUpdate: (details) => _handlePanUpdate(details, provider),
            onPanEnd: _handlePanEnd,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: widget.minScale,
              maxScale: widget.maxScale,
              constrained: false,
              clipBehavior: Clip.hardEdge,
              panEnabled: true,
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
                    selectedTool: provider.toolMode,
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
  final ToolMode selectedTool;

  BeadCanvasPainter({
    required this.design,
    required this.cellSize,
    required this.showGrid,
    required this.showCoordinates,
    required this.selectedTool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawBeads(canvas);
    if (showGrid) {
      _drawGrid(canvas, size);
    }
    if (showCoordinates && cellSize >= 12) {
      _drawCoordinates(canvas);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _drawBeads(Canvas canvas) {
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
          final paint = Paint()
            ..color = bead.color
            ..style = PaintingStyle.fill;
          canvas.drawRect(rect, paint);

          final highlightPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;
          canvas.drawRect(
            Rect.fromLTWH(
              rect.left,
              rect.top,
              rect.width * 0.4,
              rect.height * 0.4,
            ),
            highlightPaint,
          );

          final shadowPaint = Paint()
            ..color = Colors.black.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill;
          canvas.drawRect(
            Rect.fromLTWH(
              rect.left + rect.width * 0.6,
              rect.top + rect.height * 0.6,
              rect.width * 0.4,
              rect.height * 0.4,
            ),
            shadowPaint,
          );
        } else {
          final paint = Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill;
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int x = 0; x <= design.width; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, design.height * cellSize),
        paint,
      );
    }

    for (int y = 0; y <= design.height; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(design.width * cellSize, y * cellSize),
        paint,
      );
    }

    final majorPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int x = 0; x <= design.width; x += 10) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, design.height * cellSize),
        majorPaint,
      );
    }

    for (int y = 0; y <= design.height; y += 10) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(design.width * cellSize, y * cellSize),
        majorPaint,
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
      fontSize: cellSize * 0.4,
    );

    for (int x = 0; x < design.width; x += 5) {
      textPainter.text = TextSpan(text: x.toString(), style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x * cellSize + cellSize / 2 - textPainter.width / 2,
          -textPainter.height - 2,
        ),
      );
    }

    for (int y = 0; y < design.height; y += 5) {
      textPainter.text = TextSpan(text: y.toString(), style: textStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          -textPainter.width - 2,
          y * cellSize + cellSize / 2 - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BeadCanvasPainter oldDelegate) {
    return oldDelegate.design != design ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showCoordinates != showCoordinates ||
        oldDelegate.selectedTool != selectedTool;
  }
}
