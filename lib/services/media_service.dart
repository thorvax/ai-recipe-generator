import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/image_processing.dart';

/// A friendly error that the UI can show directly.
class MediaException implements Exception {
  final String message;
  MediaException(this.message);

  @override
  String toString() => message;
}

/// Where to pick a picture from (keeps image_picker out of the widgets).
enum MediaSource { camera, gallery }

/// Picks a picture and shrinks it to a base64 JPEG for Firestore.
/// No Firebase code here, and no paid storage: the string is saved
/// inside the Firestore document itself.
class MediaService {
  final ImagePicker _picker = ImagePicker();

  /// Square 256×256 profile picture. Null if the user cancelled.
  Future<String?> pickAvatar(MediaSource source) =>
      _pick(source, ImageSpec.avatar);

  /// Recipe / comment photo (max 900 px). Null if the user cancelled.
  Future<String?> pickPhoto(MediaSource source) =>
      _pick(source, ImageSpec.photo);

  Future<String?> _pick(MediaSource source, ImageSpec spec) async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: source == MediaSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        // Let Android shrink big camera photos natively first, so the
        // pure-Dart step below has much less work to do.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
    } on PlatformException catch (e) {
      debugPrint('pickImage failed: ${e.code} ${e.message}');
      if (e.code.contains('access_denied')) {
        throw MediaException(
          'MealMind needs permission to use your camera or photos.',
        );
      }
      throw MediaException('Could not open the picture. Please try again.');
    }
    if (file == null) return null;

    try {
      final bytes = await file.readAsBytes();
      final jpg = await compute(processImage, ImageJob(bytes, spec));
      return base64Encode(jpg);
    } on ImageTooLargeException {
      throw MediaException(
        'That picture is too large even after compressing. Try another one.',
      );
    } on ImageDecodeException {
      throw MediaException('That file is not a picture we can read.');
    } catch (e) {
      debugPrint('processImage failed: $e');
      throw MediaException('Could not process the picture. Try another one.');
    }
  }
}
