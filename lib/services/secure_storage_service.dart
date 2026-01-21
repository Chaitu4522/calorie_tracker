import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure storage of sensitive data (API key).
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static const String _apiKeyKey = 'gemini_api_key';

  /// Save the Gemini API key.
  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(key: _apiKeyKey, value: apiKey);
  }

  /// Get the stored API key.
  Future<String?> getApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }

  /// Check if API key exists.
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Delete the API key.
  Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyKey);
  }

  /// Delete all secure storage data.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
