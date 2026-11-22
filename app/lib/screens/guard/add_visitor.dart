import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/visitor.dart';
import '../../services/firestore_service.dart';

class AddVisitorScreen extends ConsumerStatefulWidget {
  const AddVisitorScreen({super.key});

  @override
  ConsumerState<AddVisitorScreen> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends ConsumerState<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  final _flatController = TextEditingController();
  String _selectedWing = 'A';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _purposeController.dispose();
    _flatController.dispose();
    super.dispose();
  }

  Future<void> _submitVisitor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final visitor = Visitor(
        id: const Uuid().v4(),
        wing: _selectedWing,
        flatNumber: _flatController.text.trim(),
        visitorName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        purpose: _purposeController.text.trim(),
        status: 'pending',
        entryTime: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).createVisitor(visitor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor notified successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding visitor: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Visitor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedWing,
                      decoration: const InputDecoration(labelText: 'Wing'),
                      items: ['A', 'B', 'C', 'D'].map((w) {
                        return DropdownMenuItem(value: w, child: Text(w));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedWing = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _flatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Flat Number'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Visitor Name'),
                validator: (val) => val == null || val.isEmpty ? 'Enter visitor name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(labelText: 'Purpose (Delivery, Guest, etc.)'),
                validator: (val) => val == null || val.isEmpty ? 'Enter purpose' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitVisitor,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('NOTIFY RESIDENT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
