import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user.dart';

class AddUserDialog extends ConsumerStatefulWidget {
  final String initialRole;

  const AddUserDialog({super.key, required this.initialRole});

  @override
  ConsumerState<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<AddUserDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _membersController = TextEditingController();
  
  String? _selectedWing;
  String? _selectedFloor;
  String? _selectedFlat;
  String _userType = 'owner';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.initialRole.toUpperCase()}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            
            if (widget.initialRole == 'resident') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedWing,
                      decoration: const InputDecoration(labelText: 'Wing'),
                      items: ['A', 'B'].map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                      onChanged: (v) => setState(() => _selectedWing = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFloor,
                      decoration: const InputDecoration(labelText: 'Floor'),
                      items: List.generate(12, (i) => (i + 1).toString())
                          .map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (v) => setState(() {
                        _selectedFloor = v;
                        _selectedFlat = null;
                      }),
                    ),
                  ),
                ],
              ),
              if (_selectedFloor != null)
                DropdownButtonFormField<String>(
                  value: _selectedFlat,
                  decoration: const InputDecoration(labelText: 'Flat'),
                  items: List.generate(4, (i) {
                    final flatNum = '${_selectedFloor!.padLeft(2, '0')}0${i + 1}';
                    return DropdownMenuItem(value: flatNum, child: Text(flatNum));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedFlat = v),
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _userType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'owner', child: Text('Owner')),
                  DropdownMenuItem(value: 'renter', child: Text('Renter')),
                ],
                onChanged: (v) => setState(() => _userType = v!),
              ),
              TextField(
                controller: _membersController,
                decoration: const InputDecoration(labelText: 'Family (comma separated)', hintText: 'Aman, Priya'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (widget.initialRole == 'resident' && (_selectedWing == null || _selectedFlat == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select Wing & Flat')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);

      // Create auth user (Admin-safe: Uses secondary app)
      final uid = await authService.createUser(_emailController.text, _passwordController.text);
      if (uid == null) throw Exception('Failed to create user');

      List<String>? members;
      if (_membersController.text.isNotEmpty) {
        members = _membersController.text.split(',').map((e) => e.trim()).take(6).toList();
      }

      await firestoreService.createUser(AppUser(
        uid: uid,
        name: _nameController.text,
        phone: _phoneController.text,
        flatNumber: widget.initialRole == 'resident' ? _selectedFlat : null,
        wing: widget.initialRole == 'resident' ? _selectedWing : null,
        role: widget.initialRole,
        userType: widget.initialRole == 'resident' ? _userType : null,
        familyMembers: members,
        createdAt: DateTime.now(),
      ));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User Created!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
