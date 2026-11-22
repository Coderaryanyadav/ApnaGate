import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/complaint.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ComplaintListScreen extends ConsumerStatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  ConsumerState<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends ConsumerState<ComplaintListScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty || desc.isEmpty) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final complaint = Complaint(
      id: const Uuid().v4(),
      residentId: user.id,
      title: title,
      description: desc,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await ref.read(firestoreServiceProvider).createComplaint(complaint);
    _titleController.clear();
    _descController.clear();
    setState(() {});
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint submitted!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance & Complaints')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00E5FF),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF131B2A),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('File Complaint', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Issue Title')),
                  const SizedBox(height: 12),
                  TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _submitComplaint, child: const Text('SUBMIT')),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : FutureBuilder<List<Complaint>>(
              future: ref.read(firestoreServiceProvider).getComplaints(residentId: user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Center(child: Text('No complaints logged.'));
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
                        trailing: Chip(
                          label: Text(c.status.toUpperCase(), style: const TextStyle(fontSize: 10)),
                          backgroundColor: c.status == 'resolved' ? Colors.green.withAlpha(40) : Colors.orange.withAlpha(40),
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
