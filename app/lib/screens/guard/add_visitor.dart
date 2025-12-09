import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/visitor_request.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/society_config_service.dart';
import '../../utils/input_validator.dart';
import '../../utils/haptic_helper.dart';
import '../../widgets/loading_widgets.dart';

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
  final bool _isLoading = false;

  // Selection State
  String? _selectedWing;
  String _selectedPurpose = 'Delivery';

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
    if (_selectedWing == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Wing')));
      return;
    }
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo is required!')));
      return;
    }

    HapticHelper.lightImpact();
    LoadingOverlay.show(context, message: 'Creating visitor request...');

    try {
      final firestore = ref.read(firestoreServiceProvider);
      
      // 1. Validate Resident
      final flat = _flatController.text.trim();
      final residents = await firestore.getResidentsByFlat(_selectedWing!, flat);

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
        wing: _selectedWing!, // ✅ Added wing
        flatNumber: flat, // ✅ Changed to just flat number
        residentId: residents.first.id,
        guardId: currentUser?.id ?? '',
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await firestore.createVisitorRequest(request);

      // 🔔 Notify ALL residents of the flat (handled by notifyFlat)
      await ref.read(notificationServiceProvider).notifyFlat(
        wing: _selectedWing!,
        flatNumber: flat,
        title: '🔔 New Visitor!',
        message: '${request.visitorName} is waiting at $_selectedWing-$flat',
        visitorId: request.id,
      );

      LoadingOverlay.hide();
      if (mounted) {
        HapticHelper.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Request Sent & Resident Notified!'), backgroundColor: Colors.green, duration: Duration(seconds: 3)));
        Navigator.pop(context);
      }
    } catch (e) {
      LoadingOverlay.hide();
      if (mounted) {
        HapticHelper.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)));
      }
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
                    child: Consumer(
                      builder: (context, ref, _) {
                        final config = ref.watch(societyConfigProvider);
                        return DropdownButtonFormField<String>(
                          // ignore: deprecated_member_use
                          value: _selectedWing != null && config.wings.contains(_selectedWing) ? _selectedWing : null,
                          decoration: const InputDecoration(
                            labelText: 'Wing',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          items: config.wings.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                          onChanged: (v) => setState(() => _selectedWing = v!),
                        );
                      }
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
                validator: InputValidator.validateName,
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
                validator: InputValidator.validatePhone,
              ),

              const SizedBox(height: 24),
              
              // Purpose Dropdown with Emojis
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedPurpose,
                decoration: const InputDecoration(
                  labelText: 'Purpose of Visit',
                  prefixIcon: Icon(Icons.assignment),
                  border: OutlineInputBorder(),
                ),
               items: const [
                  DropdownMenuItem(value: 'Delivery', child: Text('🚚 Delivery')),
                  DropdownMenuItem(value: 'Guest', child: Text('👥 Guest')),
                  DropdownMenuItem(value: 'Cab', child: Text('🚕 Cab')),
                  DropdownMenuItem(value: 'Service', child: Text('🔧 Service')),
                  DropdownMenuItem(value: 'Other', child: Text('📦 Other')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedPurpose = val);
                },
                validator: (v) => v == null ? 'Select purpose' : null,
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
