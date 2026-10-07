import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'password_derivation.dart';

/// Handles the AES-256 decryption of encrypted values in memory.
class AesDecryption {
  /// Decrypts a base64 encoded ciphertext string using the runtime derived Key and IV.
  ///
  /// Returns the decrypted plaintext string, or an empty string if decryption fails.
  static String decrypt(String encryptedBase64) {
    if (encryptedBase64.trim().isEmpty) return '';

    try {
      // 1. Derive key and IV bytes at runtime
      final List<int> keyBytes = PasswordDerivation.deriveKey();
      final List<int> ivBytes = PasswordDerivation.deriveIv();

      final key = enc.Key(Uint8List.fromList(keyBytes));
      final iv = enc.IV(Uint8List.fromList(ivBytes));

      // 2. Perform AES-256-CBC decryption
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt(
        enc.Encrypted.fromBase64(encryptedBase64),
        iv: iv,
      );
      
      return decrypted.trim();
    } catch (e) {
      // Return empty in case of any failures to avoid crash
      return '';
    }
  }
}
