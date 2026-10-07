/// A utility to dynamically derive the AES Key and IV at runtime.
///
/// This avoids hardcoding a single plaintext password string, making static
/// analysis and decompilation of the API key more difficult.
class PasswordDerivation {
  /// Derives a 32-byte (256-bit) encryption key dynamically.
  static List<int> deriveKey() {
    // Two base parts from which to derive the key bytes
    const String part1 = "ArGuS_CoMmUnIcAtIoN_2026"; // 24 chars
    const String part2 = "SeCuRiTy_KeY_GeMiNi"; // 19 chars
    
    final List<int> keyBytes = [];
    for (int i = 0; i < 32; i++) {
      final int charCode1 = part1.codeUnitAt(i % part1.length);
      final int charCode2 = part2.codeUnitAt((i * 3) % part2.length);
      // XOR combination with shift index to complicate simple analysis
      keyBytes.add((charCode1 ^ charCode2 ^ (i * 7)) & 0xFF);
    }
    return keyBytes;
  }

  /// Derives a 16-byte (128-bit) Initialization Vector (IV) dynamically.
  static List<int> deriveIv() {
    const String basePart = "InItIaLiZaTiOn_VeCtOr"; // 21 chars
    
    final List<int> ivBytes = [];
    for (int i = 0; i < 16; i++) {
      final int charCode = basePart.codeUnitAt((i * 5) % basePart.length);
      // Math manipulation to derive unique bytes
      ivBytes.add((charCode ^ (i * 13)) & 0xFF);
    }
    return ivBytes;
  }
}
