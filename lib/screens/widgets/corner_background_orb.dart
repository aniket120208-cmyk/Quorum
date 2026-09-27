import 'package:flutter/material.dart';

class CornerBackgroundOrb extends StatelessWidget {
  final Color backgroundColor;
  const CornerBackgroundOrb({super.key,required this.backgroundColor,});
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -120,
      bottom: -100,
      child: Container(
        width: 330,
        height: 330,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [
              const Color(0xFF2B255D).withOpacity(0.55),
              const Color(0xFF16152B).withOpacity(0.3),
              backgroundColor.withOpacity(0.0),
            ],
            stops: const [0.0, 0.65, 1.0],
          ),
        ),
      ),
    );
  }
}