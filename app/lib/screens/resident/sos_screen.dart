import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../utils/sos_rate_limiter.dart';
import '../../utils/haptic_helper.dart';

import '../../utils/app_constants.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  bool _isSending = false;

  Future<void> _sendSOS() async {
    // Check rate limit
    final canSend = await SOSRateLimiter.canSendSOS();
    if (!canSend) {
      final remaining = await SOSRateLimiter.getRemainingCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please wait $remaining minutes before sending another SOS'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show confirmation
    if (mounted) {
      final confirmed = await ConfirmationDialog.confirmSOS(context: context);
      if (!confirmed) return;
    }

    setState(() => _isSending = true);

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
        setState(() => _isSending = false);
        return;
    }

    try {
      // Fetch user profile for details
      final appUser = await ref.read(firestoreServiceProvider).getUser(user.id);
      
      if (appUser == null) throw Exception('User profile not found');

      // 1. Send to Firestore
      await ref.read(firestoreServiceProvider).sendSOS(wing: appUser.wing);

      // 2. Push Notification
      // 2. Push Notification (Guards + Admins)
      await ref.read(notificationServiceProvider).notifySOSAlert(
        wing: appUser.wing ?? 'Unknown',
        flatNumber: appUser.flatNumber ?? '000',
        residentName: appUser.name,
      );
      
      if (mounted) {
        // Success vibration
        HapticHelper.heavyImpact();
        
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: AppConstants.spacing8),
                Text('🚨 SOS SENT'),
              ],
            ),
            content: const Text('Guards and Admin have been alerted!\nHelp is on the way.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error sending SOS: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme
      appBar: AppBar(title: const Text('SOS Alert'), backgroundColor: Colors.transparent),
      body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🚨 EMERGENCY',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.red),
          ),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            _isSending ? 'Sending alert...' : 'Press and hold to alert security',
            style: TextStyle(
              fontSize: 16,
              color: _isSending ? Colors.orange : Colors.grey,
              fontWeight: _isSending ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: AppConstants.spacing48),
          GestureDetector(
            onLongPress: _isSending ? null : _sendSOS,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSending ? Colors.orange.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                border: Border.all(
                  color: _isSending ? Colors.orange : Colors.red,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isSending ? Colors.orange : Colors.red).withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                _isSending ? Icons.radio_button_checked : Icons.notifications_active,
                size: 80,
                color: _isSending ? Colors.orange : Colors.red,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
