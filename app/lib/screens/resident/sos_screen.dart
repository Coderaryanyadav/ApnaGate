import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

// Make sure to add vibration: ^1.8.4 to pubspec.yaml if not already there, 
// or I will just skip vibration import if I see it's missing from my plan.
// Actually I didn't add vibration to pubspec. Let's just remove the import for now or use system sound if possible.
// Wait, I can simulate SOS UI without vibration for now or rely on just visual/network.

class SOSScreen extends ConsumerStatefulWidget {
  const SOSScreen({super.key});

  @override
  ConsumerState<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends ConsumerState<SOSScreen> {
  Future<void> _sendSOS() async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      // We need to fetch the user's flat number details first actually
      final firestore = ref.read(firestoreServiceProvider);
      final appUser = await firestore.getUser(user.uid);
      
      if (appUser?.flatNumber == null) {
        throw Exception('Flat number not found');
      }

      await firestore.sendSOS(user.uid, appUser!.flatNumber!);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('SOS SENT'),
            content: const Text('Guards and Admin have been alerted!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending SOS: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'EMERGENCY',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.red),
          ),
          const SizedBox(height: 16),
          const Text(
            'Press and hold to alert security',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onLongPress: _sendSOS,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_active,
                size: 80,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
