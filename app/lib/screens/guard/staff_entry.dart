import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/extras.dart';
import '../../services/notification_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/society_config_service.dart'; // Added
import '../resident/staff_attendance_screen.dart';

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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.calendar_month, color: Colors.blueAccent),
                              onPressed: () => Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (_) => StaffAttendanceScreen(staffId: staff.id, staffName: staff.name)
                                )
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                                child: ElevatedButton(
                                  onPressed: () => staff.status == 'in' ? _toggleStatus(staff) : _showCheckInDialog(staff),
                                  style: ElevatedButton.styleFrom(
                                  backgroundColor: isIn ? Colors.red : Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 0),
                                ),
                                child: Text(isIn ? 'CHECK OUT' : 'CHECK IN', style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
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

  Future<void> _toggleStatus(ServiceProvider staff, {String? wing, String? flat}) async {
    // 📳 Haptic Feedback
    // ignore: deprecated_member_use, unawaited_futures
    HapticFeedback.mediumImpact();
    
    final newStatus = staff.status == 'in' ? 'out' : 'in';
    final currentUser = ref.read(authServiceProvider).currentUser;

    try {
      // 1. Update Database & Log
      await ref.read(firestoreServiceProvider).updateProviderStatus(
         staff.id, 
         newStatus,
         actorId: currentUser?.id,
      );
      
      // 2. Notify Relevant Parties
      if (newStatus == 'in' && wing != null && flat != null && flat.isNotEmpty) {
        // 🔔 Notify Specific Resident (Daily Help Logic)
        await ref.read(notificationServiceProvider).notifyFlat(
          wing: wing,
          flatNumber: flat,
          title: 'Staff Arrived',
          message: '${staff.name} (${staff.category}) has arrived.',
          // data: {'type': 'staff_entry', 'staff_id': staff.id} // Optional data types
        );
      } else {
        // 🔔 Notify Admin (Default/General Staff)
        // Only if not notifying resident? Or both? Usually if resident notified, admin doesn't need spam.
        // But let's keep Admin updated for general security monitoring if desired.
        // However, Daily Help entry is private. I'll skip Admin notification if Resident is notified.
        if (wing == null) {
           final action = newStatus == 'in' ? 'Checked In' : 'Checked Out';
           await ref.read(notificationServiceProvider).notifyByTag(
             tagKey: 'role', 
             tagValue: 'admin', 
             title: 'Staff Update', 
             message: '${staff.name} ($action) - ${staff.category}',
           );
        }
      }

      // Force refresh
      // ignore: unused_result
      ref.refresh(firestoreServiceProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff.name} Marked ${newStatus.toUpperCase()} ${wing != null ? "for $wing-$flat" : ""}'),
            backgroundColor: newStatus == 'in' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showCheckInDialog(ServiceProvider staff) {
    String? selectedWing;
    final flatCtrl = TextEditingController(); // Dispose? Ideally yes, but in dialog it's fleeting.

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final config = ref.watch(societyConfigProvider);
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text('Check In: ${staff.name}', style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Is this staff visiting a specific flat?', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  items: config.wings.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                  onChanged: (v) => selectedWing = v,
                  decoration: const InputDecoration(
                    labelText: 'Wing (Optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: flatCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Flat Number (Optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _toggleStatus(staff); // No data = General
                },
                child: const Text('General Entry', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  _toggleStatus(staff, wing: selectedWing, flat: flatCtrl.text.trim());
                },
                child: const Text('Notify Resident'),
              ),
            ],
          );
        }
      ),
    );
  }
}
