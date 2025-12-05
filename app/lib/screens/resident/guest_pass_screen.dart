import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/guest_pass.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class GuestPassScreen extends ConsumerStatefulWidget {
  const GuestPassScreen({super.key});

  @override
  ConsumerState<GuestPassScreen> createState() => _GuestPassScreenState();
}

class _GuestPassScreenState extends ConsumerState<GuestPassScreen> {
  GuestPass? _currentPass;
  bool _isLoading = false;

  Future<void> _generatePass() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final pass = GuestPass(
        id: const Uuid().v4(),
        residentId: user.uid,
        visitorName: 'Guest', // Could ask user for name
        validUntil: DateTime.now().add(const Duration(hours: 24)),
        token: const Uuid().v4(), // Secure random token
        isUsed: false,
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).createGuestPass(pass);
      setState(() => _currentPass = pass);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentPass != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: QrImageView(
                      data: _currentPass!.token,
                      version: QrVersions.auto,
                      size: 250,
                    ),
                   ),
                  const SizedBox(height: 16),
                  const Text(
                    'Entry Pass',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Valid until: ${_currentPass!.validUntil.hour}:${_currentPass!.validUntil.minute}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ] else ...[
             const Icon(Icons.qr_code_2, size: 100, color: Colors.blue),
             const SizedBox(height: 24),
             const Text(
               'Generate a digital pass for your guests',
               textAlign: TextAlign.center,
               style: TextStyle(fontSize: 18, color: Colors.grey),
             ),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _generatePass,
              icon: const Icon(Icons.add),
              label: Text(_isLoading ? 'Generating...' : 'GENERATE NEW PASS'),
            ),
          ),
        ],
      ),
    );
  }
}
