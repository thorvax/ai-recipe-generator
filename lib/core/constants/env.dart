/// Secrets and config. DO NOT commit this file to GitHub.
/// Add this line to your .gitignore:   lib/core/constants/env.dart
///
/// Each teammate creates their own copy with their own free Gemini key
/// (get one at https://aistudio.google.com/apikey).
class Env {
  Env._();

  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Model id. Flash-Lite models have the most generous free daily limit.
  /// If you get a "model not found" error, check the current model list in
  /// Google AI Studio and change this string.
  static const String geminiModel = 'gemini-3.5-flash-lite';
}
