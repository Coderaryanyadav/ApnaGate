import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PatrolLogsScreen extends StatelessWidget {
  const PatrolLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.isBoxOpen('patrol_logs') ? Hive.box('patrol_logs') : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Security Patrol Logs')),
      body: box == null || box.isEmpty
          ? const Center(child: Text('No patrol checkpoints logged recently.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final log = box.getAt(box.length - 1 - index) as Map?;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified, color: Colors.greenAccent),
                    title: Text(log?['checkpoint']?.toString() ?? 'Checkpoint Logged'),
                    subtitle: Text('Timestamp: ${log?['time'] ?? 'N/A'}'),
                  ),
                );
              },
            ),
    );
  }
}
