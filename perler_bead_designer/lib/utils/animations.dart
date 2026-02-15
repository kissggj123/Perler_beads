import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AnimationConfig {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
}

class CustomPageTransitionsBuilder extends PageTransitionsBuilder {
  const CustomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideTween = Tween<Offset>(
      begin: const Offset(0.1, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: AnimationConfig.enterCurve));

    final fadeTween = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: AnimationConfig.enterCurve));

    return SlideTransition(
      position: animation.drive(slideTween),
      child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
    );
  }
}

class AnimatedPageTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;

  const AnimatedPageTransition({
    super.key,
    required this.child,
    required this.animation,
    required this.secondaryAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    if (!appProvider.pageTransitionsEnabled || !appProvider.animationsEnabled) {
      return child;
    }

    final slideTween = Tween<Offset>(
      begin: const Offset(0.1, 0.0),
      end: Offset.zero,
    ).chain(CurveTween(curve: AnimationConfig.enterCurve));

    final fadeTween = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: AnimationConfig.enterCurve));

    return SlideTransition(
      position: animation.drive(slideTween),
      child: FadeTransition(opacity: animation.drive(fadeTween), child: child),
    );
  }
}

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration? duration;
  final Offset? offset;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration,
    this.offset,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? AnimationConfig.defaultDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationConfig.enterCurve),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: widget.offset ?? const Offset(0.0, 0.1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AnimationConfig.enterCurve,
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appProvider = context.watch<AppProvider>();
    if (appProvider.listAnimationsEnabled && appProvider.animationsEnabled) {
      final delay = Duration(milliseconds: (widget.index * 50).clamp(0, 300));
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    if (!appProvider.listAnimationsEnabled || !appProvider.animationsEnabled) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Duration? duration;
  final double scaleAmount;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.duration,
    this.scaleAmount = 0.02,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? AnimationConfig.fastDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0 - widget.scaleAmount)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: AnimationConfig.defaultCurve,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    final appProvider = context.read<AppProvider>();
    if (appProvider.cardAnimationsEnabled && appProvider.animationsEnabled) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onTap?.call();
      }
    });
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    if (!appProvider.cardAnimationsEnabled || !appProvider.animationsEnabled) {
      return GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: widget.child,
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

class AnimatedRipple extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? rippleColor;

  const AnimatedRipple({
    super.key,
    required this.child,
    this.onTap,
    this.rippleColor,
  });

  @override
  State<AnimatedRipple> createState() => _AnimatedRippleState();
}

class _AnimatedRippleState extends State<AnimatedRipple> {
  final List<_RippleInfo> _ripples = [];
  int _rippleId = 0;

  void _addRipple(Offset position) {
    final appProvider = context.read<AppProvider>();
    if (!appProvider.cardAnimationsEnabled || !appProvider.animationsEnabled) {
      widget.onTap?.call();
      return;
    }

    setState(() {
      _ripples.add(_RippleInfo(id: _rippleId++, position: position));
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _ripples.removeWhere((r) => r.id == _rippleId - 1);
        });
        widget.onTap?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (details) => _addRipple(details.localPosition),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          widget.child,
          if (appProvider.cardAnimationsEnabled &&
              appProvider.animationsEnabled)
            ..._ripples.map(
              (ripple) => _RippleWidget(
                key: ValueKey(ripple.id),
                position: ripple.position,
                color:
                    widget.rippleColor ??
                    colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }
}

class _RippleInfo {
  final int id;
  final Offset position;

  _RippleInfo({required this.id, required this.position});
}

class _RippleWidget extends StatefulWidget {
  final Offset position;
  final Color color;

  const _RippleWidget({super.key, required this.position, required this.color});

  @override
  State<_RippleWidget> createState() => _RippleWidgetState();
}

class _RippleWidgetState extends State<_RippleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: widget.position.dx - 100 * _animation.value,
          top: widget.position.dy - 100 * _animation.value,
          child: Container(
            width: 200 * _animation.value,
            height: 200 * _animation.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(
                alpha: 0.3 * (1 - _animation.value),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool isFilled;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
    this.isFilled = true,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConfig.fastDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: AnimationConfig.defaultCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final appProvider = context.read<AppProvider>();
    if (appProvider.buttonAnimationsEnabled && appProvider.animationsEnabled) {
      _controller.forward().then((_) {
        _controller.reverse();
        widget.onPressed?.call();
      });
    } else {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    if (!appProvider.buttonAnimationsEnabled ||
        !appProvider.animationsEnabled) {
      return widget.isFilled
          ? FilledButton(
              onPressed: widget.onPressed,
              style: widget.style,
              child: widget.child,
            )
          : OutlinedButton(
              onPressed: widget.onPressed,
              style: widget.style,
              child: widget.child,
            );
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: widget.isFilled
          ? FilledButton(
              onPressed: _handleTap,
              style: widget.style,
              child: widget.child,
            )
          : OutlinedButton(
              onPressed: _handleTap,
              style: widget.style,
              child: widget.child,
            ),
    );
  }
}

class LoadingAnimation extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingAnimation({super.key, this.size = 40.0, this.color});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!appProvider.animationsEnabled) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: color ?? colorScheme.primary,
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: _BeadLoadingAnimation(color: color ?? colorScheme.primary),
    );
  }
}

class _BeadLoadingAnimation extends StatefulWidget {
  final Color color;

  const _BeadLoadingAnimation({required this.color});

  @override
  State<_BeadLoadingAnimation> createState() => _BeadLoadingAnimationState();
}

class _BeadLoadingAnimationState extends State<_BeadLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    _animations = List.generate(9, (index) {
      final row = index ~/ 3;
      final col = index % 3;
      final delay = (row + col) * 0.1;
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(delay, delay + 0.4, curve: Curves.easeInOut),
        ),
      );
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
        return GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: List.generate(9, (index) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: _animations[index].value),
              ),
            );
          }),
        );
      },
    );
  }
}

class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration? duration;
  final Duration? delay;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration,
    this.delay,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? AnimationConfig.defaultDuration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.enterCurve,
    );

    final delay = widget.delay ?? Duration.zero;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

class SlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration? duration;
  final Duration? delay;
  final Offset beginOffset;

  const SlideInWidget({
    super.key,
    required this.child,
    this.duration,
    this.delay,
    this.beginOffset = const Offset(0.0, 0.1),
  });

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? AnimationConfig.defaultDuration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: AnimationConfig.enterCurve,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AnimationConfig.enterCurve),
    );

    final delay = widget.delay ?? Duration.zero;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHighest,
                colorScheme.surfaceContainerHigh,
                colorScheme.surfaceContainerHighest,
              ],
              stops: [0.0, 0.5 + _animation.value * 0.25, 1.0],
            ),
          ),
        );
      },
    );
  }
}
