import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/extras.dart';
import '../../services/notification_service.dart';
import '../../services/firestore_service.dart';

class StaffEntryScreen extends ConsumerStatefulWidget {
  const StaffEntryScreen({super.key});

  @override
  ConsumerState<StaffEntryScreen> createState() => _StaffEntryScreenState();
}

class _StaffEntryScreenState extends ConsumerState<StaffEntryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Staff Entry')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Search Staff',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ServiceProvider>>(
              stream: ref.watch(firestoreServiceProvider).getServiceProviders(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final providers = snapshot.data!;
                
                final filtered = providers.where((p) {
                   return p.name.toLowerCase().contains(_searchQuery) || 
                          p.category.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No staff found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final staff = filtered[index];
                    final isIn = staff.status == 'in';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isIn ? Colors.green.shade100 : Colors.grey.shade100,
                          child: Icon(Icons.person, color: isIn ? Colors.green : Colors.grey),
                        ),
                        title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${staff.category} • ${staff.status == 'in' ? 'Since' : 'Last seen'}: ${staff.lastActive != null ? TimeOfDay.fromDateTime(staff.lastActive!).format(context) : 'N/A'}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: () => _toggleStatus(staff),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isIn ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(isIn ? 'CHECK OUT' : 'CHECK IN'),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(ServiceProvider staff) async {
    // 📳 Haptic Feedback
    // ignore: deprecated_member_use, unawaited_futures
    HapticFeedback.mediumImpact();
    
    final newStatus = staff.status == 'in' ? 'out' : 'in';
    // 1. Update Database
    await ref.read(firestoreServiceProvider).updateProviderStatus(staff.id, newStatus);
    
    // 2. Notify Admin
    try {
        final action = newStatus == 'in' ? 'Checked In' : 'Checked Out';
        final message = '${staff.name} ($action) - ${staff.category}';
        
        await ref.read(notificationServiceProvider).notifyByTag(
          tagKey: 'role', 
          tagValue: 'admin', 
          title: 'Staff Update', 
          message: message,
          data: {'type': 'staff_update', 'staff_id': staff.id, 'status': newStatus}
        );
    } catch (e) {
        debugPrint('Failed to notify admin: $e');
    }
    
    // Force refresh UI (Works even if Realtime is off)
    // ignore: unused_result
    ref.refresh(firestoreServiceProvider);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${staff.name} Marked ${newStatus.toUpperCase()}')),
      );
    }
  }
}
