import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/assembly_guide_service.dart';

class AssemblyGuideWidget extends StatefulWidget {
  final BeadDesign design;
  final double cellSize;
  final AssemblyStep? currentStep;
  final VoidCallback? onNextStep;
  final VoidCallback? onPreviousStep;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onReset;
  final bool isPlaying;
  final double animationSpeed;
  final Function(double)? onSpeedChanged;
  final bool showSameColorHint;

  const AssemblyGuideWidget({
    super.key,
    required this.design,
    required this.cellSize,
    this.currentStep,
    this.onNextStep,
    this.onPreviousStep,
    this.onPlay,
    this.onPause,
    this.onReset,
    this.isPlaying = false,
    this.animationSpeed = 1.0,
    this.onSpeedChanged,
    this.showSameColorHint = true,
  });

  @override
  State<AssemblyGuideWidget> createState() => _AssemblyGuideWidgetState();
}

class _AssemblyGuideWidgetState extends State<AssemblyGuideWidget>
    with TickerProviderStateMixin {
  late AnimationController _fallAnimationController;
  late AnimationController _glowAnimationController;
  late Animation<double> _fallAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _fallAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _glowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _fallAnimation = CurvedAnimation(
      parent: _fallAnimationController,
      curve: Curves.bounceOut,
    );
    _glowAnimation = CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(AssemblyGuideWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStep != oldWidget.currentStep &&
        widget.currentStep != null) {
      _fallAnimationController.reset();
      _fallAnimationController.forward();
    }
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _fallAnimationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _fallAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: widget.design.width * widget.cellSize,
                    height: widget.design.height * widget.cellSize,
                    child: CustomPaint(
                      painter: AssemblyCanvasPainter(
                        design: widget.design,
                        cellSize: widget.cellSize,
                        currentStep: widget.currentStep,
                        fallAnimation: _fallAnimation,
                        glowAnimation: _glowAnimation,
                        showSameColorHint: widget.showSameColorHint,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildControls(context),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressBar(context),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: widget.onPreviousStep,
                tooltip: '上一步',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.replay),
                onPressed: widget.onReset,
                tooltip: '重置',
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                heroTag: 'assembly_play',
                onPressed: widget.isPlaying ? widget.onPause : widget.onPlay,
                child: Icon(widget.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: widget.onNextStep,
                tooltip: '下一步',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSpeedSlider(context),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final currentStep = widget.currentStep;
    final progress = currentStep?.progress ?? 0.0;
    final stepIndex = currentStep?.stepIndex ?? -1;
    final totalSteps = currentStep?.totalSteps ?? 0;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '步骤: ${stepIndex + 1} / $totalSteps',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '进度: ${(progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedSlider(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.speed, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Slider(
            value: widget.animationSpeed,
            min: 0.25,
            max: 4.0,
            divisions: 15,
            label: '${widget.animationSpeed}x',
            onChanged: widget.onSpeedChanged,
          ),
        ),
        Text(
          '${widget.animationSpeed}x',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class AssemblyCanvasPainter extends CustomPainter {
  final BeadDesign design;
  final double cellSize;
  final AssemblyStep? currentStep;
  final Animation<double> fallAnimation;
  final Animation<double> glowAnimation;
  final bool showSameColorHint;

  late final Paint _backgroundPaint;
  late final Paint _whitePaint;
  late final Paint _placedPaint;
  late final Paint _highlightPaint;
  late final Paint _shadowPaint;
  late final Paint _glowPaint;
  late final Paint _sameColorHintPaint;

  AssemblyCanvasPainter({
    required this.design,
    required this.cellSize,
    this.currentStep,
    required this.fallAnimation,
    required this.glowAnimation,
    this.showSameColorHint = true,
  }) {
    _backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;

    _whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    _placedPaint = Paint()..style = PaintingStyle.fill;

    _highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    _shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    _glowPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    _sameColorHintPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawPlacedBeads(canvas);
    _drawSameColorHints(canvas);
    _drawCurrentBead(canvas);
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final rect = Rect.fromLTWH(
          x * cellSize,
          y * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(rect, _whitePaint);
      }
    }
  }

  void _drawPlacedBeads(Canvas canvas) {
    if (currentStep == null) return;

    for (int i = 0; i <= currentStep!.stepIndex; i++) {
      final step = _getStepAtIndex(i);
      if (step == null) continue;

      final rect = Rect.fromLTWH(
        step.x * cellSize,
        step.y * cellSize,
        cellSize,
        cellSize,
      );

      _placedPaint.color = step.color.color;
      canvas.drawRect(rect, _placedPaint);

      _draw3DEffect(canvas, rect);
    }
  }

  AssemblyStep? _getStepAtIndex(int index) {
    int count = 0;
    for (int y = 0; y < design.height; y++) {
      for (int x = 0; x < design.width; x++) {
        final bead = design.getBead(x, y);
        if (bead != null) {
          if (count == index) {
            return AssemblyStep(
              x: x,
              y: y,
              color: bead,
              stepIndex: index,
              totalSteps: design.getTotalBeadCount(),
            );
          }
          count++;
        }
      }
    }
    return null;
  }

  void _drawSameColorHints(Canvas canvas) {
    if (!showSameColorHint || currentStep == null) return;

    for (final pos in currentStep!.sameColorPositions) {
      if (pos.x == currentStep!.x && pos.y == currentStep!.y) continue;

      final isPlaced = _isPositionPlaced(pos.x, pos.y);
      if (!isPlaced) {
        final rect = Rect.fromLTWH(
          pos.x * cellSize,
          pos.y * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(rect, _sameColorHintPaint);
      }
    }
  }

  bool _isPositionPlaced(int x, int y) {
    if (currentStep == null) return false;

    for (int i = 0; i <= currentStep!.stepIndex; i++) {
      final step = _getStepAtIndex(i);
      if (step != null && step.x == x && step.y == y) {
        return true;
      }
    }
    return false;
  }

  void _drawCurrentBead(Canvas canvas) {
    if (currentStep == null) return;

    final fallValue = fallAnimation.value;
    final glowValue = glowAnimation.value;

    final targetY = currentStep!.y * cellSize;
    final startY = -cellSize * 2;
    final currentY = startY + (targetY - startY) * fallValue;

    final rect = Rect.fromLTWH(
      currentStep!.x * cellSize,
      currentY,
      cellSize,
      cellSize,
    );

    _placedPaint.color = currentStep!.color.color;
    canvas.drawRect(rect, _placedPaint);

    _draw3DEffect(canvas, rect);

    if (fallValue >= 1.0) {
      final glowRect = rect.inflate(4 * glowValue);
      _glowPaint.color = currentStep!.color.color.withValues(
        alpha: 0.5 * glowValue,
      );
      canvas.drawRect(glowRect, _glowPaint);
    }

    if (fallValue < 1.0) {
      _drawShadow(canvas, rect, fallValue);
    }
  }

  void _draw3DEffect(Canvas canvas, Rect rect) {
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width * 0.4, rect.height * 0.4),
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

  void _drawShadow(Canvas canvas, Rect rect, double fallValue) {
    final shadowY = currentStep!.y * cellSize;
    final shadowRect = Rect.fromLTWH(
      currentStep!.x * cellSize,
      shadowY,
      cellSize,
      cellSize,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3 * (1 - fallValue))
      ..style = PaintingStyle.fill;

    canvas.drawRect(shadowRect, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant AssemblyCanvasPainter oldDelegate) {
    return currentStep != oldDelegate.currentStep ||
        fallAnimation.value != oldDelegate.fallAnimation.value ||
        glowAnimation.value != oldDelegate.glowAnimation.value ||
        showSameColorHint != oldDelegate.showSameColorHint;
  }
}

class Bead3DWidget extends StatelessWidget {
  final Color color;
  final double size;
  final bool show3DEffect;
  final double elevation;

  const Bead3DWidget({
    super.key,
    required this.color,
    this.size = 20,
    this.show3DEffect = true,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        boxShadow: show3DEffect
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  offset: Offset(-size * 0.1, -size * 0.1),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: Offset(size * 0.1, size * 0.1),
                  blurRadius: 0,
                ),
                if (elevation > 0)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: Offset(0, elevation),
                    blurRadius: elevation * 2,
                  ),
              ]
            : null,
      ),
    );
  }
}

