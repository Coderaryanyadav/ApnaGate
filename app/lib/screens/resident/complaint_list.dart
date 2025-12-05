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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
           if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}'));
           }
          final complaints = snapshot.data ?? [];

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
        onPressed: () => _showAddDialog(context, ref),
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

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    
    // Fetch user's flat number
    final appUser = await ref.read(firestoreServiceProvider).getUser(user.uid);
    if (appUser == null || !context.mounted) return;

    String selectedCategory = 'Plumbing Issue';
    final categories = [
      'Plumbing Issue',
      'Electricity Problem',
      'Neighbour Disturbance',
      'Staff Misbehavior',
      'Other',
    ];
    
    String description = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Raise Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category Dropdown
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedCategory = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Description
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide details about the issue...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                onChanged: (val) => description = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (description.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a description')),
                  );
                  return;
                }

                final complaint = Complaint(
                  id: '',
                  residentId: user.uid,
                  flatNumber: "${appUser.wing}-${appUser.flatNumber}",
                  title: selectedCategory,
                  description: description,
                  status: 'open',
                  createdAt: DateTime.now(),
                );

                await ref.read(firestoreServiceProvider).addComplaint(complaint);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Complaint submitted successfully')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
