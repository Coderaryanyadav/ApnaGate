import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withValues(alpha: 0.3),
             blurRadius: 10,
             offset: const Offset(0, 5),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStaffQR(staff),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 1. Photo Avatar
                Hero(
                  tag: 'staff_${staff['id']}',
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPresent ? Colors.greenAccent : Colors.grey.withValues(alpha: 0.3), 
                        width: 2
                      ),
                      image: staff['photo_url'] != null 
                        ? DecorationImage(image: CachedNetworkImageProvider(staff['photo_url']), fit: BoxFit.cover)
                        : null,
                      color: const Color(0xFF2A2A35),
                    ),
                     child: staff['photo_url'] == null 
                        ? const Icon(Icons.person, color: Colors.white54, size: 30) 
                        : null,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 2. Name & Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff['name'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (staff['role'] ?? 'Staff').toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.indigoAccent, 
                                fontSize: 10, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status Badge
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isPresent ? Colors.green : Colors.red).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    color: isPresent ? Colors.greenAccent : Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isPresent ? 'INSIDE' : 'OUTSIDE',
                                  style: TextStyle(
                                    color: isPresent ? Colors.greenAccent : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Action Buttons (History & Delete)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.blueAccent),
                      tooltip: 'View History',
                      onPressed: () => Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => StaffAttendanceScreen(staffId: staff['id'], staffName: staff['name'])
                        )
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white30),
                      tooltip: 'Remove',
                      onPressed: () => _confirmDelete(staff['id']),
                    ),
                  ],
                ),
              ],
            ),
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
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Text(
              'Show to Security Guard',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.white.withValues(alpha: 0.1), blurRadius: 20),
                ],
              ),
              child: QrImageView(
                data: 'STAFF:${staff['id']}',
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              staff['name'],
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                 color: Colors.indigo.withValues(alpha: 0.2),
                 borderRadius: BorderRadius.circular(20),
                 border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.5)),
              ),
              child: Text(
                staff['role'].toString().toUpperCase(),
                style: const TextStyle(color: Colors.indigoAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Staff?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to remove this staff member? This will delete their history.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
               ref.read(firestoreServiceProvider).deleteHousehelp(id);
               Navigator.pop(context);
            }, 
            child: const Text('Removing...'), // Short text for button
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
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E2C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Add Daily Help', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.camera, maxWidth: 600, imageQuality: 80);
                      if (image != null) {
                        setDialogState(() => photoPath = image.path);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.indigoAccent, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: const Color(0xFF2A2A35),
                        backgroundImage: photoPath != null ? FileImage(File(photoPath!)) : null, 
                        child: photoPath == null 
                          ? const Icon(Icons.camera_alt, color: Colors.white54, size: 30) 
                          : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.person, color: Colors.indigoAccent),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF2A2A35),
                    style: const TextStyle(color: Colors.white),
                    // ignore: deprecated_member_use
                    value: role,
                    items: ['Maid', 'Driver', 'Cook', 'Nanny', 'Other'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setDialogState(() => role = v!),
                    decoration: InputDecoration(
                      labelText: 'Role',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.work, color: Colors.indigoAccent),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Phone (Optional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.phone, color: Colors.indigoAccent),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                 onPressed: () => Navigator.pop(dialogContext), 
                 child: const Text('Cancel', style: TextStyle(color: Colors.grey))
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.indigoAccent, 
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  
                  // Show Loading visual (quick hack since state is local)
                  setDialogState(() {}); 
                  
                  String? photoUrl;
                  if (photoPath != null) {
                      try {
                        photoUrl = await ref.read(storageServiceProvider).uploadProfilePhoto(
                           userId: 'staff_${const Uuid().v4()}', 
                           imagePath: photoPath!,
                        );
                      } catch (e) {
                         debugPrint('Upload failed: $e');
                      }
                  }

                  await ref.read(firestoreServiceProvider).addHousehelp(
                    ownerId: ownerId,
                    name: nameCtrl.text.trim(),
                    role: role,
                    phone: phoneCtrl.text.trim(),
                    photoUrl: photoUrl,
                  );
                  
                  if (mounted && dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Add Staff', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
      ),
    );
  }
}
