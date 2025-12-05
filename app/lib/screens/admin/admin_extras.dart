import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/extras.dart';
import '../../services/firestore_service.dart';

// --- COMPLAINTS ADMIN ---
class ComplaintAdminScreen extends ConsumerWidget {
  const ComplaintAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Complaints')),
      body: StreamBuilder<List<Complaint>>(
        stream: ref.watch(firestoreServiceProvider).getAllComplaints(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final complaints = snapshot.data!;
          
          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final c = complaints[index];
              return Card(
                child: ListTile(
                  title: Text(c.title),
                  subtitle: Text("${c.flatNumber} • ${c.status}"),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) => ref.read(firestoreServiceProvider).updateComplaintStatus(c.id, val),
                    itemBuilder: (_) => ['open', 'in_progress', 'resolved'].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
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

// --- SERVICE ADMIN ---
class ServiceAdminScreen extends ConsumerWidget {
  const ServiceAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Services')),
      body: StreamBuilder<List<ServiceProvider>>(
        stream: ref.watch(firestoreServiceProvider).getServiceProviders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final providers = snapshot.data!;
          
          return ListView.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final p = providers[index];
              return ListTile(
                title: Text(p.name),
                subtitle: Text("${p.category} • ${p.phone}"),
                leading: const Icon(Icons.handyman),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddDialog(context, ref),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category (Plumber etc)')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await ref.read(firestoreServiceProvider).addServiceProvider(ServiceProvider(
                id: '',
                name: nameCtrl.text,
                category: catCtrl.text,
                phone: phoneCtrl.text,
              ));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }
}
