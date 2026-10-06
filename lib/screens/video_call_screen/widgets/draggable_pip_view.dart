import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class DraggablePipView extends StatefulWidget {
  final CameraController? controller;
  final bool isCameraOff;

  const DraggablePipView({
    super.key,
    required this.controller,
    required this.isCameraOff,
  });

  @override
  State<DraggablePipView> createState() => _DraggablePipViewState();
}

class _DraggablePipViewState extends State<DraggablePipView> {
  Offset position = const Offset(20, 80);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const pipWidth = 110.0;
    const pipHeight = 160.0;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            position = Offset(
              (position.dx + details.delta.dx).clamp(16.0, screenSize.width - pipWidth - 16.0),
              (position.dy + details.delta.dy).clamp(50.0, screenSize.height - pipHeight - 100.0),
            );
          });
        },
        child: Container(
          width: pipWidth,
          height: pipHeight,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: widget.isCameraOff || widget.controller == null || !widget.controller!.value.isInitialized
              ? const Center(
                  child: Icon(Icons.videocam_off, color: Colors.white54, size: 32),
                )
              : CameraPreview(widget.controller!),
        ),
      ),
    );
  }
}