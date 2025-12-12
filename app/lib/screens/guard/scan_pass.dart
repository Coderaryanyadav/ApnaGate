import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/user.dart';
import '../../utils/haptic_helper.dart';
import 'package:otp/otp.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanPassScreen extends ConsumerStatefulWidget {
  const ScanPassScreen({super.key});

  @override
  ConsumerState<ScanPassScreen> createState() => _ScanPassScreenState();
}

class _ScanPassScreenState extends ConsumerState<ScanPassScreen> with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _syncOfflineData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _syncOfflineData() async {
     final box = Hive.box('user_cache');
    
     // 1. Secrets (For Verification)
     try {
       final res = await Supabase.instance.client.from('identity_secrets').select('id, secret');
       final Map<String, dynamic> secrets = {};
       for (final row in res) {
         secrets[row['id']] = row['secret'];
       }
       await box.put('guard_secrets_cache', secrets);
       debugPrint('✅ Synced ${res.length} secrets');
     } catch (e) {
       debugPrint('Secrets Sync Fail: $e');
     }

     // 2. Profiles (For Display)
     try {
       final res = await Supabase.instance.client.from('profiles').select();
       final Map<String, dynamic> profiles = {};
       for (final row in res) {
         profiles[row['id']] = row;
       }
       await box.put('guard_profiles_cache', profiles);
       debugPrint('✅ Synced ${res.length} profiles');
     } catch (e) {
       debugPrint('Profiles Sync Fail: $e');
     }
  }

  Future<AppUser?> _getUserOffline(String uid) async {
     try {
       // Online First
       return await ref.read(firestoreServiceProvider).getUser(uid);
     } catch (e) {
       // Offline Fallback
       final box = Hive.box('user_cache');
       final cacheMap = box.get('guard_profiles_cache');
       if (cacheMap != null && cacheMap is Map && cacheMap.containsKey(uid)) {
          final data = Map<String, dynamic>.from(cacheMap[uid]);
          return AppUser.fromMap(data, uid);
       }
     }
     return null;
  }

  Future<bool> _verifyTOTP(String uid, String code) async {
    final box = Hive.box('user_cache');
    String? secret;

    // 1. Try Cache
    final cacheMap = box.get('guard_secrets_cache');
    if (cacheMap != null && cacheMap is Map) {
       secret = cacheMap[uid];
    }
    
    // 2. Try Online if missing
    if (secret == null) {
       try {
         final res = await Supabase.instance.client
           .from('identity_secrets')
           .select('secret')
           .eq('id', uid)
           .maybeSingle();
         if (res != null) secret = res['secret'];
       } catch (e) {
         debugPrint('Online secret fetch failed: $e');
       }
    }
    
    if (secret == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final validCode = OTP.generateTOTPCodeString(secret, now, length: 6, interval: 30);
    final validCodePrev = OTP.generateTOTPCodeString(secret, now - 30000, length: 6, interval: 30);
    
    return (code == validCode || code == validCodePrev);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    try {
      final firestore = ref.read(firestoreServiceProvider);
      final scanData = code.trim();

      // 1. Try Guest Pass First
      final pass = await firestore.getGuestPassByToken(scanData);

      if (pass != null) {
        // --- GUEST PASS LOGIC ---
        if (pass.isUsed) {
          HapticHelper.heavyImpact();
          _showResult(false, 'Pass already used', '', guestCount: pass.guestCount);
          return;
        }

        if (pass.validUntil.isBefore(DateTime.now())) {
          HapticHelper.heavyImpact();
          _showResult(false, 'Pass expired', '', guestCount: pass.guestCount);
          return;
        }

        HapticHelper.mediumImpact();
        
        String flatInfo = 'Unknown Flat';
        if (pass.flatNumber != null) {
          flatInfo = '${pass.wing ?? ''}-${pass.flatNumber}';
        }

        // SHOW DIALOG FIRST (Verify Details)
        if (!mounted) return;
        _showPremiumDialog(
          isSuccess: true,
          title: 'VERIFY GUEST',
          message: 'Valid Guest Pass Found',
          visitorName: pass.visitorName,
          flatInfo: flatInfo,
          isGuest: true,
          guestCount: pass.guestCount,
          additionalInfo: pass.additionalInfo,
          onConfirm: () async {
             // MARK USED ONLY ON CONFIRMATION
             await firestore.markGuestPassUsed(pass.id);
             
             // Unblock UI: Send Notification asynchronously (Fire & Forget)
             final notificationService = ref.read(notificationServiceProvider);
             notificationService.notifyFlat(
                wing: pass.wing ?? '',
                flatNumber: pass.flatNumber ?? '',
                title: 'Guest Arrived',
                message: '${pass.visitorName} (${pass.guestCount} ${pass.guestCount == 1 ? "person" : "people"}) has entered.',
                visitorId: pass.id,
             ).onError((error, stackTrace) {
                debugPrint('❌ Notify Error: $error');
             });

             if (mounted) Navigator.pop(context); // Close dialog IMMEDIATELY
             // 🔄 Reset Processing Flag to allow next scan
             if (mounted) setState(() => _isProcessing = false);
          }
        );
        return;
      }

      // 2. Try Resident ID (If not guest pass)
      String userIdToFetch = scanData;
      
      // Handle Digital ID Format: TOTP (UID|CODE) or Legacy (AUTH:UID:HMAC)
      if (scanData.contains('|')) {
         final parts = scanData.split('|');
         if (parts.length == 2) {
            final uid = parts[0];
            final code = parts[1];
            
            // 🔐 OKAY TO VERIFY OFFLINE
            final isValid = await _verifyTOTP(uid, code);
            
            if (!isValid) {
               HapticHelper.heavyImpact();
               if (mounted) _showResult(false, 'Invalid/Expired Code', 'Please ask resident to refresh QR');
               // NOTE: _showResult resets _isProcessing via its onConfirm
               return;
            }
            
            // Valid! Proceed to fetch user details (Offline capable if profile cached?)
            userIdToFetch = uid;
         }
      } 
      else if (scanData.startsWith('AUTH:')) {
        final parts = scanData.split(':');
        if (parts.length >= 2) {
          userIdToFetch = parts[1];
        }
      }

      final AppUser? user = await _getUserOffline(userIdToFetch);

      if (user != null && user.role == 'resident') {
        // --- RESIDENT VERIFICATION LOGIC ---
        HapticHelper.mediumImpact();

        if (!mounted) return;
        _showPremiumDialog(
          isSuccess: true,
          title: 'RESIDENT VERIFIED',
          message: 'Access Granted',
          visitorName: '', // Hidden for privacy
          flatInfo: '',    // Hidden for privacy
          photoUrl: user.photoUrl,
          isGuest: false,
          onConfirm: () {
             Navigator.pop(context);
             // 🔄 Reset Processing Flag
             if (mounted) setState(() => _isProcessing = false);
          }, 
        );
        return;
      }

      // 3. Try Staff ID (STAFF:ID)
      if (scanData.startsWith('STAFF:')) {
         final staffId = scanData.split(':')[1];
         // Fetch Staff From Firestore
         // Note: We access 'daily_help' via a helper in FirestoreService but need a method
         // to get ANY staff (Guard Permission). RLS allows guard to read all.
         
         final staff = await firestore.getHousehelpById(staffId);
         
         if (staff != null) {
           HapticHelper.mediumImpact();
           
           if (!mounted) return;
           
           final bool isInside = staff['is_present'] == true;
           
           _showPremiumDialog(
             isSuccess: true,
             title: isInside ? 'STAFF EXIT?' : 'STAFF ENTRY',
             message: isInside ? 'Mark ${staff['name']} as Exited?' : 'Mark ${staff['name']} as Present?',
             visitorName: staff['name'],
             flatInfo: staff['role'].toString().toUpperCase(),
             photoUrl: staff['photo_url'],
             isGuest: false,
             additionalInfo: 'Current Status: ${isInside ? "INSIDE" : "OUTSIDE"}',
           onConfirm: () async {
               // Toggle Attendance
               await firestore.toggleStaffAttendance(staffId, staff['owner_id'], !isInside);
               
               // 🔔 Silent Notification to Owner
               try {
                  final notificationService = ref.read(notificationServiceProvider);
                  await notificationService.notifyUser(
                    userId: staff['owner_id'],
                    title: isInside ? 'Househelp Left' : 'Househelp Arrived', 
                    message: '${staff['name']} has ${isInside ? 'left' : 'entered'} the society.',
                    data: {'type': 'staff_attendance', 'staff_id': staffId},
                  );
               } catch (e) {
                 debugPrint('Notify Error: $e');
               }

               if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('✅ Marked ${isInside ? "Exit" : "Entry"} for ${staff['name']}'))
                  );
                  // 🔄 Reset Processing Flag
                  setState(() => _isProcessing = false);
               }
             }
           );
           return;
         }
      }

      // 4. Invalid
      HapticHelper.heavyImpact(); 
      _showResult(false, 'Invalid ID or Token', '');

    } catch (e) {
      if (mounted) {
        debugPrint('Scan Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
         setState(() => _isProcessing = false);
      }
    }
  }

  void _showResult(bool isValid, String message, String visitor, {int? guestCount}) {
    _showPremiumDialog(
      isSuccess: false,
      title: 'ACCESS DENIED',
      message: message,
      visitorName: visitor,
      flatInfo: '',
      guestCount: guestCount ?? 1,
      onConfirm: () => setState(() => _isProcessing = false),
    );
  }

  void _showPremiumDialog({
    required bool isSuccess,
    required String title,
    required String message,
    required String visitorName,
    required String flatInfo,
    String? photoUrl,
    bool isGuest = true,
    int guestCount = 1,
    String? additionalInfo,
    required VoidCallback onConfirm,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: title,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, anim1, anim2) => Container(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.elasticOut),
          child: FadeTransition(
            opacity: anim1,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSuccess ? (isGuest ? Colors.greenAccent : Colors.cyanAccent) : Colors.redAccent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isSuccess ? (isGuest ? Colors.greenAccent : Colors.cyanAccent) : Colors.redAccent).withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon or Photo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: (isSuccess ? (isGuest ? Colors.green : Colors.cyan) : Colors.red).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSuccess ? (isGuest ? Colors.greenAccent : Colors.cyanAccent) : Colors.redAccent,
                            width: 2
                          ),
                          image: photoUrl != null && photoUrl.isNotEmpty
                              ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: photoUrl == null || photoUrl.isEmpty
                          ? Icon(
                              isSuccess ? (isGuest ? Icons.check_circle : Icons.verified_user) : Icons.error,
                              color: isSuccess ? (isGuest ? Colors.greenAccent : Colors.cyanAccent) : Colors.redAccent,
                              size: 50,
                            )
                          : null,
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          color: isSuccess ? (isGuest ? Colors.greenAccent : Colors.cyanAccent) : Colors.redAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 24),

                      if (visitorName.isNotEmpty) ...[
                        _buildDetailRow(isGuest ? 'VISITOR' : 'RESIDENT', visitorName, Icons.person),
                        const SizedBox(height: 16),
                      ],
                      
                      if (flatInfo.isNotEmpty) ...[
                        _buildDetailRow(isGuest ? 'VISITING' : 'RESIDES AT', flatInfo, Icons.home),
                        const SizedBox(height: 16),
                      ],
                      
                      if (isGuest) ...[
                         _buildDetailRow('GUESTS COUNT', '$guestCount Person(s)', Icons.group),
                         const SizedBox(height: 16),
                      ],

                      if (additionalInfo != null && additionalInfo.isNotEmpty) ...[
                         _buildDetailRow('NOTE', additionalInfo, Icons.note),
                         const SizedBox(height: 16),
                      ],

                      if (isSuccess)
                        _buildDetailRow('TIME', DateFormat('hh:mm a').format(DateTime.now()), Icons.access_time),

                      const SizedBox(height: 32),
                      
                      // Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSuccess ? (isGuest ? Colors.greenAccent : Colors.cyanAccent) : Colors.redAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (!isSuccess) {
                               Navigator.of(ctx).pop();
                               onConfirm(); // This resets _isProcessing
                            } else {
                               // For success, just run the confirm action (which marks as used & pops)
                               // Note: The parent passed a callback that handles logic.
                               // Use the callback directly.
                               onConfirm();
                            }
                          },
                          child: Text(
                            isSuccess ? (isGuest ? 'APPROVE ENTRY & NOTIFY' : 'VERIFIED - CLOSE') : 'TRY AGAIN',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Scan Guest Pass'), backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          
          // Dark Overlay with Cutout effect (Simulated)
          ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.srcOut),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: 260,
                    width: 260,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Border & Animation
          Center(
            child: Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.3), blurRadius: 20)
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Positioned(
                          top: 260 * _controller.value,
                          left: 0, 
                          right: 0,
                          child: Container(
                            height: 2, 
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const Positioned(
            bottom: 80, left: 0, right: 0,
            child: Text(
              'Align QR code within the frame', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
