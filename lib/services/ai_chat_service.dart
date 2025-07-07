import 'dart:convert';
import 'package:http/http.dart' as http;

class AIChatService {
  static const String _apiKey = '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';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  static Future<String?> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          // Optionally add these for OpenRouter rankings:
          // 'HTTP-Referer': '<YOUR_SITE_URL>',
          // 'X-Title': '<YOUR_SITE_NAME>',
        },
        body: jsonEncode({
          'model': 'deepseek/deepseek-r1-0528',
          'messages': [
            {'role': 'user', 'content': message},
          ],
          'max_tokens': 512,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String?;
      } else {
        String errorMsg = 'API error: ${response.statusCode}';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['error'] != null) {
            errorMsg = data['error']['message'] ?? errorMsg;
          }
        } catch (_) {}
        print('OpenRouter API error: ${response.statusCode} ${response.body}');
        return errorMsg;
      }
    } catch (e) {
      print('OpenRouter API exception: $e');
      return 'An error occurred: $e';
    }
  }
} 