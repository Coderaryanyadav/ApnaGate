import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/society_config_service.dart'; // Added
import '../../models/user.dart';
import '../../utils/input_validator.dart';
import '../../widgets/loading_widgets.dart';
import '../../utils/haptic_helper.dart';

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
    final config = ref.watch(societyConfigProvider); // Dynamic Config
    return AlertDialog(
      title: Text('Add ${widget.initialRole.toUpperCase()}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), validator: InputValidator.validateName),
            TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone, validator: InputValidator.validatePhone),
            TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress, validator: InputValidator.validateEmail),
            TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true, validator: InputValidator.validatePassword),
            
            if (widget.initialRole == 'resident') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _selectedWing,
                      decoration: const InputDecoration(labelText: 'Wing'),
                      items: config.wings.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                      onChanged: (v) => setState(() => _selectedWing = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _selectedFloor,
                      decoration: const InputDecoration(labelText: 'Floor'),
                      items: List.generate(config.totalFloors, (i) => (i + 1).toString())
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
                  // ignore: deprecated_member_use
                  value: _selectedFlat,
                  decoration: const InputDecoration(labelText: 'Flat'),
                  items: List.generate(config.flatsPerFloor, (i) {
                    final flatNum = '${_selectedFloor!.padLeft(2, '0')}0${i + 1}'; // Keep 01 format for now, or use _generateFlat helper logic?
                    return DropdownMenuItem(value: flatNum, child: Text(flatNum));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedFlat = v),
                ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _userType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'owner', child: Text('Owner')),
                  DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
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
        LoadingButton(
          label: 'Create',
          isLoading: _isLoading,
          onPressed: _submit,
          icon: Icons.person_add,
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
      // Create auth user (Admin-safe: Uses secondary app)
      final newUserId = await authService.createUser(_emailController.text, _passwordController.text);
      if (newUserId == null) throw Exception('Failed to create user');

      List<String>? members;
      if (_membersController.text.isNotEmpty) {
        members = _membersController.text.split(',').map((e) => e.trim()).take(6).toList();
      }

      await firestoreService.createUser(AppUser(
        id: newUserId,
        email: _emailController.text, // Pass email
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
        HapticHelper.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ User Created!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        HapticHelper.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
