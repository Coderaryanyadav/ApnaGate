import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/extras.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ComplaintListScreen extends ConsumerWidget {
  const ComplaintListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      body: StreamBuilder<List<Complaint>>(
        stream: ref.watch(firestoreServiceProvider).getUserComplaints(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final complaints = snapshot.data!;

          if (complaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.thumb_up_alt_outlined, size: 60, color: Colors.indigo.shade100),
                  const SizedBox(height: 16),
                  Text('No open complaints!', style: TextStyle(color: Colors.indigo.shade300, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final item = complaints[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(item.status).withOpacity(0.1),
                    child: Icon(_getStatusIcon(item.status), color: _getStatusColor(item.status)),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor(item.status)),
                    ),
                    child: Text(
                      item.status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(item.status)),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref, user.uid),
        label: const Text('Raise Complaint'),
        icon: const Icon(Icons.report_problem),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved': return Colors.green;
      case 'in_progress': return Colors.orange;
      default: return Colors.red;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'resolved': return Icons.check_circle;
      case 'in_progress': return Icons.engineering;
      default: return Icons.error_outline;
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, String uid) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    // Need flat number. Fetch current user from firestore to be sure?
    // Optimization: Assume user knows their flat or auto-fetch.
    // For now, let's just make them type title/desc. Flat number can be fetched in logic or stored in AppUser.
    
    // Fetch AppUser to get Flat Number
    final appUser = await ref.read(firestoreServiceProvider).getUser(uid);
    if (appUser == null) return;

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Raise Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Issue (e.g. Leaking Tap)')),
              const SizedBox(height: 8),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Details'), maxLines: 3),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                 if (titleController.text.isEmpty) return;
                 await ref.read(firestoreServiceProvider).addComplaint(Complaint(
                   id: '',
                   title: titleController.text,
                   description: descController.text,
                   residentId: uid,
                   flatNumber: "${appUser.wing}-${appUser.flatNumber}", // Combine Wing-Flat
                   status: 'open',
                   createdAt: DateTime.now(),
                 ));
                 if (context.mounted) Navigator.pop(context);
              },
              child: const Text('SUBMIT'),
            ),
          ],
        ),
      );
    }
  }
}
