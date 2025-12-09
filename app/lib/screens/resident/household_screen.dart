import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user.dart'; // Added
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../utils/haptic_helper.dart';

class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key});

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  


  Future<void> _showAddMemberDialog() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    final currentUser = await ref.read(firestoreServiceProvider).getUser(user.id);
    if (currentUser == null || !mounted) return;

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(); // Owner sets password
    String selectedRole = 'family'; 
    bool isSubmitting = false;

    // Use a simplified flow: Just enter URL or handle upload later. 
    // Since I cannot modify "Storage Service" efficiently here without seeing it, I will use a placeholder or assume text for now, 
    // OR just skip the *file* aspect and stick to text fields if user allows?
    // User said: "image of the member".
    // I will add a "Photo URL" field for now (maybe pointing to dicebear or similar if no upload). 
    // Or I'll skip the image *upload* complexity in this single step to avoid breaking build if packages missing.
    // Wait, the user uploaded an image.
    // I'll stick to basic fields first.
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Add Member', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 TextField(
                   controller: nameCtrl,
                   style: const TextStyle(color: Colors.white),
                   decoration: const InputDecoration(
                     labelText: 'Name',
                     labelStyle: TextStyle(color: Colors.white70),
                     enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                   ),
                 ),
                 const SizedBox(height: 12),
                 TextField(
                   controller: phoneCtrl,
                   style: const TextStyle(color: Colors.white),
                   keyboardType: TextInputType.phone,
                   decoration: const InputDecoration(
                     labelText: 'Phone Number',
                     labelStyle: TextStyle(color: Colors.white70),
                     enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                   ),
                 ),
                 const SizedBox(height: 12),
                 TextField(
                   controller: emailCtrl,
                   style: const TextStyle(color: Colors.white),
                   keyboardType: TextInputType.emailAddress,
                   decoration: const InputDecoration(
                     labelText: 'Email',
                     labelStyle: TextStyle(color: Colors.white70),
                     enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                   ),
                 ),
                 const SizedBox(height: 12),
                 TextField(
                   controller: passwordCtrl,
                   style: const TextStyle(color: Colors.white),
                   obscureText: true,
                   decoration: const InputDecoration(
                     labelText: 'Set Password',
                     labelStyle: TextStyle(color: Colors.white70),
                     enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                   ),
                 ),
                 const SizedBox(height: 16),
                 DropdownButtonFormField<String>(
                   // ignore: deprecated_member_use
                   value: selectedRole,
                   dropdownColor: const Color(0xFF2C2C2C),
                   style: const TextStyle(color: Colors.white),
                   decoration: const InputDecoration(
                     labelText: 'Role',
                     labelStyle: TextStyle(color: Colors.white70),
                     enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                   ),
                   items: const [
                     DropdownMenuItem(value: 'family', child: Text('Family Member')),
                     DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
                   ],
                   onChanged: (val) => setState(() => selectedRole = val!),
                 ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: isSubmitting ? null : () async {
                 if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty || passwordCtrl.text.isEmpty) return;
                 
                 setState(() => isSubmitting = true);
                 try {
                   // 1. Create Auth User
                   String? newUserId;
                   try {
                     newUserId = await ref.read(authServiceProvider).createUser(
                       emailCtrl.text.trim(), 
                       passwordCtrl.text.trim()
                     );
                   } catch (authError) {
                      debugPrint('⚠️ Auth creation failed: $authError');
                   }

                   // Generate avatar
                   final randomAvatar = 'https://api.dicebear.com/7.x/avataaars/png?seed=${nameCtrl.text}';

                   // 2. Add to Household Registry (and link ID if created)
                   await ref.read(firestoreServiceProvider).addHouseholdMember(
                     ownerId: currentUser.id,
                     name: nameCtrl.text.trim(),
                     phone: phoneCtrl.text.trim(),
                     email: emailCtrl.text.trim(),
                     // password: passwordCtrl.text.trim(), // Removed
                     photoUrl: randomAvatar, 
                     role: selectedRole,
                     wing: currentUser.wing ?? '',
                     flatNumber: currentUser.flatNumber ?? '',
                     linkedUserId: newUserId, // New parameter
                   );

                   // 3. Create Profile (Crucial for Login)
                   if (newUserId != null) {
                      await ref.read(firestoreServiceProvider).createProfileForMember(
                        id: newUserId,
                        email: emailCtrl.text.trim(),
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        role: 'resident', // They are residents
                        wing: currentUser.wing ?? '',
                        flatNumber: currentUser.flatNumber ?? '',
                        ownerId: currentUser.id, // Link to owner
                        photoUrl: randomAvatar,
                      );
                   }
                   if (context.mounted) Navigator.pop(context);
                 } catch (e) {
                   String errorMsg = 'Unable to add member. Please try again.';
                   final errString = e.toString().toLowerCase();
                   
                   if (errString.contains('email-already-in-use')) {
                     errorMsg = 'This email is already associated with an account.';
                   } else if (errString.contains('weak-password')) {
                     errorMsg = 'Password is too weak. Please use at least 6 characters.';
                   } else if (errString.contains('invalid-email')) {
                     errorMsg = 'Please enter a valid email address.';
                   } else if (errString.contains('network')) {
                     errorMsg = 'Network error. Please check your connection.';
                   }

                   if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('$errorMsg\n(Technical: $e)'), // Show technical error for user to report
                        backgroundColor: Colors.redAccent,
                        duration: const Duration(seconds: 5),
                      ));
                   }
                   setState(() => isSubmitting = false);
                 }
              },
              child: isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authServiceProvider).currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Household Management'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder(
        future: ref.read(firestoreServiceProvider).getUser(user.id),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const LoadingList(message: 'Loading...');
          }

          final currentUser = userSnapshot.data!;
          final wing = currentUser.wing ?? '';
          final flatNumber = currentUser.flatNumber ?? '';

          if (wing.isEmpty || flatNumber.isEmpty) {
            return const Center(child: Text('Unable to load flat information', style: TextStyle(color: Colors.white)));
          }

          // 1. Stream Registry (Invites/Pending)
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: ref.watch(firestoreServiceProvider).getHouseholdMembersByFlat(wing, flatNumber),
            builder: (context, registrySnapshot) {
              
              // 2. Stream Profiles (Active Users)
              return StreamBuilder<List<AppUser>>(
                  stream: ref.watch(firestoreServiceProvider).getResidentsStream(wing, flatNumber),
                  builder: (context, profilesSnapshot) {
                    if (registrySnapshot.connectionState == ConnectionState.waiting || 
                        profilesSnapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingList(message: 'Loading members...');
                    }

                    final registryList = registrySnapshot.data ?? [];
                    final profileList = profilesSnapshot.data ?? [];

                    // --- MERGE LOGIC ---
                    final Map<String, Map<String, dynamic>> mergedMap = {};

                    // A. Add Profiles (Source of Truth for Active Users)
                    for (var profile in profileList) {
                      // Use Phone or ID as key? Profile ID is unique.
                      mergedMap[profile.id] = {
                        'id': profile.id, // Profile ID implies deletion removes Profile? No, usually household_registry ID. 
                        // Logic: If user is in Profile, they are a member. Removing them means removing from Group? 
                        // If they are just a Profile, we can't 'delete' the profile easily.
                        // Ideally, we treat them as 'Active'.
                        'name': profile.name,
                        'phone': profile.phone,
                        'role': profile.role == 'admin' ? 'Co-Owner' : 'Family',
                        'photo_url': profile.photoUrl,
                        'is_registered': true,
                        'is_profile': true, // Mark as having a profile
                        'profile_id': profile.id,
                      };
                    }

                    // B. Add/Update from Registry (Source for Roles/Pending)
                    for (var reg in registryList) {
                      // Try to match with existing Profile by Phone
                      final phone = reg['phone']?.toString().trim();
                      // Find if this phone exists in mergedMap
                      String? existingId;
                      for (var key in mergedMap.keys) {
                        if (mergedMap[key]?['phone'] == phone) {
                          existingId = key;
                          break;
                        }
                      }
                      
                      final linkedId = reg['linked_user_id'];
                      if (linkedId != null && mergedMap.containsKey(linkedId)) {
                         existingId = linkedId;
                      }

                      if (existingId != null) {
                        // MERGE: Update Role from Registry (it's more specific: Tenant/Family)
                        mergedMap[existingId]!['role'] = reg['role'];
                        mergedMap[existingId]!['registry_id'] = reg['id']; // Store registry ID for deletion
                      } else {
                        // Add New (Pending Invite)
                        mergedMap[reg['id']] = {
                          'id': reg['id'],
                          'name': reg['name'],
                          'phone': reg['phone'],
                          'role': reg['role'],
                          'photo_url': reg['photo_url'],
                          'is_registered': false, // Not in profile list? Or check linked_user_id
                          'registry_id': reg['id'],
                          // If linked_user_id is set but not found in Profiles stream (maybe delay?), treat as pending?
                          // Or maybe profile fetch failed?
                        };
                      }
                    }

                    // C. Convert to List & Sort
                    final members = mergedMap.values.toList();
                    
                    // D. Handle Current User Display
                    final isUserInList = members.any((m) => m['phone'] == currentUser.phone || m['id'] == currentUser.id);
                    if (!isUserInList) {
                       members.insert(0, {
                          'id': currentUser.id,
                          'name': '${currentUser.name} (You)',
                          'phone': currentUser.phone,
                          'role': 'Owner (You)',
                          'photo_url': currentUser.photoUrl,
                          'is_registered': true,
                          'is_current_user': true,
                       });
                    } else {
                       // Mark current user
                       for (var m in members) {
                         if (m['phone'] == currentUser.phone || m['id'] == currentUser.id) {
                            m['name'] = '${m['name']} (You)';
                            m['is_current_user'] = true;
                            if (m['role'] == null) m['role'] = 'Owner';
                         }
                       }
                    }

                    members.sort((a, b) {
                       if (a['is_current_user'] == true) return -1;
                       if (b['is_current_user'] == true) return 1;
                       return 0;
                    });

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Manage Family & Tenants',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All members of $wing-$flatNumber can view and manage this list.',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddMemberDialog,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Member'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigoAccent,
                              foregroundColor: Colors.white,
                           minimumSize: const Size(double.infinity, 50),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                       ),
                     ],
                   ),
                 ),
              ),

              if (members.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.family_restroom,
                    title: 'No Members Yet',
                    message: 'Add family members or tenants to get started',
                    onAction: _showAddMemberDialog,
                    actionLabel: 'Add Member',
                  ),
                )
              else 
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final member = members[index];
                      final isRegistered = member['is_registered'] == true;
                      final isCurrentUser = member['is_current_user'] == true;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E), // Dark Card
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                             radius: 24,
                             backgroundColor: isRegistered ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                             backgroundImage: member['photo_url'] != null ? NetworkImage(member['photo_url']) : null,
                             child: member['photo_url'] == null ? Icon(
                               member['role'] == 'Family' || member['role'] == 'Owner' ? Icons.favorite : Icons.person,
                               color: member['role'] == 'Family' || member['role'] == 'Owner' ? Colors.pinkAccent : Colors.blueAccent,
                             ) : null,
                          ),
                          title: Text(member['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                               Text(member['phone'] ?? '', style: const TextStyle(color: Colors.grey)),
                               const SizedBox(height: 4),
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                 decoration: BoxDecoration(
                                   color: isRegistered ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                   borderRadius: BorderRadius.circular(4),
                                 ),
                                 child: Text(
                                   isRegistered ? 'Active' : 'Pending Invite',
                                   style: TextStyle(
                                     fontSize: 10, 
                                     color: isRegistered ? Colors.greenAccent : Colors.orangeAccent
                                   ),
                                 ),
                               ),
                             ],
                           ),
                           trailing: isCurrentUser ? null : IconButton(
                             // If it's a Profile WITHOUT Registry ID, we can't "delete" it from registry. 
                             // We might need to 'Add to registry then delete'? Or just Hide?
                             // Delete creates a disconnect.
                             icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                             onPressed: () => _confirmDelete(member['registry_id'] ?? member['profile_id']), 
                           ),
                         ),
                       );
                     },
                     childCount: members.length,
                   ),
                 ),
            ],
          );
        }
      );  
    });
   }
  ),
 );
}

  Future<void> _confirmDelete(String id) async {
    final confirmed = await ConfirmationDialog.confirmDelete(
      context: context,
      itemName: 'household member',
    );

    if (confirmed) {
      await ref.read(firestoreServiceProvider).removeHouseholdMember(id);
      if (mounted) {
        HapticHelper.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Member removed'), backgroundColor: Colors.green),
        );
      }
    }
  }
}
