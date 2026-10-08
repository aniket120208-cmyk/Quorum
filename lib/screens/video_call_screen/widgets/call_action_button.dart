import 'package:flutter/material.dart';

class CallActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool isActive;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const CallActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.isActive = false,
    this.backgroundColor,
    this.iconColor,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? (isActive ? Colors.white : Colors.white.withValues(alpha: 0.16));
    final fg = iconColor ?? (isActive ? Colors.black : Colors.white);
    return Semantics(
      button: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: bg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(icon, color: fg, size: size * 0.5),
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }
}