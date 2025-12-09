import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  final _supabase = Supabase.instance.client;

  /// Upload profile photo to Supabase Storage
  /// Returns the public URL of the uploaded photo
  Future<String> uploadProfilePhoto({
    required String userId,
    required String imagePath,
  }) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      
      // Decode and compress image
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');
      
      // Resize to 800x800 max
      final resized = img.copyResize(image, width: 800, height: 800);
      final compressedBytes = img.encodeJpg(resized, quality: 85);
      
      // Upload to Supabase Storage
      final fileName = 'profile_$userId.jpg';
      await _supabase.storage
          .from('profiles')
          .uploadBinary(
            fileName,
            compressedBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );
      
      // Get public URL
      final publicUrl = _supabase.storage
          .from('profiles')
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Converts an image file to a Base64 string with compression.
  /// Returns null if processing fails.
  Future<String?> uploadVisitorPhoto(File file) async {
    return _uploadImage(file, 'visitors');
  }

  Future<String?> uploadComplaintImage(File file) async {
    return _uploadImage(file, 'complaints');
  }

  Future<String?> _uploadImage(File file, String folder) async {
    try {
      // 1. Read bytes
      final bytes = await file.readAsBytes();

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
