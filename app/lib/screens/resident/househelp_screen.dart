import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/daily_help.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class HousehelpScreen extends ConsumerStatefulWidget {
  const HousehelpScreen({super.key});

  @override
  ConsumerState<HousehelpScreen> createState() => _HousehelpScreenState();
}

class _HousehelpScreenState extends ConsumerState<HousehelpScreen> {
  late Future<List<DailyHelp>> _helpFuture;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authServiceProvider).currentUser;
    _helpFuture = user != null
        ? ref.read(firestoreServiceProvider).getDailyHelp(ownerId: user.id)
        : Future.value([]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Help & Staff')),
      body: FutureBuilder<List<DailyHelp>>(
        future: _helpFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No daily staff assigned to your flat.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = list[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.isInside ? Colors.green.withAlpha(50) : Colors.grey.withAlpha(50),
                    child: Icon(Icons.cleaning_services, color: item.isInside ? Colors.greenAccent : Colors.white60),
                  ),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${item.role} • ${item.phone ?? "No contact"}'),
                  trailing: Chip(
                    label: Text(item.isInside ? 'INSIDE' : 'OUTSIDE', style: const TextStyle(fontSize: 10)),
                    backgroundColor: item.isInside ? Colors.green.withAlpha(40) : Colors.grey.withAlpha(40),
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
