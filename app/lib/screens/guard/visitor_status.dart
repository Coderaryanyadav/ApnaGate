import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/visitor.dart';
import '../../services/firestore_service.dart';

class VisitorStatusScreen extends ConsumerStatefulWidget {
  const VisitorStatusScreen({super.key});

  @override
  ConsumerState<VisitorStatusScreen> createState() => _VisitorStatusScreenState();
}

class _VisitorStatusScreenState extends ConsumerState<VisitorStatusScreen> {
  late Future<List<Visitor>> _visitorsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _visitorsFuture = ref.read(firestoreServiceProvider).getVisitors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitor Status Logs'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<Visitor>>(
        future: _visitorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final visitors = snapshot.data ?? [];
          if (visitors.isEmpty) {
            return const Center(child: Text('No visitor records found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: visitors.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final visitor = visitors[index];
              Color statusColor;
              switch (visitor.status) {
                case 'approved':
                  statusColor = Colors.greenAccent;
                  break;
                case 'rejected':
                  statusColor = Colors.redAccent;
                  break;
                case 'completed':
                  statusColor = Colors.grey;
                  break;
                default:
                  statusColor = Colors.orangeAccent;
              }

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withAlpha(50),
                    child: Icon(Icons.person, color: statusColor),
                  ),
                  title: Text(visitor.visitorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Flat ${visitor.wing}-${visitor.flatNumber} • ${visitor.purpose}'),
                  trailing: Chip(
                    label: Text(visitor.status.toUpperCase(), style: const TextStyle(fontSize: 10)),
                    backgroundColor: statusColor.withAlpha(30),
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
