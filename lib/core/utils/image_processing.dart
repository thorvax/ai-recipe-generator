import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The picture could not be made small enough to store.
class ImageTooLargeException implements Exception {
  @override
  String toString() => 'ImageTooLargeException';
}

/// The picked file is not an image we can read.
class ImageDecodeException implements Exception {
  @override
  String toString() => 'ImageDecodeException';
}

/// How to shrink a picture before it is stored as base64 in Firestore.
class ImageSpec {
  /// Longest side in pixels (both sides when [square]).
  final int maxSide;

  /// Center-crop to a square first (avatars).
  final bool square;

  /// JPEG qualities to try, best first.
  final List<int> qualities;

  /// Stop as soon as the JPEG is at most this many bytes.
  final int targetBytes;

  /// Never store more than this many bytes (base64 adds a third on top).
  final int hardCapBytes;

  const ImageSpec({
    required this.maxSide,
    required this.square,
    required this.qualities,
    required this.targetBytes,
    required this.hardCapBytes,
  });

  /// 256×256, ~25 KB. The cap keeps base64 under the 60,000-char rule.
  static const avatar = ImageSpec(
    maxSide: 256,
    square: true,
    qualities: [75, 65, 55, 45],
    targetBytes: 25 * 1024,
    hardCapBytes: 44000,
  );

  /// Post and comment photos: 900 px long side, ~150 KB, hard cap 300 KB.
  /// 300,000 bytes = exactly 400,000 base64 chars (the Firestore rule limit).
  static const photo = ImageSpec(
    maxSide: 900,
    square: false,
    qualities: [70, 60, 50, 40],
    targetBytes: 150 * 1024,
    hardCapBytes: 300000,
  );
}

/// Arguments for [processImage] (one object so it can go through compute).
class ImageJob {
  final Uint8List bytes;
  final ImageSpec spec;
  const ImageJob(this.bytes, this.spec);
}

/// Decodes, fixes rotation, crops/resizes and re-encodes as JPEG, lowering
/// the quality (and finally the size) until it fits. Pure and synchronous:
/// call it through `compute` so the UI does not freeze.
///
/// Throws [ImageDecodeException] or [ImageTooLargeException].
Uint8List processImage(ImageJob job) {
  final spec = job.spec;
  final decoded = img.decodeImage(job.bytes);
  if (decoded == null) throw ImageDecodeException();

  var image = img.bakeOrientation(decoded);
  if (spec.square) image = _centerSquare(image);

  Uint8List? smallest;
  // Full size first, then one smaller step if quality alone is not enough.
  for (final scale in const [1.0, 0.75]) {
    final resized = _fit(image, (spec.maxSide * scale).round());
    for (final q in spec.qualities) {
      final jpg = img.encodeJpg(resized, quality: q);
      if (smallest == null || jpg.length < smallest.length) smallest = jpg;
      if (jpg.length <= spec.targetBytes) return jpg;
    }
    if (smallest != null && smallest.length <= spec.hardCapBytes) {
      return smallest;
    }
  }
  throw ImageTooLargeException();
}

img.Image _centerSquare(img.Image src) {
  final side = src.width < src.height ? src.width : src.height;
  return img.copyCrop(
    src,
    x: (src.width - side) ~/ 2,
    y: (src.height - side) ~/ 2,
    width: side,
    height: side,
  );
}

/// Shrinks so the longest side is at most [maxSide]. Never enlarges.
img.Image _fit(img.Image src, int maxSide) {
  final longest = src.width > src.height ? src.width : src.height;
  if (longest <= maxSide) return src;
  return src.width >= src.height
      ? img.copyResize(
          src,
          width: maxSide,
          interpolation: img.Interpolation.average,
        )
      : img.copyResize(
          src,
          height: maxSide,
          interpolation: img.Interpolation.average,
        );
}
