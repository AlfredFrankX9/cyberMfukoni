import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';

/// A reusable glassmorphism container with frosted-glass effect.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? borderColor;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.08,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.borderColor,
    this.backgroundColor,
    this.width,
    this.height,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (backgroundColor ?? Colors.white).withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.12),
                width: 1.0,
              ),
              boxShadow: boxShadow ?? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Animated floating orbs for background decoration.
class FloatingOrbs extends StatefulWidget {
  final int count;
  final List<Color>? colors;

  const FloatingOrbs({super.key, this.count = 4, this.colors});

  @override
  State<FloatingOrbs> createState() => _FloatingOrbsState();
}

class _FloatingOrbsState extends State<FloatingOrbs> with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<Offset>> _animations;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    final defaultColors = [
      const Color(0xFF00FFCC),
      const Color(0xFFAA00FF),
      const Color(0xFF00B8D4),
      const Color(0xFFFF6D00),
    ];
    final colors = widget.colors ?? defaultColors;

    _controllers = List.generate(widget.count, (i) {
      return AnimationController(
        duration: Duration(seconds: 6 + _random.nextInt(8)),
        vsync: this,
      )..repeat(reverse: true);
    });

    _animations = List.generate(widget.count, (i) {
      final startX = -0.5 + _random.nextDouble() * 1.0;
      final startY = -0.5 + _random.nextDouble() * 1.0;
      final endX = -0.5 + _random.nextDouble() * 1.0;
      final endY = -0.5 + _random.nextDouble() * 1.0;
      return Tween<Offset>(
        begin: Offset(startX, startY),
        end: Offset(endX, endY),
      ).animate(CurvedAnimation(
        parent: _controllers[i],
        curve: Curves.easeInOutSine,
      ));
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultColors = [
      const Color(0xFF00FFCC),
      const Color(0xFFAA00FF),
      const Color(0xFF00B8D4),
      const Color(0xFFFF6D00),
    ];
    final colors = widget.colors ?? defaultColors;
    final sizes = [180.0, 140.0, 200.0, 120.0, 160.0, 150.0];

    return Stack(
      children: List.generate(widget.count, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (context, child) {
            return Positioned(
              left: MediaQuery.of(context).size.width * (0.3 + _animations[i].value.dx * 0.5),
              top: MediaQuery.of(context).size.height * (0.2 + _animations[i].value.dy * 0.5),
              child: Container(
                width: sizes[i % sizes.length],
                height: sizes[i % sizes.length],
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors[i % colors.length].withOpacity(0.25),
                      colors[i % colors.length].withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// A 3D tilt effect wrapper that responds to pointer position.
class Tilt3DCard extends StatefulWidget {
  final Widget child;
  final double maxTilt;
  final Duration duration;

  const Tilt3DCard({
    super.key,
    required this.child,
    this.maxTilt = 0.04,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<Tilt3DCard> createState() => _Tilt3DCardState();
}

class _Tilt3DCardState extends State<Tilt3DCard> {
  double _rotateX = 0;
  double _rotateY = 0;

  void _onHover(PointerEvent event, BoxConstraints constraints) {
    final dx = (event.localPosition.dx - constraints.maxWidth / 2) / constraints.maxWidth;
    final dy = (event.localPosition.dy - constraints.maxHeight / 2) / constraints.maxHeight;
    setState(() {
      _rotateY = dx * widget.maxTilt;
      _rotateX = -dy * widget.maxTilt;
    });
  }

  void _onExit(PointerEvent event) {
    setState(() {
      _rotateX = 0;
      _rotateY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onHover: (e) => _onHover(e, constraints),
          onExit: _onExit,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(_rotateX)
              ..rotateY(_rotateY),
            transformAlignment: Alignment.center,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Neon glow text with animated shimmer.
class NeonText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final double letterSpacing;
  final double glowRadius;

  const NeonText({
    super.key,
    required this.text,
    this.fontSize = 28,
    this.color = const Color(0xFF00FFCC),
    this.fontWeight = FontWeight.bold,
    this.letterSpacing = 2,
    this.glowRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        shadows: [
          Shadow(color: color.withOpacity(0.6), blurRadius: glowRadius),
          Shadow(color: color.withOpacity(0.3), blurRadius: glowRadius * 2),
          Shadow(color: color.withOpacity(0.15), blurRadius: glowRadius * 3),
        ],
      ),
    );
  }
}

/// Fade-slide-in animation wrapper for staggered entry effects.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.offset = const Offset(0, 30),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _position = Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(widget.delay, () {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _position.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Pulsing glow animation for icons or circular elements.
class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color color;
  final double maxRadius;

  const PulsingGlow({
    super.key,
    required this.child,
    this.color = const Color(0xFF00FFCC),
    this.maxRadius = 20,
  });

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 * _controller.value),
                blurRadius: widget.maxRadius * _controller.value,
                spreadRadius: widget.maxRadius * 0.3 * _controller.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
