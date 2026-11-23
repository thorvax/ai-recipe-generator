import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Full-screen photo with pinch-to-zoom and a close button.
class PhotoViewerScreen extends StatelessWidget {
  final Uint8List bytes;

  const PhotoViewerScreen({super.key, required this.bytes});

  static Future<void> open(BuildContext context, Uint8List bytes) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoViewerScreen(bytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      // StackFit.expand: the Stack fills the whole screen. Without it, a
      // Stack is only as big as its non-positioned children (here it was
      // just the close button), so the photo was squeezed into a tiny box
      // in the top-left corner.
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ),
          // Positioned, so StackFit.expand doesn't stretch the button too.
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.scrimStart,
                  ),
                  icon: const Icon(Icons.close, color: AppColors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
