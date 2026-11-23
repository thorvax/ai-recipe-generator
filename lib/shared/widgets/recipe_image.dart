import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/utils/image_bytes_cache.dart';

/// A recipe photo stored as base64, or the default recipe image when
/// there is none. Fills its parent (give it a size or use Positioned.fill).
///
/// The base64 is decoded once (cached per [cacheKey] + length), outside
/// of build, so scrolling the feed stays smooth.
class RecipeImage extends StatefulWidget {
  /// Unique per picture, e.g. the post id.
  final String cacheKey;
  final String? base64;

  /// Decode width in pixels (smaller = less memory).
  final int cacheWidth;

  const RecipeImage({
    super.key,
    required this.cacheKey,
    required this.base64,
    this.cacheWidth = 800,
  });

  @override
  State<RecipeImage> createState() => _RecipeImageState();
}

class _RecipeImageState extends State<RecipeImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = ImageBytesCache.decode(widget.cacheKey, widget.base64);
  }

  @override
  void didUpdateWidget(RecipeImage old) {
    super.didUpdateWidget(old);
    if (old.cacheKey != widget.cacheKey ||
        old.base64?.length != widget.base64?.length) {
      _bytes = ImageBytesCache.decode(widget.cacheKey, widget.base64);
    }
  }

  Widget _defaultImage() => Image.asset(
    AppAssets.defaultRecipe,
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    cacheWidth: widget.cacheWidth,
  );

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return _defaultImage();
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      cacheWidth: widget.cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _defaultImage(),
    );
  }
}
