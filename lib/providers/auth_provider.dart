import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_routes.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

/// Holds auth state for the UI (loading + error message) and
/// calls AuthService. Screens read this with context.read / context.watch.
class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;

  // Separate from _isLoading so only the Google button shows a spinner.
  bool _isGoogleLoading = false;
  bool get isGoogleLoading => _isGoogleLoading;
  String? get errorMessage => _errorMessage;

  User? get currentUser => _service.currentUser;
  bool get isLoggedIn => currentUser != null;

  /// Email accounts must tap the link in the verification email before
  /// using the app. Google accounts are always verified.
  bool get needsEmailVerification =>
      currentUser != null && !currentUser!.emailVerified;

  /// Where to go after login: Home, or the Verify Email screen first.
  String get homeRoute =>
      needsEmailVerification ? AppRoutes.verifyEmail : AppRoutes.home;

  /// When the verification email was last sent in this session, or null.
  DateTime? get lastVerificationSentAt => AuthService.lastVerificationSentAt;
  DateTime? get lastPasswordResetSentAt => AuthService.lastPasswordResetSentAt;

  Future<bool> sendVerificationEmail() =>
      _run(() => _service.sendVerificationEmail());

  /// True once verified. False (with errorMessage set on failures, or a
  /// "not yet" message) otherwise.
  Future<bool> checkEmailVerified() async {
    var verified = false;
    final ok = await _run(() async {
      verified = await _service.checkEmailVerified();
    });
    if (ok && !verified) {
      _errorMessage =
          'Not verified yet. Tap the link in the email first, then try again.';
      notifyListeners();
    }
    return verified;
  }

  /// Name shown to other users: the username (kept as the display name by
  /// syncAccount), else the part before "@".
  String get displayName {
    final user = currentUser;
    final name = user?.displayName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final email = user?.email ?? '';
    return email.contains('@') ? email.split('@').first : 'Cook';
  }

  /// Google profile photo (256 px), or null for email accounts.
  String? get googlePhotoUrl => ProfileService.googlePhotoUrlOf(currentUser);

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Runs an auth action, handling loading + errors. Returns true on success.
  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) =>
      _run(() => _service.signUp(
            username: username,
            email: email,
            password: password,
          ));

  /// Call after every login (and when the app opens signed in), before
  /// showing Home: completes the account (username, profile) and loads the
  /// dietary preferences.
  Future<void> afterLogin() async {
    await _service.syncAccount();
    await loadDietaryPreferences();
    notifyListeners(); // the display name may now be the username
  }

  /// True when signed in. False if cancelled (no error shown) or failed
  /// (errorMessage is set).
  Future<bool> signInWithGoogle() async {
    _isGoogleLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await _service.signInWithGoogle();
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isGoogleLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) =>
      _run(() => _service.signIn(email: email, password: password));

  /// Returns the saved username, or null on failure (errorMessage is set).
  Future<String?> changeUsername(String username) async {
    String? saved;
    final ok = await _run(() async {
      saved = await _service.changeUsername(username);
    });
    return ok ? saved : null;
  }

  List<String> _dietaryNeeds = [];
  List<String> get dietaryNeeds => _dietaryNeeds;

  /// Loads the saved dietary preferences (call once after login).
  Future<void> loadDietaryPreferences() async {
    _dietaryNeeds = await _service.getDietaryPreferences();
    notifyListeners();
  }

  Future<bool> updateDietaryPreferences(List<String> needs) async {
    final ok = await _run(() => _service.updateDietaryPreferences(needs));
    if (ok) {
      _dietaryNeeds = needs;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _service.sendPasswordReset(email));

  Future<void> signOut() {
    _dietaryNeeds = [];
    return _service.signOut();
  }
}
