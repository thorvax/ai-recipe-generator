import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/public_profile.dart';
import '../services/media_service.dart';
import '../services/profile_service.dart';

/// Result of changing the avatar: [error] is null on success.
/// [changed] is false when the user cancelled the picker.
typedef AvatarResult = ({bool changed, String? error});

/// Public profiles (name + avatar) of every user shown on screen.
/// Each uid is fetched at most once per session; concurrent requests for
/// the same uid share one Firestore read.
class ProfileProvider extends ChangeNotifier {
  final ProfileService _service = ProfileService();
  final MediaService _media = MediaService();

  final Map<String, PublicProfile?> _cache = {};
  final Map<String, Future<void>> _inflight = {};

  String? _myUid;
  String _myName = 'Cook';
  bool _isSavingAvatar = false;
  int _session = 0; // bumped on logout so late responses are ignored

  bool get isSavingAvatar => _isSavingAvatar;

  /// Null while loading, on error, or when the user has no profile.
  PublicProfile? profileFor(String uid) => _cache[uid];

  PublicProfile? get myProfile => _myUid == null ? null : _cache[_myUid];

  /// Fetches a profile once per session. Safe to call from many widgets.
  Future<void> load(String uid) {
    if (uid.isEmpty || _cache.containsKey(uid)) return Future.value();
    return _inflight[uid] ??= _fetch(uid);
  }

  Future<void> _fetch(String uid) async {
    final session = _session;
    try {
      final profile = await _service.get(uid);
      if (session != _session) return; // logged out meanwhile
      _cache[uid] = profile;
    } catch (e) {
      // Not cached, so a later screen can try again.
      debugPrint('load profile $uid failed: $e');
    } finally {
      if (session == _session) {
        _inflight.remove(uid);
        notifyListeners();
      }
    }
  }

  /// Called once after login: creates the profile for older accounts
  /// and refreshes the Google photo when there is no custom avatar.
  Future<void> ensureMine({
    required String uid,
    required String name,
    String? googlePhotoUrl,
  }) async {
    _myUid = uid;
    _myName = name;
    try {
      _cache[uid] = await _service.ensure(
        uid: uid,
        name: name,
        googlePhotoUrl: googlePhotoUrl,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('ensureMine failed: $e');
      unawaited(load(uid));
    }
  }

  /// Picks, compresses and saves a new avatar.
  Future<AvatarResult> changeAvatar(MediaSource source) async {
    final uid = _myUid;
    if (uid == null) return (changed: false, error: 'You are not logged in.');

    final String? b64;
    try {
      b64 = await _media.pickAvatar(source);
    } on MediaException catch (e) {
      return (changed: false, error: e.message);
    }
    if (b64 == null) return (changed: false, error: null); // cancelled

    final error = await _saveAvatar(uid, b64);
    return (changed: error == null, error: error);
  }

  /// Removes the custom avatar (falls back to Google photo or default).
  Future<String?> removeAvatar() async {
    final uid = _myUid;
    if (uid == null) return 'You are not logged in.';
    return _saveAvatar(uid, null);
  }

  Future<String?> _saveAvatar(String uid, String? b64) async {
    _isSavingAvatar = true;
    notifyListeners();
    try {
      await _service.setAvatar(uid: uid, name: _myName, avatarBase64: b64);
      final old = _cache[uid];
      _cache[uid] = PublicProfile(
        uid: uid,
        name: old?.name ?? _myName,
        avatarBase64: b64,
        photoUrl: old?.photoUrl,
      );
      return null;
    } catch (e) {
      debugPrint('save avatar failed: $e');
      if (e is TimeoutException) {
        return 'Could not reach the server. Check your connection and try again.';
      }
      return 'Could not save your photo. Please try again.';
    } finally {
      _isSavingAvatar = false;
      notifyListeners();
    }
  }

  /// Keeps the cached name in sync after Edit Profile (Firestore is
  /// updated by AuthService.updateName).
  void onNameChanged(String name) {
    final uid = _myUid;
    _myName = name.trim();
    if (uid == null) return;
    final old = _cache[uid];
    if (old != null) {
      _cache[uid] = PublicProfile(
        uid: uid,
        name: _myName,
        avatarBase64: old.avatarBase64,
        photoUrl: old.photoUrl,
      );
    }
    notifyListeners();
  }

  /// Forget everything (logout).
  void clear() {
    _session++;
    _cache.clear();
    _inflight.clear();
    _myUid = null;
    _myName = 'Cook';
    notifyListeners();
  }
}
