import 'dart:convert';
import 'package:http/http.dart' as http;

class AIChatService {
  static String? _apiKey;
  static String? _modelUrl;
  static void setApiKey(String key) => _apiKey = key;
  static void setModelUrl(String url) => _modelUrl = url.trim();
  static String get apiKey => _apiKey ?? '';
  static String get modelUrl => _modelUrl ?? '';

  static Future<String?> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(modelUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': message}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('generated_text')) {
          return data['generated_text'];
        } else if (data is List && data.isNotEmpty && data[0]['generated_text'] != null) {
          return data[0]['generated_text'];
        }
        return data.toString();
      } else {
        print('Hugging Face API error: ${response.statusCode} ${response.body}');
        if (response.headers['content-type']?.contains('text/html') ?? false) {
          return 'Error: Received HTML response. Check your API key and model URL.';
        }
        return 'Error: ${response.body}';
      }
    } catch (e) {
      return 'An error occurred: $e';
    }
  }
} 