
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double life;
  double maxLife;
  double rotation;
  double rotationSpeed;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
    required this.maxLife,
    this.rotation = 0,
    this.rotationSpeed = 0,
  });

  bool get isAlive => life > 0;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += 200 * dt;
    life -= dt;
    rotation += rotationSpeed * dt;
  }
}

class GpuAnimationService extends ChangeNotifier {
  static final GpuAnimationService _instance = GpuAnimationService._internal();
  factory GpuAnimationService() => _instance;
  GpuAnimationService._internal();

  final List<Particle> _particles = [];
  bool _isEnabled = true;
  bool _isInitialized = false;
  late final Ticker _ticker;
  Duration? _lastFrameTime;
  final List<VoidCallback> _frameCallbacks = [];

  bool get isEnabled => _isEnabled;
  List<Particle> get particles => List.unmodifiable(_particles);
  int get particleCount => _particles.length;

  void initialize() {
    if (_isInitialized) return;
    _ticker = Ticker(_onTick);
    _isInitialized = true;
  }

  void _onTick(Duration elapsed) {
    if (_lastFrameTime == null) {
      _lastFrameTime = elapsed;
      return;
    }

    final dt = (elapsed - _lastFrameTime!).inMicroseconds / 1000000.0;
    _lastFrameTime = elapsed;

    _updateParticles(dt);

    for (final callback in _frameCallbacks) {
      callback();
    }
  }

  void _updateParticles(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i].update(dt);
      if (!_particles[i].isAlive) {
        _particles.removeAt(i);
      }
    }
  }

  void setEnabled(bool enabled) {
    if (_isEnabled == enabled) return;
    _isEnabled = enabled;
    if (!enabled) {
      _particles.clear();
    }
    notifyListeners();
  }

  void startAnimation() {
    if (!_isInitialized) initialize();
    if (!_ticker.isActive) {
      _ticker.start();
      _lastFrameTime = null;
    }
  }

  void stopAnimation() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _particles.clear();
  }

  void addFrameCallback(VoidCallback callback) {
    _frameCallbacks.add(callback);
  }

  void removeFrameCallback(VoidCallback callback) {
    _frameCallbacks.remove(callback);
  }

  void emitCompletionParticles({
    required Offset position,
    required Color color,
    int count = 30,
    double spread = 100,
  }) {
    if (!_isEnabled) return;

    final random = math.Random();
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final speed = random.nextDouble() * spread + 50;
      final vx = math.cos(angle) * speed;
      final vy = math.sin(angle) * speed - 100;

      _particles.add(Particle(
        x: position.dx,
        y: position.dy,
        vx: vx,
        vy: vy,
        size: random.nextDouble() * 8 + 4,
        color: _varyColor(color, random),
        life: random.nextDouble() * 0.5 + 0.5,
        maxLife: 1.0,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 10,
      ));
    }

    startAnimation();
    notifyListeners();
  }

  void emitBeadPlacedParticles({
    required Offset position,
    required Color color,
    int count = 8,
  }) {
    if (!_isEnabled) return;

    final random = math.Random();
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final speed = random.nextDouble() * 30 + 10;

      _particles.add(Particle(
        x: position.dx,
        y: position.dy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 20,
        size: random.nextDouble() * 4 + 2,
        color: _varyColor(color, random),
        life: random.nextDouble() * 0.3 + 0.2,
        maxLife: 0.5,
      ));
    }

    startAnimation();
    notifyListeners();
  }

  void emitSuccessParticles({
    required Rect bounds,
    required List<Color> colors,
    int countPerColor = 10,
  }) {
    if (!_isEnabled) return;

    final random = math.Random();
    for (final color in colors) {
      for (int i = 0; i < countPerColor; i++) {
        final x = bounds.left + random.nextDouble() * bounds.width;
        final y = bounds.bottom;
        final angle = -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi / 3;
        final speed = random.nextDouble() * 200 + 150;

        _particles.add(Particle(
          x: x,
          y: y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: random.nextDouble() * 10 + 5,
          color: _varyColor(color, random),
          life: random.nextDouble() * 1.0 + 0.5,
          maxLife: 1.5,
          rotation: random.nextDouble() * math.pi * 2,
          rotationSpeed: (random.nextDouble() - 0.5) * 8,
        ));
      }
    }

    startAnimation();
    notifyListeners();
  }

  void emitExplosionParticles({
    required Offset center,
    required Color color,
    int count = 50,
    double radius = 150,
  }) {
    if (!_isEnabled) return;

    final random = math.Random();
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2;
      final speed = random.nextDouble() * radius + radius / 2;

      _particles.add(Particle(
        x: center.dx,
        y: center.dy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        size: random.nextDouble() * 12 + 6,
        color: _varyColor(color, random),
        life: random.nextDouble() * 0.8 + 0.4,
        maxLife: 1.2,
        rotation: angle,
        rotationSpeed: (random.nextDouble() - 0.5) * 6,
      ));
    }

    startAnimation();
    notifyListeners();
  }

  Color _varyColor(Color baseColor, math.Random random) {
    final variation = random.nextInt(30) - 15;
    return Color.fromARGB(
      (baseColor.a * 255.0).round().clamp(0, 255),
      ((baseColor.r * 255.0).round() + variation).clamp(0, 255),
      ((baseColor.g * 255.0).round() + variation).clamp(0, 255),
      ((baseColor.b * 255.0).round() + variation).clamp(0, 255),
    );
  }

  void clearParticles() {
    _particles.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopAnimation();
    _ticker.dispose();
    super.dispose();
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final bool show3DEffect;

  ParticlePainter({
    required this.particles,
    this.show3DEffect = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final alpha = (particle.life / particle.maxLife).clamp(0.0, 1.0);
      final color = particle.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);

      if (show3DEffect) {
        _draw3DParticle(canvas, particle, color);
      } else {
        _drawFlatParticle(canvas, particle, color);
      }

      canvas.restore();
    }
  }

  void _draw3DParticle(Canvas canvas, Particle particle, Color color) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: particle.size,
      height: particle.size,
    );

    final paint = Paint()..color = color;
    canvas.drawRect(rect, paint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3);
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
      ..color = Colors.black.withValues(alpha: 0.2);
    canvas.drawRect(
      Rect.fromLTWH(
        rect.left + rect.width * 0.6,
        rect.top + rect.height * 0.6,
        rect.width * 0.4,
        rect.height * 0.4,
      ),
      shadowPaint,
    );
  }

  void _drawFlatParticle(Canvas canvas, Particle particle, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(
      Offset.zero,
      particle.size / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return particles.length != oldDelegate.particles.length ||
        particles.isNotEmpty;
  }
}

class ParticleOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const ParticleOverlay({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  final GpuAnimationService _animationService = GpuAnimationService();
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _animationService.initialize();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animationService.addFrameCallback(_onFrame);
  }

  void _onFrame() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _animationService.removeFrameCallback(_onFrame);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled && _animationService.particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ParticlePainter(
                  particles: _animationService.particles,
                  show3DEffect: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AnimatedTransitionService {
  static final AnimatedTransitionService _instance =
      AnimatedTransitionService._internal();
  factory AnimatedTransitionService() => _instance;
  AnimatedTransitionService._internal();

  bool _transitionsEnabled = true;

  bool get transitionsEnabled => _transitionsEnabled;

  void setTransitionsEnabled(bool enabled) {
    _transitionsEnabled = enabled;
  }

  Animation<double> createFadeAnimation(
    AnimationController controller, {
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }

  Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0.1, 0.0),
    Curve curve = Curves.easeOutCubic,
  }) {
    return Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }

  Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = 0.8,
    Curve curve = Curves.easeOutBack,
  }) {
    return Tween<double>(begin: begin, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
  }
}

class ButtonClickFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? rippleColor;

  const ButtonClickFeedback({
    super.key,
    required this.child,
    this.onPressed,
    this.rippleColor,
  });

  @override
  State<ButtonClickFeedback> createState() => _ButtonClickFeedbackState();
}

class _ButtonClickFeedbackState extends State<ButtonClickFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class CompletionEffectWidget extends StatefulWidget {
  final Widget child;
  final bool showEffect;
  final Color effectColor;
  final VoidCallback? onComplete;

  const CompletionEffectWidget({
    super.key,
    required this.child,
    this.showEffect = false,
    this.effectColor = Colors.green,
    this.onComplete,
  });

  @override
  State<CompletionEffectWidget> createState() => _CompletionEffectWidgetState();
}

class _CompletionEffectWidgetState extends State<CompletionEffectWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  final GpuAnimationService _animationService = GpuAnimationService();

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(CompletionEffectWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showEffect && !oldWidget.showEffect) {
      _triggerEffect();
    }
  }

  void _triggerEffect() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    _glowController.forward().then((_) {
      _glowController.reset();
      widget.onComplete?.call();
    });

    if (_animationService.isEnabled) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        _animationService.emitCompletionParticles(
          position: Offset(
            position.dx + size.width / 2,
            position.dy + size.height / 2,
          ),
          color: widget.effectColor,
        );
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: _glowAnimation.value > 0
                ? [
                    BoxShadow(
                      color: widget.effectColor
                          .withValues(alpha: _glowAnimation.value * 0.5),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 5 * _glowAnimation.value,
                    ),
                  ]
                : null,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
