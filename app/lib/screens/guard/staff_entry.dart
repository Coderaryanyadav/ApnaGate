import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/daily_help.dart';
import '../../services/firestore_service.dart';

class StaffEntryScreen extends ConsumerStatefulWidget {
  const StaffEntryScreen({super.key});

  @override
  ConsumerState<StaffEntryScreen> createState() => _StaffEntryScreenState();
}

class _StaffEntryScreenState extends ConsumerState<StaffEntryScreen> {
  late Future<List<DailyHelp>> _staffFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _staffFuture = ref.read(firestoreServiceProvider).getDailyHelp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff & Daily Help Entry'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<DailyHelp>>(
        future: _staffFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final staffList = snapshot.data ?? [];
          if (staffList.isEmpty) {
            return const Center(child: Text('No daily staff registered.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final staff = staffList[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.badge,
                    color: staff.isInside ? Colors.greenAccent : Colors.white60,
                  ),
                  title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${staff.role} • ${staff.phone ?? "No Phone"}'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: staff.isInside ? Colors.redAccent : const Color(0xFF00E5FF),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Toggled status for ${staff.name}')),
                      );
                    },
                    child: Text(staff.isInside ? 'LOG EXIT' : 'LOG ENTRY'),
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
