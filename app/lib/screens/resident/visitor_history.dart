import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/visitor.dart';
import '../../services/firestore_service.dart';

class VisitorHistoryScreen extends ConsumerStatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  ConsumerState<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends ConsumerState<VisitorHistoryScreen> {
  late Future<List<Visitor>> _visitorsFuture;

  @override
  void initState() {
    super.initState();
    _visitorsFuture = ref.read(firestoreServiceProvider).getVisitors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visitor History')),
      body: FutureBuilder<List<Visitor>>(
        future: _visitorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final visitors = snapshot.data ?? [];
          if (visitors.isEmpty) {
            return const Center(child: Text('No visitor records.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: visitors.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final v = visitors[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: Text(v.visitorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${v.purpose} • Flat ${v.wing}-${v.flatNumber}'),
                  trailing: Text(
                    v.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: v.status == 'approved' ? Colors.greenAccent : Colors.white60,
                    ),
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
