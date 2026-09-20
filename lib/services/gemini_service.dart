import 'dart:convert';
import 'package:http/http.dart' as http;

const geminiKey = String.fromEnvironment('GEMINI_API_KEY');
const geminiModel = 'gemini-3.6-flash'; // check AI Studio for the current name

Future<http.Response> postWithRetry(
  Uri url, {
  required Map<String, String> headers,
  required String body,
  int maxTries = 3,
}) async {
  for (var attempt = 1; attempt <= maxTries; attempt++) {
    final response = await http.post(url, headers: headers, body: body);
    final retryable = response.statusCode == 503 || response.statusCode == 429;
    if (!retryable || attempt == maxTries) return response;
    await Future.delayed(Duration(seconds: 2 * attempt)); // waits 2s, then 4s
  }
  throw StateError('unreachable');
}

Future<Map<String, dynamic>> generateRecipe({
  required List<String> ingredients,
  String mealType = 'any',
  String cuisine = 'any',
  int servings = 2,
  String dietary = 'none',
}) async {
  final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent',
  );

  final prompt =
      '''
Create a $cuisine $mealType recipe for $servings servings using: ${ingredients.join(', ')}.
Dietary restriction: $dietary.
Return ONLY JSON in this shape:
{"name":"","cookingTime":0,"ingredients":[{"name":"","quantity":"","unit":""}],"steps":[""]}
''';

  final response = await postWithRetry(
    url,
    headers: {
      'Content-Type': 'application/json',
      'x-goog-api-key': geminiKey.trim(),
    },
    body: jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'responseMimeType': 'application/json'},
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Gemini error ${response.statusCode}: ${response.body}');
  }

  final data = jsonDecode(response.body);
  final text = data['candidates'][0]['content']['parts'][0]['text'];
  return jsonDecode(text) as Map<String, dynamic>;
}
