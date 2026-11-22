import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../../models/guest_pass.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class GuestPassScreen extends ConsumerStatefulWidget {
  const GuestPassScreen({super.key});

  @override
  ConsumerState<GuestPassScreen> createState() => _GuestPassScreenState();
}

class _GuestPassScreenState extends ConsumerState<GuestPassScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createPass() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isGenerating = true);

    try {
      final code = (100000 + Random().nextInt(900000)).toString();
      final pass = GuestPass(
        id: const Uuid().v4(),
        residentId: user.id,
        guestName: name,
        guestPhone: _phoneController.text.trim(),
        passCode: code,
        validFrom: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 1)),
        status: 'active',
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).createGuestPass(pass);

      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pass Created 🎉'),
            content: Text('Guest Pass Code: $code\nShare this code with $name for seamless gate check-in.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('DONE'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Guest Pass')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Guest Full Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Guest Phone (Optional)'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isGenerating ? null : _createPass,
              child: _isGenerating
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('GENERATE PASS CODE'),
            ),
          ],
        ),
      ),
    );
  }
}
