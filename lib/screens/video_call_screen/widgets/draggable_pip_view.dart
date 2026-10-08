import 'package:flutter/material.dart';

class DraggablePipView extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double margin;
  final double topInset;
  final double bottomInset;

  const DraggablePipView({
    super.key,
    required this.child,
    this.width = 110,
    this.height = 160,
    this.margin = 16,
    this.topInset = 72,
    this.bottomInset = 120,
  });

  @override
  State<DraggablePipView> createState() => _DraggablePipViewState();
}

class _DraggablePipViewState extends State<DraggablePipView> {
  Offset? _position;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minX = widget.margin;
        final maxX = constraints.maxWidth - widget.width - widget.margin;
        final minY = widget.topInset;
        final maxY = constraints.maxHeight - widget.height - widget.bottomInset;

        final pos = _position ?? Offset(maxX, minY);
        final clamped = Offset(
          pos.dx.clamp(minX, maxX < minX ? minX : maxX),
          pos.dy.clamp(minY, maxY < minY ? minY : maxY),
        );

        return Stack(
          children: [
            AnimatedPositioned(
              duration:
                  _dragging ? Duration.zero : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: clamped.dx,
              top: clamped.dy,
              child: GestureDetector(
                onPanStart: (_) => setState(() {
                  _dragging = true;
                  _position = clamped;
                }),
                onPanUpdate: (d) => setState(() {
                  final p = (_position ?? clamped) + d.delta;
                  _position = Offset(
                    p.dx.clamp(minX, maxX < minX ? minX : maxX),
                    p.dy.clamp(minY, maxY < minY ? minY : maxY),
                  );
                }),
                onPanEnd: (_) {
                  final p = _position ?? clamped;
                  final centerX = p.dx + widget.width / 2;
                  final centerY = p.dy + widget.height / 2;
                  setState(() {
                    _dragging = false;
                    _position = Offset(
                      centerX < constraints.maxWidth / 2 ? minX : maxX,
                      centerY < constraints.maxHeight / 2 ? minY : maxY,
                    );
                  });
                },
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}