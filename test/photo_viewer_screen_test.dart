import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:meal_mind/shared/widgets/photo_viewer_screen.dart';

void main() {
  // Regression test: the photo used to show as a tiny box in the top-left
  // corner, because the Stack shrank to the size of the close button.
  testWidgets('the photo viewer fills the whole screen', (tester) async {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 40, height: 30)),
    );

    await tester.pumpWidget(
      MaterialApp(home: PhotoViewerScreen(bytes: bytes)),
    );

    final screen = tester.getSize(find.byType(Scaffold));
    expect(tester.getSize(find.byType(InteractiveViewer)), screen);

    // The close button keeps its normal size in the top-left corner.
    final close = tester.getRect(find.byType(IconButton));
    expect(close.width, lessThan(100));
    expect(close.topLeft.dx, lessThan(20));
  });
}
