import 'dart:math';

class OrderIDGenerator {
  /// Generates a custom order ID like: tiff123456789
  /// Format: tiff + 8 random digits = 12 chars total
  static String generateOrderID() {
    final random = Random();
    final randomDigits = random.nextInt(100000000).toString().padLeft(8, '0');

    // Format: tiff + 8 digits = 12 chars
    return 'TIFF${randomDigits.substring(0, 8)}';
  }
}
