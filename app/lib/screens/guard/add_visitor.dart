import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/visitor_request.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class AddVisitorScreen extends ConsumerStatefulWidget {
  const AddVisitorScreen({super.key});

  @override
  ConsumerState<AddVisitorScreen> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends ConsumerState<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _flatController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  // Selection State
  String _selectedWing = 'A';
  String _selectedPurpose = 'Delivery';
  final List<String> _purposes = ['Delivery', 'Guest', 'Cab', 'Service', 'Other'];

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50, // Optimize camera capture
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo is required!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = ref.read(firestoreServiceProvider);
      
      // 1. Validate Resident
      final flat = _flatController.text.trim();
      final residents = await firestore.getResidentsByFlat(_selectedWing, flat);

      if (residents.isEmpty) {
        throw Exception('No resident found in $_selectedWing - $flat');
      }

      // 2. Upload Photo (Base64)
      final photoUrl = await ref.read(storageServiceProvider).uploadVisitorPhoto(_imageFile!);
      if (photoUrl == null) throw Exception('Image processing failed');

      // 3. Create Request
      final currentUser = ref.read(authServiceProvider).currentUser;
      final request = VisitorRequest(
        id: const Uuid().v4(),
        visitorName: _nameController.text.trim(),
        visitorPhone: _phoneController.text.trim(),
        photoUrl: photoUrl,
        purpose: _selectedPurpose,
        flatNumber: '$_selectedWing-$flat', // Store full address
        residentId: residents.first.uid,
        guardId: currentUser?.uid ?? '',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await firestore.createVisitorRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request Sent!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Visitor Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    image: _imageFile != null 
                      ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                      : null,
                  ),
                  child: _imageFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Tap to Capture Photo', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Address Section (Wing + Flat)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedWing,
                      decoration: const InputDecoration(
                        labelText: 'Wing',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: ['A', 'B'].map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                      onChanged: (v) => setState(() => _selectedWing = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _flatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Flat No.',
                        hintText: 'e.g. 101',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // Personal Info
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Visitor Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Visitor Phone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              const Text('Purpose', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                children: _purposes.map((p) {
                  final isSelected = _selectedPurpose == p;
                  return ChoiceChip(
                    label: Text(p),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPurpose = p);
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  );
                }).toList(),
              ),

              const SizedBox(height: 32),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('NOTIFY RESIDENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
