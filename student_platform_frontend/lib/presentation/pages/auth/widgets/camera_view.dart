import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CameraView extends StatelessWidget {
  final bool isCameraReady;
  final CameraController? controller;
  final bool isProcessing;

  const CameraView({
    super.key,
    required this.isCameraReady,
    this.controller,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            border: Border.all(color: const Color(0xFF1E3A8A), width: 4),
          ),
          child: ClipOval(
            child: isCameraReady && controller != null
                ? CameraPreview(controller!)
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
        if (isCameraReady)
          Container(
            width: 330,
            height: 330,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isProcessing ? Colors.cyan : const Color(0xFF1E3A8A).withOpacity(0.3),
                width: 2,
              ),
            ),
          ).animate(onPlay: (c) => c.repeat())
           .shimmer(duration: 2.seconds, color: Colors.blue.withOpacity(0.4)),
      ],
    );
  }
}
