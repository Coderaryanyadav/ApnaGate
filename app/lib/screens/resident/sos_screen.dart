import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/sos_alert.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  bool _isSending = false;

  Future<void> _triggerSos() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final profile = await ref.read(firestoreServiceProvider).getUser(user.id);
    if (profile == null) return;

    setState(() => _isSending = true);

    try {
      final sos = SosAlert(
        id: const Uuid().v4(),
        residentId: user.id,
        wing: profile.wing ?? 'A',
        flatNumber: profile.flatNumber ?? '000',
        status: 'active',
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).triggerSosAlert(sos);

      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🚨 SOS ALERT BROADCASTED', style: TextStyle(color: Colors.redAccent)),
            content: const Text('Guards and security checkpoints have been notified with high-priority sirens.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error triggering SOS: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency SOS')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield, size: 80, color: Colors.redAccent),
              const SizedBox(height: 20),
              const Text(
                'EMERGENCY ASSISTANCE',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hold or press the button below to send an emergency alert with your flat location to all on-duty security guards.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _isSending ? null : _triggerSos,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Colors.redAccent, Colors.red],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withAlpha(120),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
