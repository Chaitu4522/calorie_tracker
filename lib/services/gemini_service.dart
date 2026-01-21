import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Result of a Gemini API calorie estimation.
class GeminiResult {
  final bool success;
  final int? calories;
  final String? errorMessage;

  GeminiResult.success(this.calories)
      : success = true,
        errorMessage = null;

  GeminiResult.error(this.errorMessage)
      : success = false,
        calories = null;
}

/// Service for interacting with Google Gemini API.
class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent';
  static const Duration _timeout = Duration(seconds: 15);

  /// Background prompt for calorie estimation.
  static const String _systemPrompt = '''
You are a nutrition assistant. Analyze the provided food image and text description to estimate total calories.

Provide ONLY a numeric calorie estimate (integer). Do not include explanations, ranges, or units. If uncertain, provide your best estimate.

Example response: 450
''';

  /// Estimate calories from an image and description.
  Future<GeminiResult> estimateCalories({
    required String apiKey,
    required File imageFile,
    required String description,
  }) async {
    try {
      // Read and encode image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Determine MIME type
      final extension = imageFile.path.split('.').last.toLowerCase();
      String mimeType;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        default:
          mimeType = 'image/jpeg';
      }

      // Build the request body
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': '$_systemPrompt\n\nUser description: $description'},
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 50,
        }
      };

      // Make API request
      final url = Uri.parse('$_baseUrl?key=$apiKey');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      // Handle response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseResponse(data);
      } else if (response.statusCode == 400) {
        return GeminiResult.error('Invalid request. Please check your API key.');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return GeminiResult.error('Invalid API key. Please update in Settings.');
      } else if (response.statusCode == 429) {
        return GeminiResult.error(
          'Rate limit exceeded. Please try again later.',
        );
      } else {
        return GeminiResult.error(
          'API error (${response.statusCode}). Please try again.',
        );
      }
    } on SocketException {
      return GeminiResult.error(
        'No internet connection. Please enter calories manually.',
      );
    } on http.ClientException {
      return GeminiResult.error(
        'Network error. Please check your connection.',
      );
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return GeminiResult.error(
          'Request timed out. Please try again.',
        );
      }
      return GeminiResult.error(
        'Unable to estimate calories. Please enter manually.',
      );
    }
  }

  /// Estimate calories from description only (no image).
  Future<GeminiResult> estimateCaloriesFromText({
    required String apiKey,
    required String description,
  }) async {
    try {
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    '$_systemPrompt\n\nUser description: $description\n\n(No image provided - estimate based on description only)'
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 50,
        }
      };

      final url = Uri.parse('$_baseUrl?key=$apiKey');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseResponse(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return GeminiResult.error('Invalid API key. Please update in Settings.');
      } else if (response.statusCode == 429) {
        return GeminiResult.error(
          'Rate limit exceeded. Please try again later.',
        );
      } else {
        return GeminiResult.error(
          'API error (${response.statusCode}). Please try again.',
        );
      }
    } on SocketException {
      return GeminiResult.error(
        'No internet connection. Please enter calories manually.',
      );
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return GeminiResult.error('Request timed out. Please try again.');
      }
      return GeminiResult.error(
        'Unable to estimate calories. Please enter manually.',
      );
    }
  }

  /// Parse the API response and extract calorie value.
  GeminiResult _parseResponse(Map<String, dynamic> data) {
    try {
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return GeminiResult.error('No response from AI. Please enter manually.');
      }

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) {
        return GeminiResult.error('Invalid response. Please enter manually.');
      }

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return GeminiResult.error('Empty response. Please enter manually.');
      }

      final text = parts[0]['text'] as String?;
      if (text == null || text.isEmpty) {
        return GeminiResult.error('Empty response. Please enter manually.');
      }

      // Extract numeric value from response
      final cleanedText = text.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanedText.isEmpty) {
        return GeminiResult.error(
          'Could not parse calorie value. Please enter manually.',
        );
      }

      final calories = int.tryParse(cleanedText);
      if (calories == null || calories < 0) {
        return GeminiResult.error(
          'Invalid calorie value. Please enter manually.',
        );
      }

      // Sanity check for reasonable calorie values
      if (calories > 10000) {
        return GeminiResult.error(
          'Estimated value seems too high. Please verify and enter manually.',
        );
      }

      return GeminiResult.success(calories);
    } catch (e) {
      return GeminiResult.error('Error parsing response. Please enter manually.');
    }
  }
}
