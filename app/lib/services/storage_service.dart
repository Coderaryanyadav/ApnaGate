import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  StorageService();

  /// Converts an image file to a Base64 string with compression.
  /// Returns null if processing fails.
  Future<String?> uploadVisitorPhoto(File photoFile) async {
    try {
      // 1. Read bytes
      final bytes = await photoFile.readAsBytes();

      // 2. Decode image
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // 3. Resize (Limit width to 600px to save space)
      final resized = img.copyResize(image, width: 600);

      // 4. Compress to JPEG (Quality 60%)
      final compressedBytes = img.encodeJpg(resized, quality: 60);

      // 5. Convert to Base64
      final base64String = base64Encode(compressedBytes);

      return base64String;
    } catch (e) {
      // debugPrint('Error compressing image: $e');
      rethrow;
    }
  }
}
