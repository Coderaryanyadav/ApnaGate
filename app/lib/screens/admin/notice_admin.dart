import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/notice.dart';
import '../../services/firestore_service.dart';

class NoticeAdminScreen extends ConsumerStatefulWidget {
  const NoticeAdminScreen({super.key});

  @override
  ConsumerState<NoticeAdminScreen> createState() => _NoticeAdminScreenState();
}

class _NoticeAdminScreenState extends ConsumerState<NoticeAdminScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _postNotice() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty || desc.isEmpty) return;

    final notice = Notice(
      id: const Uuid().v4(),
      title: title,
      description: desc,
      createdAt: DateTime.now(),
    );

    await ref.read(firestoreServiceProvider).createNotice(notice);
    _titleController.clear();
    _descController.clear();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice posted to all residents!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Society Notice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Notice Title')),
            const SizedBox(height: 16),
            TextField(controller: _descController, maxLines: 4, decoration: const InputDecoration(labelText: 'Full Description')),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _postNotice,
              icon: const Icon(Icons.send),
              label: const Text('PUBLISH NOTICE'),
            ),
          ],
        ),
      ),
    );
  }
}
