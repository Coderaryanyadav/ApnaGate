import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/guest_pass.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class MyPassScreen extends ConsumerStatefulWidget {
  const MyPassScreen({super.key});

  @override
  ConsumerState<MyPassScreen> createState() => _MyPassScreenState();
}

class _MyPassScreenState extends ConsumerState<MyPassScreen> {
  late Future<List<GuestPass>> _passesFuture;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authServiceProvider).currentUser;
    _passesFuture = user != null
        ? ref.read(firestoreServiceProvider).getGuestPasses(user.id)
        : Future.value([]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Active Passes')),
      body: FutureBuilder<List<GuestPass>>(
        future: _passesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final passes = snapshot.data ?? [];
          if (passes.isEmpty) {
            return const Center(child: Text('No active guest passes created.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: passes.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pass = passes[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      QrImageView(
                        data: pass.passCode,
                        version: QrVersions.auto,
                        size: 80.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pass.guestName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Pass Code: ${pass.passCode}', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Status: ${pass.status.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
