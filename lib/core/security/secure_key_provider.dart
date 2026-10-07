import 'encrypted_parts.dart';
import 'aes_decryption.dart';

/// Provides the decrypted Gemini API Key only in memory.
///
/// Decrypts the key on demand and caches it to prevent repetitive decryption work.
/// It never writes the decrypted key to local storage or logs.
class SecureKeyProvider {
  static String? _cachedKey;

  /// Decrypts and returns the Gemini API key.
  ///
  /// Caches the key in an in-memory variable for fast subsequent access.
  static String getGeminiApiKey() {
    if (_cachedKey != null) {
      return _cachedKey!;
    }

    // 1. Combine the split encrypted parts
    final String combinedCiphertext = EncryptedParts.getCombinedString();

    // 2. Decrypt in memory
    _cachedKey = AesDecryption.decrypt(combinedCiphertext);

    return _cachedKey!;
  }
}
