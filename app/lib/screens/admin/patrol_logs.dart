
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PatrolLogsScreen extends StatefulWidget {
  const PatrolLogsScreen({super.key});

  @override
  State<PatrolLogsScreen> createState() => _PatrolLogsScreenState();
}

class _PatrolLogsScreenState extends State<PatrolLogsScreen> {
  late Future<List<Map<String, dynamic>>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = _fetchLogs();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchLogs() async {
    final box = Hive.box('patrol_logs');

    try {
      // Join with profiles to get guard name
      final response = await Supabase.instance.client
          .from('patrol_logs')
          .select('*, guard:guard_id(name)')
          .order('created_at', ascending: false)
          .limit(100);
          
      final data = List<Map<String, dynamic>>.from(response);
      
      // Cache
      await box.put('logs', data);
      
      return data;
    } catch (e) {
      debugPrint('⚠️ Network failed, loading logs from cache...');
      final cached = box.get('logs');
      if (cached != null) {
        // Safe cast
        return (cached as List).map((e) => Map<String, dynamic>.from(e)).toList();
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Patrol Logs 🛡️'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshLogs),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('No patrol logs yet.', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final guardName = log['guard']?['name'] ?? 'Unknown Guard';
              final type = log['scan_type'];
              final status = log['status'];
              final createdAt = DateTime.parse(log['created_at']).toLocal();
              final timeStr = DateFormat('hh:mm a').format(createdAt);
              final dateStr = DateFormat('MMM dd').format(createdAt);
              
              final isPeer = type == 'peer';
              
              return Card(
                color: const Color(0xFF1E1E2C),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPeer ? Colors.blueAccent : Colors.orangeAccent,
                    child: Icon(isPeer ? Icons.people : Icons.qr_code, color: Colors.white),
                  ),
                  title: Text('$guardName ($status)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    isPeer 
                      ? 'Verified Peer Guard' // Ideally show peer name if I joined scanned_id too
                      : 'Checkpoint: ${log['checkpoint_name']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(timeStr, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      Text(dateStr, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                    ],
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
