import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Thrown when someone else already has the username. The message can be
/// shown to the user as-is.
class UsernameTakenException implements Exception {
  final String message = 'That username is already taken.';

  @override
  String toString() => message;
}

/// Unique usernames (same rules and Firestore layout as the website's
/// resources/js/lib/username.ts — keep both in sync).
///
/// Each taken name is a document usernames/{username} = { user_id,
/// created_at }. The document id IS the username, so Firestore itself makes
/// them unique: the rules refuse to create a document that already exists.
/// Login still uses email + password; the username is the name shown on
/// posts, comments and the profile.
class UsernameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int minLength = 3;
  static const int maxLength = 20;
  static const Duration timeout = Duration(seconds: 8);
  static final RegExp _pattern = RegExp(r'^[a-z0-9._]{3,20}$');

  // ---------- pure helpers (unit-tested) ----------

  /// What the user typed, as stored: trimmed and lower-case.
  static String normalize(String text) => text.trim().toLowerCase();

  /// An error message, or null when the username is allowed.
  static String? validate(String? text) {
    final username = normalize(text ?? '');
    if (username.isEmpty) return 'Username is required';
    if (username.length < minLength || username.length > maxLength) {
      return 'Use $minLength to $maxLength characters';
    }
    if (!_pattern.hasMatch(username)) {
      return 'Use only lowercase letters, numbers, dots and underscores';
    }
    return null;
  }

  /// A starting point for an auto-made username, from a name or an email:
  /// "Marc Bartolome" -> "marcbartolome", "ana.reyes@gmail.com" -> "ana.reyes".
  static String baseFrom(String nameOrEmail) {
    var base = nameOrEmail
        .split('@')
        .first
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._]'), '')
        .replaceAll(RegExp(r'^[._]+|[._]+$'), '');
    // Leave room for up to 4 digits.
    if (base.length > maxLength - 4) base = base.substring(0, maxLength - 4);
    return base.length >= minLength ? base : 'cook';
  }

  static final Random _random = Random();

  /// base + 4 random digits, e.g. "marc4821". The last resort only.
  static String _withRandomDigits(String base) {
    final short =
        base.length > maxLength - 4 ? base.substring(0, maxLength - 4) : base;
    return '$short${1000 + _random.nextInt(9000)}';
  }

  /// Friendly cooking words mixed into suggestions ("skyrashoumon").
  /// Same list and order as the website.
  static const List<String> suggestionWords = [
    'sky', 'chef', 'tasty', 'spicy', 'sweet', 'fresh', 'happy', 'golden',
    'sunny', 'crispy', 'cozy', 'yummy', 'zesty', 'savory', 'honey', 'pepper',
    'mango', 'herb',
  ];

  // How a word joins the name: skyrashoumon, rashoumon_chef,
  // tasty.rashoumon, rashoumonspicy.
  static final List<String Function(String word, String name)> _patterns = [
    (word, name) => '$word$name',
    (word, name) => '${name}_$word',
    (word, name) => '$word.$name',
    (word, name) => '$name$word',
  ];

  /// Username ideas built from what the user typed plus a random word,
  /// e.g. "rashoumon" -> [skyrashoumon, rashoumon_chef, tasty.rashoumon].
  /// All valid, all different, never the typed name itself. Not yet
  /// checked against Firestore: [findAvailableSuggestions] does that.
  /// [random] returns 0..1 and can be replaced in tests (like the web).
  static List<String> suggestions(
    String text, {
    int count = 3,
    double Function()? random,
  }) {
    final next = random ?? _random.nextDouble;
    final name = baseFrom(text);
    // Shuffle the words (Fisher–Yates) so each attempt gives new ideas.
    final words = [...suggestionWords];
    for (var i = words.length - 1; i > 0; i--) {
      final j = (next() * (i + 1)).floor();
      final tmp = words[i];
      words[i] = words[j];
      words[j] = tmp;
    }

    final result = <String>[];
    for (var index = 0; index < words.length; index++) {
      final word = words[index];
      final pattern = _patterns[index % _patterns.length];
      // Room for the word and its joining character.
      final room = maxLength - word.length - 1;
      final shortName = (name.length > room ? name.substring(0, room) : name)
          .replaceAll(RegExp(r'[._]+$'), '');
      final candidate = pattern(word, shortName);
      if (validate(candidate) == null &&
          candidate != name &&
          !result.contains(candidate)) {
        result.add(candidate);
      }
      if (result.length == count) break;
    }
    return result;
  }

  // ---------- Firestore ----------

  DocumentReference<Map<String, dynamic>> _nameDoc(String username) =>
      _db.collection('usernames').doc(username);

  /// True when nobody has this username yet (works before login too).
  Future<bool> isAvailable(String username) async {
    final snap = await _nameDoc(normalize(username)).get().timeout(timeout);
    return !snap.exists;
  }

  /// Up to [count] suggestions for [text] that nobody has yet. Checks a few
  /// extra ideas at once, because some may be taken too.
  Future<List<String>> findAvailableSuggestions(
    String text, {
    int count = 3,
  }) async {
    final ideas = suggestions(text, count: count * 2);
    final free = await Future.wait(
      ideas.map((idea) => isAvailable(idea).catchError((_) => false)),
    );
    return [
      for (var i = 0; i < ideas.length; i++)
        if (free[i]) ideas[i],
    ].take(count).toList();
  }

  /// The user's username from users/{uid}, or null when they have none.
  Future<String?> getUsername(String uid) async {
    final snap =
        await _db.collection('users').doc(uid).get().timeout(timeout);
    final username = snap.data()?['username'];
    return username is String && username.isNotEmpty ? username : null;
  }

  /// Makes [text] the user's username in one transaction: claims
  /// usernames/{username}, saves it on users/{uid} (also as `name`), and
  /// frees the old one. Throws [UsernameTakenException] if it's taken.
  Future<String> claim({
    required String uid,
    required String email,
    required String text,
  }) async {
    final username = normalize(text);
    final newRef = _nameDoc(username);
    final userRef = _db.collection('users').doc(uid);

    try {
      await _db.runTransaction((transaction) async {
        final taken = await transaction.get(newRef);
        final userDoc = await transaction.get(userRef);
        final oldUsername = userDoc.data()?['username'];

        if (taken.exists && taken.data()?['user_id'] != uid) {
          throw UsernameTakenException();
        }

        if (!taken.exists) {
          transaction.set(newRef, {
            'user_id': uid,
            'created_at': FieldValue.serverTimestamp(),
          });
        }

        transaction.set(
          userRef,
          {
            'user_id': uid,
            'email': email,
            'username': username,
            'name': username,
          },
          SetOptions(merge: true),
        );

        // Free the old name so someone else can take it.
        if (oldUsername is String && oldUsername != username) {
          transaction.delete(_nameDoc(oldUsername));
        }
      }).timeout(timeout);
    } on UsernameTakenException {
      rethrow;
    } on FirebaseException {
      // Another account claimed it at the same moment: the rules refuse to
      // overwrite an existing username, so it lands here.
      final stillFree = await isAvailable(username).catchError((_) => true);
      if (!stillFree) throw UsernameTakenException();
      rethrow;
    }

    return username;
  }

  /// Gives an account without a username (older accounts, first Google
  /// login) one made from its name or email: "marc", or a word mix like
  /// "skymarc" / "marc_chef" when that's taken. Returns the username.
  Future<String> ensure({
    required String uid,
    required String email,
    required String nameOrEmail,
  }) async {
    final existing = await getUsername(uid);
    if (existing != null) return existing;

    final base = baseFrom(nameOrEmail);
    final candidates = [
      base,
      ...suggestions(base, count: 6),
      // Very unlikely to be needed: all the word mixes were taken.
      _withRandomDigits(base),
      _withRandomDigits(base),
    ];

    for (final candidate in candidates) {
      try {
        return await claim(uid: uid, email: email, text: candidate);
      } on UsernameTakenException {
        // Try the next one.
      }
    }
    throw UsernameTakenException();
  }
}
