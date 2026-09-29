import 'package:flutter/material.dart';

class CornerBackgroundOrb extends StatelessWidget {
  final Color backgroundColor;
  final Color innerColor;
  final Color midColor;
  final double innerOpacity;
  final double midOpacity;
  final double size;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;

  const CornerBackgroundOrb({
    super.key,
    required this.backgroundColor,
    required this.innerColor,
    required this.midColor,
    this.innerOpacity = 0.55,
    this.midOpacity = 0.3,
    this.size = 330,
    this.left,
    this.right,
    this.top,
    this.bottom,
  });

  const CornerBackgroundOrb.bottomLeft({
    super.key,
    required this.backgroundColor,
  })  : innerColor = const Color(0xFF2B255D),
        midColor = const Color(0xFF16152B),
        innerOpacity = 0.55,
        midOpacity = 0.3,
        size = 330,
        left = -120,
        bottom = -100,
        right = null,
        top = null;

  const CornerBackgroundOrb.topRight({
    super.key,
    required this.backgroundColor,
  })  : innerColor = const Color(0xFF3B319A),
        midColor = const Color(0xFF231F5C),
        innerOpacity = 0.85,
        midOpacity = 0.45,
        size = 300,
        right = -110,
        top = -110,
        left = null,
        bottom = null;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.85,
              colors: [
                innerColor.withOpacity(innerOpacity),
                midColor.withOpacity(midOpacity),
                backgroundColor.withOpacity(0.0),
              ],
              stops: const [0.0, 0.65, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class OrbBackground extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const OrbBackground({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF0E0E1A),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          CornerBackgroundOrb.topRight(backgroundColor: backgroundColor),
          CornerBackgroundOrb.bottomLeft(backgroundColor: backgroundColor),
          SafeArea(child: child),
        ],
      ),
    );
  }
}