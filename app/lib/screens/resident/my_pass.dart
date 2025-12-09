import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/user.dart';

class MyPassScreen extends ConsumerStatefulWidget {
  const MyPassScreen({super.key});

  @override
  ConsumerState<MyPassScreen> createState() => _MyPassScreenState();
}

class _MyPassScreenState extends ConsumerState<MyPassScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _generateAuthCode(String uid) {
    final window = (DateTime.now().millisecondsSinceEpoch / 30000).floor();
    final secretKey = utf8.encode('CG_SECURE_$uid');
    final hmac = Hmac(sha256, secretKey);
    final digest = hmac.convert(utf8.encode(window.toString()));
    return 'AUTH:$uid:$digest';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authServiceProvider).currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('My Digital ID'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<AppUser?>(
        future: ref.read(firestoreServiceProvider).getUser(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Profile not found', style: TextStyle(color: Colors.white)));
          }

          final profile = snapshot.data!;
          
          // 🔴 FORCE REAL PHOTO UPLOAD - NO GENERATED AVATARS
          if (profile.photoUrl == null || profile.photoUrl!.isEmpty) {
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(32),
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.add_a_photo, size: 80, color: Colors.blueAccent),
                     const SizedBox(height: 24),
                     const Text(
                       'Photo Required',
                       style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                     ),
                     const SizedBox(height: 12),
                     const Text(
                       'Please upload your photo to access your Digital ID. This is required for security verification.',
                       textAlign: TextAlign.center,
                       style: TextStyle(color: Colors.white70),
                     ),
                     const SizedBox(height: 32),
                     ElevatedButton.icon(
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blueAccent,
                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                       ),
                       onPressed: () => _uploadPhoto(profile),
                       icon: const Icon(Icons.camera_alt),
                       label: const Text('Upload Photo'),
                     ),
                   ],
                 ),
               ),
             );
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade900, Colors.blue.shade900],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Live Indicator
                        FadeTransition(
                          opacity: _animController,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.greenAccent),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(radius: 4, backgroundColor: Colors.greenAccent),
                                SizedBox(width: 8),
                                Text('VERIFIED', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Profile Image
                        // Profile Image (Clickable)
                        GestureDetector(
                          onTap: () => _uploadPhoto(profile),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  image: DecorationImage(image: NetworkImage(profile.photoUrl!), fit: BoxFit.cover),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Name
                        Text(
                          profile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        
                        // Approved Entry Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            '✓ APPROVED ENTRY',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Resident of Building',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // QR Code with Authenticator Timer
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(milliseconds: 500), (_) => DateTime.now()),
                          builder: (context, _) {
                            final now = DateTime.now();
                            final seconds = now.second;
                            final windowProgress = (seconds % 30) / 30.0;
                            final timeLeft = 30 - (seconds % 30);
                            
                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: QrImageView(
                                    data: _generateAuthCode(profile.id),
                                    version: QrVersions.auto,
                                    size: 220.0,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: 220,
                                  child: LinearProgressIndicator(
                                    value: 1.0 - windowProgress,
                                    backgroundColor: Colors.white10,
                                    valueColor: AlwaysStoppedAnimation(
                                       timeLeft < 5 ? Colors.red : Colors.blueAccent
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Code refreshes in ${timeLeft}s',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                ),
                              ],
                            );
                          }
                        ),
                        
                        const SizedBox(height: 24),
                        const Text(
                          'Show this QR to the guard for verification',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                          textAlign: TextAlign.center,
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// 📸 Upload Real Photo - NO GENERATED AVATARS
  Future<void> _uploadPhoto(AppUser profile) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Show options: Camera or Gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Upload Photo'),
          content: const Text('Choose photo source:'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(ctx, ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
          ],
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      // 🛑 LIMITATION: Check File Size (Max 2MB)
      final sizeBytes = await image.length();
      if (sizeBytes > 2 * 1024 * 1024) { // 2MB
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Image too large. Max size is 2MB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading
      if (!mounted) return;
      // ignore: unawaited_futures
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Upload to Supabase Storage
      final photoUrl = await ref.read(storageServiceProvider).uploadProfilePhoto(
        userId: profile.id,
        imagePath: image.path,
      );

      // Update profile
      await ref.read(firestoreServiceProvider).updateUserPhoto(profile.id, photoUrl);

      if (mounted) {
        Navigator.pop(context); // Close loading
        setState(() {}); // Refresh
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to upload photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