class FallingBeadAnimation extends StatefulWidget {
  final Color color;
  final double size;
  final Offset startPosition;
  final Offset endPosition;
  final Duration duration;
  final VoidCallback? onComplete;
  final bool show3DEffect;

  const FallingBeadAnimation({
    super.key,
    required this.color,
    required this.size,
    required this.startPosition,
    required this.endPosition,
    this.duration = const Duration(milliseconds: 500),
    this.onComplete,
    this.show3DEffect = true,
  });

  @override
  State<FallingBeadAnimation> createState() => _FallingBeadAnimationState();
}

class _FallingBeadAnimationState extends State<FallingBeadAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _bounceAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _bounceAnimation.value;
        final x =
            widget.startPosition.dx +
            (widget.endPosition.dx - widget.startPosition.dx) * progress;
        final y =
            widget.startPosition.dy +
            (widget.endPosition.dy - widget.startPosition.dy) * progress;

        return Positioned(
          left: x,
          top: y,
          child: Bead3DWidget(
            color: widget.color,
            size: widget.size,
            show3DEffect: widget.show3DEffect,
            elevation: 10 * (1 - progress),
          ),
        );
      },
    );
  }
}

class AssemblyProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final BeadColor? currentColor;

  const AssemblyProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps > 0 ? currentStep / totalSteps : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentColor != null) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: currentColor!.color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '步骤 $currentStep / $totalSteps',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
