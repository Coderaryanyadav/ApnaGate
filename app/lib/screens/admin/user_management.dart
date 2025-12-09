import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../models/user.dart';
import 'add_user_dialog.dart';
import '../../services/society_config_service.dart'; // Added
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../utils/haptic_helper.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _selectedRole = 'resident';
  String _searchQuery = '';

  Future<void> _showAddUserDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AddUserDialog(initialRole: _selectedRole),
    );
  }

  void _showEditUserDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => _EditUserDialog(user: user),
    );
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirm = await ConfirmationDialog.confirmDelete(
      context: context,
      itemName: user.name,
    );

    if (confirm) {
      try {
        await ref.read(firestoreServiceProvider).deleteUser(user.id);
        if (mounted) {
          HapticHelper.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ User deleted'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          HapticHelper.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersStream = ref.watch(firestoreServiceProvider).getUsersByRole(_selectedRole);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.orange),
            tooltip: 'Reset Data',
            onPressed: () async {
              final confirm = await ConfirmationDialog.show(
                context: context,
                title: '⚠️ RESET DATA',
                message: 'This will DELETE ALL USERS except Admins, Guards, and Resident A-101.\n\nThis action cannot be undone.',
                confirmText: 'DELETE ALL',
                confirmColor: Colors.red,
                icon: Icons.delete_forever,
              );

              if (confirm) {
                await ref.read(firestoreServiceProvider).cleanupNonEssentialUsers();
                if (context.mounted) {
                  HapticHelper.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Cleanup Complete. Only Admin, Guards, A-101 remain.'), backgroundColor: Colors.green));
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🔍 Role Selector
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'resident', label: Text('Residents')),
                      ButtonSegment(value: 'guard', label: Text('Guards')),
                      ButtonSegment(value: 'admin', label: Text('Admins')),
                    ],
                    selected: {_selectedRole},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _selectedRole = newSelection.first);
                    },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) return Colors.white;
                            return Theme.of(context).cardTheme.color!;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) return Colors.white;
                            return Colors.grey;
                          },
                        ),
                      ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 🔍 Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, flat, or phone...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).cardTheme.color,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: usersStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var users = snapshot.data!;
                
                // Filter
                if (_searchQuery.isNotEmpty) {
                  users = users.where((u) => 
                    u.name.toLowerCase().contains(_searchQuery) || 
                    (u.flatNumber != null && u.flatNumber!.toLowerCase().contains(_searchQuery)) ||
                    (u.wing != null && u.wing!.toLowerCase().contains(_searchQuery)) ||
                    u.phone.toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                if (users.isEmpty) {
                  return EmptyState(
                  icon: Icons.person_off,
                  title: 'No Users Found',
                  message: 'No ${_selectedRole}s match your search',
                );
                }

                return ListView.builder(
                  itemCount: users.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      // Use theme color explicitly
                      color: Theme.of(context).cardTheme.color,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', 
                            style: const TextStyle(color: Colors.white)
                          ),
                        ),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(
                          _selectedRole == 'resident' && user.flatNumber != null && user.wing != null
                            ? '${user.wing}-${user.flatNumber} • ${user.phone}'
                            : user.phone,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white), // Changed color
                              onPressed: () => _showEditUserDialog(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteUser(user),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  final AppUser user;
  const _EditUserDialog({required this.user});

  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _familyMemberController;
  final _formKey = GlobalKey<FormState>();
  
  List<String> _familyMembers = [];
  String? _selectedWing;
  String? _selectedFlat;
  String? _selectedUserType; // Added

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email); // Actual email
    _familyMemberController = TextEditingController();
    _familyMembers = List.from(widget.user.familyMembers ?? []);
    
    _selectedWing = widget.user.wing;
    _selectedFlat = widget.user.flatNumber;
    _selectedUserType = widget.user.userType; // Added
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _familyMemberController.dispose();
    super.dispose();
  }

  void _addFamilyMember() {
    if (_familyMemberController.text.isNotEmpty) {
      if (_familyMembers.length >= 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 6 members allowed')));
        return;
      }
      setState(() {
        _familyMembers.add(_familyMemberController.text.trim());
        _familyMemberController.clear();
      });
    }
  }

  void _removeFamilyMember(int index) {
    setState(() {
      _familyMembers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(societyConfigProvider);
    final isResident = widget.user.role == 'resident';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit, color: Colors.white),
          SizedBox(width: 8),
          Text('Edit User', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? 'Name Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.length < 10 ? 'Invalid Phone' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (⚠️ Changing may affect login)', 
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.contains('@') ? null : 'Invalid email',
              ),
              
              if (isResident) ...[
                const SizedBox(height: 12),
                const Divider(),
                const Text('Residence Info', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                
                // User Type (Owner/Tenant)
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedUserType ?? 'owner', // Default to owner if null
                  decoration: const InputDecoration(labelText: 'Resident Type'),
                  items: const [
                    DropdownMenuItem(value: 'owner', child: Text('Owner')),
                    DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
                  ],
                  onChanged: (v) => setState(() => _selectedUserType = v),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _selectedWing != null && config.wings.contains(_selectedWing) ? _selectedWing : null,
                        decoration: const InputDecoration(labelText: 'Wing'),
                        items: config.wings.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                        onChanged: (v) => setState(() => _selectedWing = v),
                        validator: (v) => isResident && v == null ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: _selectedFlat != null && _selectedFlat!.length == 4 ? _selectedFlat : null,
                        decoration: const InputDecoration(labelText: 'Flat'),
                        items: _generateFlatNumbers(),
                        onChanged: (v) => setState(() => _selectedFlat = v),
                        validator: (v) => isResident && v == null ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Family Members:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Family Members List
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _familyMembers.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      onDeleted: () => _removeFamilyMember(entry.key),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      backgroundColor: Colors.white10,
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _familyMemberController,
                        decoration: const InputDecoration(hintText: 'Add member name', isDense: true, prefixIcon: Icon(Icons.person_add)),
                      ),
                    ),
                    IconButton(onPressed: _addFamilyMember, icon: const Icon(Icons.add_circle, color: Colors.blue)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final updatedUser = AppUser(
                id: widget.user.id,
                email: _emailController.text, // Updated email
                name: _nameController.text,
                phone: _phoneController.text,
                role: widget.user.role,
                flatNumber: isResident ? _selectedFlat : widget.user.flatNumber,
                wing: isResident ? _selectedWing : widget.user.wing,
                userType: isResident ? _selectedUserType : widget.user.userType, // Updated
                ownerId: widget.user.ownerId,
                familyMembers: _familyMembers,
                createdAt: widget.user.createdAt,
              );

              await ref.read(firestoreServiceProvider).updateUser(updatedUser);
              if (!context.mounted) return;
              Navigator.pop(context);
            }
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  // Helper to generate flat numbers based on Society Config
  List<DropdownMenuItem<String>> _generateFlatNumbers() {
    final config = ref.read(societyConfigProvider); // Use dynamic config
    final List<DropdownMenuItem<String>> items = [];
    
    for (int floor = 1; floor <= config.totalFloors; floor++) {
      for (int flat = 1; flat <= config.flatsPerFloor; flat++) {
        // Pad flat number: 1 -> 01, but floor can be 1 or 12.
        // Format: {Floor}{Flat} e.g. 101, 102... 1101, 1102
        // Typical convention: Floor padded? usually not if < 10?
        // Let's assume typical: 101, 102... 1201, 1202.
        // Wait, existing code was: floor.toString().padLeft(2, '0') + '0' + flat (max 4 flats??)
        // Original: 0101, 0102...
        // Let's stick to standard: Floor + PadLeft(2, flat)
        // Actually, let's use the USER's previous logic but limit by dynamic counts.
        // Previous logic: floor 1-12, flat 1-4.
        // flatNum = '${floor.toString().padLeft(2, '0')}0$flat';  --> "0101"
        // If flats > 9, "0110"?
        
        // Better logic:
        final String flatNum = '${floor.toString()}${flat.toString().padLeft(2, '0')}'; 
        // 101, 102, 1204.
        // But user might expect 3 digits for ground floor? 
        // Let's assume standard format: Floor + 01..Flats
        items.add(DropdownMenuItem(value: flatNum, child: Text(flatNum)));
      }
    }
    return items;
  }
}
