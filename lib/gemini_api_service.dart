import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiApiService {
  final String apiKey = "AIzaSyBxeb7jk9uG03_TI9oisT0Lw6L_wkh_AL0fdfdfvdsv"; // Replace with your API key
  final String endpoint =
       "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";
  Future<String> getGeminiResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return text; // Return the response from Gemini
      } else {
        return "Error: ${response.statusCode} ${response.reasonPhrase}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
