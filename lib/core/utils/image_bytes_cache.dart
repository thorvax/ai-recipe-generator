import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

/// Decodes base64 images once and remembers the bytes, so scrolling the feed
/// does not decode the same picture again on every rebuild.
///
/// The key is "id:length": if a picture changes, its length (almost always)
/// changes too, so the old bytes are not reused.
class ImageBytesCache {
  ImageBytesCache._();

  static const int _maxEntries = 80;
  static final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();

  /// Returns null for null/empty/invalid input.
  static Uint8List? decode(String id, String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    final key = '$id:${base64.length}';
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit; // move to the end (most recently used)
      return hit;
    }
    try {
      final bytes = base64Decode(base64);
      _cache[key] = bytes;
      if (_cache.length > _maxEntries) _cache.remove(_cache.keys.first);
      return bytes;
    } on FormatException {
      return null;
    }
  }
}
