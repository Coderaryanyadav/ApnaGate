import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/extras.dart';
import '../../services/firestore_service.dart';

class NoticeAdminScreen extends ConsumerWidget {
  const NoticeAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Building Notices (Admin)')),
      body: StreamBuilder<List<Notice>>(
        stream: ref.watch(firestoreServiceProvider).getNotices(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final notices = snapshot.data!;
          if (notices.isEmpty) return const Center(child: Text('No notices posted'));

          return ListView.builder(
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return Card(
                color: _getTypeColor(notice.type).withOpacity(0.1),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(_getTypeIcon(notice.type), color: _getTypeColor(notice.type)),
                  title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notice.description),
                  trailing: Text(
                    "${notice.createdAt.day}/${notice.createdAt.month} ${notice.createdAt.hour}:${notice.createdAt.minute}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNoticeDialog(context, ref),
        label: const Text('Post Notice'),
        icon: const Icon(Icons.add_alert),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'alert': return Colors.red;
      case 'event': return Colors.purple;
      default: return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'alert': return Icons.warning;
      case 'event': return Icons.event;
      default: return Icons.info;
    }
  }

  void _showAddNoticeDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String type = 'info';
    DateTime? expiryDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Post New Notice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: type,
                items: ['info', 'alert', 'event'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => type = v!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 16),
              // Expiry Date Picker
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => expiryDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_off),
                      const SizedBox(width: 8),
                      Text(
                        expiryDate == null 
                          ? 'Set Expiry (Optional)' 
                          : 'Expires: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}',
                        style: TextStyle(color: expiryDate == null ? Colors.white54 : Colors.white),
                      ),
                      const Spacer(),
                      if (expiryDate != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => setState(() => expiryDate = null),
                        )
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                
                await ref.read(firestoreServiceProvider).addNotice(Notice(
                  id: '',
                  title: titleController.text,
                  description: descController.text,
                  createdAt: DateTime.now(),
                  type: type,
                  expiresAt: expiryDate,
                ));

                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('POST'),
            ),
          ],
        ),
      ),
    );
  }
}
