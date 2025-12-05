import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/firestore_service.dart';
import '../../models/user.dart';
import 'add_user_dialog.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _selectedRole = 'resident';
  String _searchQuery = '';

  void _showAddUserDialog() {
    showDialog(
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

  void _deleteUser(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete ${user.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(firestoreServiceProvider).deleteUser(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersStream = ref.watch(firestoreServiceProvider).getUsersByRole(_selectedRole);

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
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
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) return Colors.indigo;
                          return Theme.of(context).cardTheme.color!;
                        },
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.selected)) return Colors.white;
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

                if (users.isEmpty) return const Center(child: Text('No users found', style: TextStyle(color: Colors.white54)));

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
                          backgroundColor: Colors.indigo.shade900,
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
                              icon: const Icon(Icons.edit, color: Colors.blue),
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
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
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
  late TextEditingController _flatController;
  late TextEditingController _wingController;
  late TextEditingController _familyMemberController;
  List<String> _familyMembers = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _flatController = TextEditingController(text: widget.user.flatNumber ?? '');
    _wingController = TextEditingController(text: widget.user.wing ?? '');
    _familyMemberController = TextEditingController();
    _familyMembers = List.from(widget.user.familyMembers ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _flatController.dispose();
    _wingController.dispose();
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
    final isResident = widget.user.role == 'resident';

    return AlertDialog(
      title: const Text('Edit User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            
            if (isResident) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _wingController, decoration: const InputDecoration(labelText: 'Wing'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _flatController, decoration: const InputDecoration(labelText: 'Flat No'))),
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
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _familyMemberController,
                      decoration: const InputDecoration(hintText: 'Add member name', isDense: true),
                    ),
                  ),
                  IconButton(onPressed: _addFamilyMember, icon: const Icon(Icons.add_circle, color: Colors.blue)),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final updatedUser = AppUser(
              uid: widget.user.uid,
              name: _nameController.text,
              phone: _phoneController.text, // Correct field
              role: widget.user.role,
              flatNumber: isResident ? _flatController.text : widget.user.flatNumber,
              wing: isResident ? _wingController.text : widget.user.wing,
              userType: widget.user.userType,
              ownerId: widget.user.ownerId,
              familyMembers: _familyMembers,
              createdAt: widget.user.createdAt,
            );

            await ref.read(firestoreServiceProvider).updateUser(updatedUser);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
