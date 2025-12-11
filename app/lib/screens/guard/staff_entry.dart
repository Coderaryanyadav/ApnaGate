import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/extras.dart';
import '../../services/notification_service.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/society_config_service.dart';
import '../resident/staff_attendance_screen.dart';

// Providers for fetching data
final serviceProvidersStream = StreamProvider.autoDispose((ref) => ref.watch(firestoreServiceProvider).getServiceProviders());
final dailyHelpStream = StreamProvider.autoDispose((ref) => ref.watch(firestoreServiceProvider).getAllDailyHelp());

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
    // Watch both streams
    final servicesAsync = ref.watch(serviceProvidersStream);
    final dailyAsync = ref.watch(dailyHelpStream);

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
                labelText: 'Search Staff or Flat',
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
            child: Builder(
              builder: (context) {
                // Handle Loading/Errors
                if (servicesAsync.isLoading || dailyAsync.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<StaffItem> allStaff = [];

                // 1. Process Service Providers
                servicesAsync.whenData((list) {
                  allStaff.addAll(list.map((s) => StaffItem(
                    id: s.id,
                    name: s.name,
                    category: s.category,
                    status: s.status,
                    lastActive: s.lastActive,
                    isDailyHelp: false,
                    provider: s,
                  )));
                });

                // 2. Process Daily Help
                dailyAsync.whenData((list) {
                  allStaff.addAll(list.map((d) {
                    // Parse Last Active
                    DateTime? lastActive;
                    if (d['is_present'] == true && d['last_entry_time'] != null) {
                       lastActive = DateTime.tryParse(d['last_entry_time']);
                    } else if (d['last_exit_time'] != null) {
                       lastActive = DateTime.tryParse(d['last_exit_time']);
                    }

                    return StaffItem(
                      id: d['id'],
                      name: d['name'] ?? 'Unknown',
                      category: d['role'] ?? 'Staff',
                      status: (d['is_present'] == true) ? 'in' : 'out',
                      lastActive: lastActive?.toLocal(),
                      isDailyHelp: true,
                      ownerId: d['owner_id'],
                      wing: d['wing'],
                      flat: d['flat_number'],
                    );
                  }));
                });

                // 3. Filter
                final filtered = allStaff.where((p) {
                   // 🔍 Search Match
                   final matchName = p.name.toLowerCase().contains(_searchQuery);
                   final matchCat = p.category.toLowerCase().contains(_searchQuery);
                   final matchFlat = p.flat?.toLowerCase().contains(_searchQuery) ?? false;
                   final isMatch = matchName || matchCat || matchFlat;

                   // 🛑 Logic: 
                   // - Service Providers (Guard, Driver): Always show (or filter by search if typed)
                   // - Daily Help (Maids): ONLY show if Search is typed (hide by default to declutter)
                   
                   if (_searchQuery.isEmpty) {
                     return !p.isDailyHelp; // Show only Service Providers by default
                   }
                   
                   return isMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No staff found'));
                }
                
                // Sort: "In" first, then by name
                filtered.sort((a, b) {
                  if (a.status == 'in' && b.status != 'in') return -1;
                  if (a.status != 'in' && b.status == 'in') return 1;
                  return a.name.compareTo(b.name);
                });

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
                          // Show Flat info if Daily Help
                          staff.isDailyHelp 
                            ? '${staff.category} • ${staff.wing}-${staff.flat}\n${isIn ? 'In since' : 'Left'}: ${_formatTime(staff.lastActive)}'
                            : '${staff.category} • ${isIn ? 'In since' : 'Last seen'}: ${_formatTime(staff.lastActive)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        isThreeLine: staff.isDailyHelp,
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
                                  onPressed: () {
                                    if (staff.isDailyHelp) {
                                      // Direct Toggle for Daily Help (We know the flat)
                                      _toggleDailyHelp(staff);
                                    } else {
                                      // Dialog for Service Provider (Ask flat?)
                                      staff.status == 'in' 
                                        ? _toggleServiceProvider(staff.provider!) // Checkout direct
                                        : _showCheckInDialog(staff.provider!); // Checkin dialog
                                    }
                                  },
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

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'N/A';
    return DateFormat('hh:mm a').format(dt);
  }

  // Logic for Daily Help (Simple Toggle)
  Future<void> _toggleDailyHelp(StaffItem staff) async {
    // ignore: deprecated_member_use, unawaited_futures
    HapticFeedback.mediumImpact();
    
    final isEntry = staff.status != 'in'; // Toggle
    
    try {
      if (staff.ownerId == null) throw Exception('Owner ID missing');

      await ref.read(firestoreServiceProvider).toggleStaffAttendance(
        staff.id, 
        staff.ownerId!, 
        isEntry
      );
      
      // Notify Resident
      if (isEntry && staff.wing != null && staff.flat != null) {
        await ref.read(notificationServiceProvider).notifyFlat(
          wing: staff.wing!,
          flatNumber: staff.flat!,
          title: 'Daily Help Entry',
          message: '${staff.name} (${staff.category}) has clocked IN.',
        );
      } else if (!isEntry && staff.wing != null && staff.flat != null) {
         // Optional: Notify exit
         /*
         await ref.read(notificationServiceProvider).notifyFlat(
          wing: staff.wing!,
          flatNumber: staff.flat!,
          title: 'Daily Help Exit',
          message: '${staff.name} (${staff.category}) has clocked OUT.',
        );
        */
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff.name} Marked ${isEntry ? "IN" : "OUT"}'),
            backgroundColor: isEntry ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // Logic for Service Provider (Generic)
  Future<void> _toggleServiceProvider(ServiceProvider staff, {String? wing, String? flat}) async {
    // ignore: deprecated_member_use, unawaited_futures
    HapticFeedback.mediumImpact();
    
    final newStatus = staff.status == 'in' ? 'out' : 'in';
    final currentUser = ref.read(authServiceProvider).currentUser;

    String? residentId;
    if (wing != null && flat != null && flat.isNotEmpty) {
      try {
        final residents = await ref.read(firestoreServiceProvider).getResidentsByFlat(wing, flat);
        if (residents.isNotEmpty) residentId = residents.first.id;
      } catch (e) { debugPrint('Error resolving resident: $e'); }
    }

    try {
      await ref.read(firestoreServiceProvider).updateProviderStatus(
         staff.id, 
         newStatus,
         actorId: currentUser?.id,
         ownerId: residentId,
      );
      
      if (newStatus == 'in' && wing != null && flat != null) {
        await ref.read(notificationServiceProvider).notifyFlat(
          wing: wing,
          flatNumber: flat,
          title: 'Staff Arrived',
          message: '${staff.name} (${staff.category}) has arrived.',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff.name} Marked ${newStatus.toUpperCase()}'),
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
    final flatCtrl = TextEditingController();

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
                const Text('Visiting specific flat?', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[850],
                  style: const TextStyle(color: Colors.white),
                  items: config.wings.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                  onChanged: (v) => selectedWing = v,
                  decoration: const InputDecoration(labelText: 'Wing', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: flatCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Flat Number', labelStyle: TextStyle(color: Colors.white70)),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _toggleServiceProvider(staff); // General
                },
                child: const Text('General Entry', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                  _toggleServiceProvider(staff, wing: selectedWing, flat: flatCtrl.text.trim());
                },
                child: const Text('Check In'),
              ),
            ],
          );
        }
      ),
    );
  }
}

// Helper Class
class StaffItem {
  final String id;
  final String name;
  final String category;
  final String status;
  final DateTime? lastActive;
  final bool isDailyHelp;
  final String? ownerId;
  final String? wing;
  final String? flat;
  final ServiceProvider? provider;

  StaffItem({
    required this.id,
    required this.name,
    required this.category,
    required this.status,
    this.lastActive,
    required this.isDailyHelp,
    this.ownerId,
    this.wing,
    this.flat,
    this.provider,
  });
}
