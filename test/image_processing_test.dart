import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meal_mind/core/utils/image_processing.dart';
import 'package:meal_mind/models/public_profile.dart';

/// A smooth gradient: compresses well, like most real photos.
Uint8List _gradientPng(int w, int h) {
  final im = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      im.setPixelRgb(x, y, x * 255 ~/ w, y * 255 ~/ h, 120);
    }
  }
  return img.encodePng(im);
}

/// Random noise: the worst case for JPEG.
Uint8List _noisePng(int w, int h) {
  final rnd = Random(42);
  final im = img.Image(width: w, height: h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      im.setPixelRgb(
        x,
        y,
        rnd.nextInt(256),
        rnd.nextInt(256),
        rnd.nextInt(256),
      );
    }
  }
  return img.encodePng(im);
}

void main() {
  group('processImage avatar', () {
    test('center-crops to a 256x256 square under 25 KB', () {
      final out = processImage(
        ImageJob(_gradientPng(1200, 800), ImageSpec.avatar),
      );
      final decoded = img.decodeJpg(out)!;
      expect(decoded.width, 256);
      expect(decoded.height, 256);
      expect(out.length, lessThanOrEqualTo(ImageSpec.avatar.targetBytes));
    });

    test(
      'noisy avatar still fits the hard cap (rule: 60,000 base64 chars)',
      () {
        final out = processImage(
          ImageJob(_noisePng(600, 600), ImageSpec.avatar),
        );
        expect(out.length, lessThanOrEqualTo(ImageSpec.avatar.hardCapBytes));
        expect((out.length + 2) ~/ 3 * 4, lessThanOrEqualTo(60000));
      },
    );
  });

  group('processImage photo', () {
    test('limits the long side to 900 px and keeps the aspect ratio', () {
      final out = processImage(
        ImageJob(_gradientPng(1800, 1200), ImageSpec.photo),
      );
      final decoded = img.decodeJpg(out)!;
      expect(decoded.width, 900);
      expect(decoded.height, 600);
      expect(out.length, lessThanOrEqualTo(ImageSpec.photo.targetBytes));
    });

    test('portrait images are limited by height', () {
      final out = processImage(
        ImageJob(_gradientPng(600, 1500), ImageSpec.photo),
      );
      final decoded = img.decodeJpg(out)!;
      expect(decoded.height, 900);
      expect(decoded.width, 360);
    });

    test('does not enlarge small images', () {
      final out = processImage(
        ImageJob(_gradientPng(300, 200), ImageSpec.photo),
      );
      final decoded = img.decodeJpg(out)!;
      expect(decoded.width, 300);
    });

    test('noise is compressed under the hard cap (rule: 400,000 chars)', () {
      final out = processImage(ImageJob(_noisePng(1200, 900), ImageSpec.photo));
      expect(out.length, lessThanOrEqualTo(ImageSpec.photo.hardCapBytes));
      expect((out.length + 2) ~/ 3 * 4, lessThanOrEqualTo(400000));
    });

    test('throws ImageTooLargeException when nothing fits the cap', () {
      const tiny = ImageSpec(
        maxSide: 900,
        square: false,
        qualities: [70, 40],
        targetBytes: 100,
        hardCapBytes: 200,
      );
      expect(
        () => processImage(ImageJob(_noisePng(400, 400), tiny)),
        throwsA(isA<ImageTooLargeException>()),
      );
    });

    test('throws ImageDecodeException for non-image bytes', () {
      expect(
        () => processImage(
          ImageJob(Uint8List.fromList([1, 2, 3, 4]), ImageSpec.photo),
        ),
        throwsA(isA<ImageDecodeException>()),
      );
    });
  });

  group('normalizeGooglePhotoUrl', () {
    test('requests 256 px instead of 96 px', () {
      expect(
        PublicProfile.normalizeGooglePhotoUrl(
          'https://lh3.googleusercontent.com/a/abc=s96-c',
        ),
        'https://lh3.googleusercontent.com/a/abc=s256-c',
      );
    });

    test('leaves other URLs alone and maps empty to null', () {
      expect(
        PublicProfile.normalizeGooglePhotoUrl('https://x.com/p.jpg'),
        'https://x.com/p.jpg',
      );
      expect(PublicProfile.normalizeGooglePhotoUrl(''), isNull);
      expect(PublicProfile.normalizeGooglePhotoUrl(null), isNull);
    });
  });
}
