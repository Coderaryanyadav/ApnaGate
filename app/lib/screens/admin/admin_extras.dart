import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/complaint.dart';
import '../../models/service_provider.dart';
import '../../services/firestore_service.dart';

class ComplaintAdminScreen extends ConsumerStatefulWidget {
  const ComplaintAdminScreen({super.key});

  @override
  ConsumerState<ComplaintAdminScreen> createState() => _ComplaintAdminScreenState();
}

class _ComplaintAdminScreenState extends ConsumerState<ComplaintAdminScreen> {
  late Future<List<Complaint>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _complaintsFuture = ref.read(firestoreServiceProvider).getComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Complaints'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<Complaint>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No active complaints.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = list[index];
              return Card(
                child: ListTile(
                  title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(c.description),
                  trailing: Chip(label: Text(c.status.toUpperCase(), style: const TextStyle(fontSize: 10))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ServiceProviderAdminScreen extends ConsumerStatefulWidget {
  const ServiceProviderAdminScreen({super.key});

  @override
  ConsumerState<ServiceProviderAdminScreen> createState() => _ServiceProviderAdminScreenState();
}

class _ServiceProviderAdminScreenState extends ConsumerState<ServiceProviderAdminScreen> {
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _addProvider() async {
    final name = _nameController.text.trim();
    final cat = _categoryController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || cat.isEmpty) return;

    final sp = ServiceProvider(
      id: const Uuid().v4(),
      name: name,
      category: cat,
      phone: phone,
      createdAt: DateTime.now(),
    );

    debugPrint('Adding service provider: ${sp.name}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $name ($cat)')));
      Navigator.pop(context);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Providers Directory')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00E5FF),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Add Service Provider'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 8),
                  TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category (e.g. Electrician)')),
                  const SizedBox(height: 8),
                  TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
                ElevatedButton(onPressed: _addProvider, child: const Text('SAVE')),
              ],
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: FutureBuilder<List<ServiceProvider>>(
        future: ref.read(firestoreServiceProvider).getServiceProviders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No service providers added yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final sp = list[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.engineering, color: Color(0xFF00E5FF)),
                  title: Text(sp.name),
                  subtitle: Text('${sp.category} • ${sp.phone}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
