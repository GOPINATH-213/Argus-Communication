// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;

// Note: These derivation methods MUST be identical to the ones inside
// lib/core/security/password_derivation.dart to ensure correct decryption.

List<int> deriveKey() {
  const String part1 = "ArGuS_CoMmUnIcAtIoN_2026";
  const String part2 = "SeCuRiTy_KeY_GeMiNi";
  
  final List<int> keyBytes = [];
  for (int i = 0; i < 32; i++) {
    final int charCode1 = part1.codeUnitAt(i % part1.length);
    final int charCode2 = part2.codeUnitAt((i * 3) % part2.length);
    keyBytes.add((charCode1 ^ charCode2 ^ (i * 7)) & 0xFF);
  }
  return keyBytes;
}

List<int> deriveIv() {
  const String basePart = "InItIaLiZaTiOn_VeCtOr";
  
  final List<int> ivBytes = [];
  for (int i = 0; i < 16; i++) {
    final int charCode = basePart.codeUnitAt((i * 5) % basePart.length);
    ivBytes.add((charCode ^ (i * 13)) & 0xFF);
  }
  return ivBytes;
}

void main(List<String> args) {
  if (args.isEmpty) {
    print("Error: Gemini API key argument is missing.");
    print("Usage: dart run bin/encrypt_key.dart <YOUR_GEMINI_API_KEY>");
    exit(1);
  }

  final String plaintextKey = args[0].trim();
  if (plaintextKey.isEmpty) {
    print("Error: API key cannot be empty.");
    exit(1);
  }

  try {
    // 1. Derive key/IV bytes using identical runtime logic
    final keyBytes = deriveKey();
    final ivBytes = deriveIv();

    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV(Uint8List.fromList(ivBytes));

    // 2. Perform AES-256-CBC encryption
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintextKey, iv: iv);
    final String base64Cipher = encrypted.base64;

    // 3. Split the base64 ciphertext into 3 segments
    final int len = base64Cipher.length;
    final int segmentSize = (len / 3).ceil();

    final String part1 = base64Cipher.substring(0, segmentSize);
    final String part2 = base64Cipher.substring(segmentSize, segmentSize * 2);
    final String part3 = base64Cipher.substring(segmentSize * 2);

    print("\n================ ENCRYPTION SUCCESSFUL ================");
    print("Replace the contents of: lib/core/security/encrypted_parts.dart");
    print("with the following code blocks:");
    print("=======================================================\n");

    print("class EncryptedParts {");
    print("  static const String part1 = '$part1';");
    print("  static const String part2 = '$part2';");
    print("  static const String part3 = '$part3';");
    print("");
    print("  static String getCombinedString() {");
    print("    return part1 + part2 + part3;");
    print("  }");
    print("}");
    print("\n=======================================================\n");
  } catch (e) {
    print("Error during encryption: $e");
    exit(1);
  }
}
