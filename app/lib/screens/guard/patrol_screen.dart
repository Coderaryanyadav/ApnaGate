import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class PatrolScreen extends StatefulWidget {
  const PatrolScreen({super.key});

  @override
  State<PatrolScreen> createState() => _PatrolScreenState();
}

class _PatrolScreenState extends State<PatrolScreen> {
  final List<String> _checkpoints = [
    'Main Gate & Lobby',
    'Basement Parking B1',
    'Basement Parking B2',
    'Clubhouse & Pool',
    'Terrace Tower A',
    'Terrace Tower B',
    'Rear Perimeter Fence',
  ];

  final Set<String> _scannedCheckpoints = {};

  Future<void> _logCheckpoint(String cp) async {
    setState(() {
      _scannedCheckpoints.add(cp);
    });

    try {
      if (Hive.isBoxOpen('patrol_logs')) {
        final box = Hive.box('patrol_logs');
        await box.add({
          'checkpoint': cp,
          'time': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        });
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged checkpoint: $cp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patrol Checkpoints')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _checkpoints.length,
        itemBuilder: (context, index) {
          final cp = _checkpoints[index];
          final isScanned = _scannedCheckpoints.contains(cp);

          return Card(
            child: ListTile(
              leading: Icon(
                isScanned ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isScanned ? Colors.greenAccent : Colors.white54,
              ),
              title: Text(cp, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: ElevatedButton(
                onPressed: isScanned ? null : () => _logCheckpoint(cp),
                child: Text(isScanned ? 'VERIFIED' : 'SCAN'),
              ),
            ),
          );
        },
      ),
    );
  }
}
