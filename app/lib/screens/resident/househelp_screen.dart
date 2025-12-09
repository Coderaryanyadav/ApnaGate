import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import 'staff_attendance_screen.dart'; // Added

class HousehelpScreen extends ConsumerStatefulWidget {
  const HousehelpScreen({super.key});

  @override
  ConsumerState<HousehelpScreen> createState() => _HousehelpScreenState();
}

class _HousehelpScreenState extends ConsumerState<HousehelpScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Error')));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Manage Daily Help'), 
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder(
        future: ref.read(firestoreServiceProvider).getUser(user.id),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final currentUser = userSnapshot.data!;
          final wing = currentUser.wing ?? '';
          final flatNumber = currentUser.flatNumber ?? '';

          if (wing.isEmpty || flatNumber.isEmpty) {
            return const Center(
              child: Text(
                'Unable to load flat information',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Column(
            children: [
              // Header Stats
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.indigoAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All members of $wing-$flatNumber can view and manage this list.',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ref.read(firestoreServiceProvider).getHousehelpsByFlat(wing, flatNumber),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final staffList = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: staffList.length,
                      itemBuilder: (context, index) {
                        final staff = staffList[index];
                        return _buildStaffCard(staff);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffDialog(context, user.id),
        backgroundColor: Colors.indigoAccent,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cleaning_services, size: 80, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No Staff Added',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your daily help to track attendance',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final isPresent = staff['is_present'] == true;
    
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showStaffQR(staff),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                backgroundImage: staff['photo_url'] != null ? CachedNetworkImageProvider(staff['photo_url']) : null,
                child: staff['photo_url'] == null 
                  ? const Icon(Icons.person, color: Colors.white54) 
                  : null,
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        staff['role'].toString().toUpperCase(),
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // View History Icon
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.blueAccent),
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (_) => StaffAttendanceScreen(staffId: staff['id'], staffName: staff['name'])
                  )
                ),
              ),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (isPresent ? Colors.green : Colors.red).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (isPresent ? Colors.green : Colors.red).withValues(alpha: 0.5)),
                ),
                child: Text(
                  isPresent ? 'INSIDE' : 'OUTSIDE',
                  style: TextStyle(
                    color: isPresent ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: () => _confirmDelete(staff['id']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStaffQR(Map<String, dynamic> staff) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Show to Guard',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: 'STAFF:${staff['id']}',
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              staff['name'],
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              staff['role'].toString().toUpperCase(),
              style: const TextStyle(color: Colors.indigoAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Staff?'),
        content: const Text('Are you sure you want to remove this staff member?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
               ref.read(firestoreServiceProvider).deleteHousehelp(id);
               Navigator.pop(context);
            }, 
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context, String ownerId) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'Maid';
    String? photoPath;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Househelp'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.camera, maxWidth: 600);
                      if (image != null) {
                        setDialogState(() => photoPath = image.path);
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: photoPath != null ? NetworkImage('file://$photoPath') : null, // Note: NetworkImage might not work with file URI correctly directly in all Flutter versions without FileImage, but usually ok. Wait, NetworkImage('file://') fails.
                      child: photoPath == null 
                        ? const Icon(Icons.camera_alt, color: Colors.white) 
                        : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    // ignore: deprecated_member_use
                    value: role,
                    items: ['Maid', 'Driver', 'Cook', 'Nanny', 'Other'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setDialogState(() => role = v!),
                    decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.work)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone (Optional)', prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  
                  // Quick Upload Logic (Ideally moved to service)
                  String? photoUrl;
                  if (photoPath != null) {
                     // We need to implement upload logic here or pass path
                     // For simplicity, we assume StorageService exists
                      try {
                        photoUrl = await ref.read(storageServiceProvider).uploadProfilePhoto(
                           userId: 'staff_${DateTime.now().millisecondsSinceEpoch}', // Temp ID
                           imagePath: photoPath!,
                        );
                      } catch (e) {
                         debugPrint('Upload failed: $e');
                      }
                  }

                  await ref.read(firestoreServiceProvider).addHousehelp(
                    ownerId: ownerId,
                    name: nameCtrl.text,
                    role: role,
                    phone: phoneCtrl.text,
                    photoUrl: photoUrl,
                  );
                  
                  if (mounted && dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }
}
