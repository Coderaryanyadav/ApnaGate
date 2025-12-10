import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/guest_pass.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class GuestPassScreen extends ConsumerStatefulWidget {
  const GuestPassScreen({super.key});

  @override
  ConsumerState<GuestPassScreen> createState() => _GuestPassScreenState();
}

class _GuestPassScreenState extends ConsumerState<GuestPassScreen> {
  GuestPass? _currentPass;
  bool _isLoading = false;
  final _screenshotController = ScreenshotController();
  
  // Inputs
  final _nameController = TextEditingController();
  final _countController = TextEditingController(text: '1');
  final _infoController = TextEditingController();

  Future<void> _generatePass() async {
    if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter guest name')));
        return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      // 1. Pick Date
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      );
      if (date == null) { setState(() => _isLoading = false); return; }

      // 2. Pick Time
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time == null) { setState(() => _isLoading = false); return; }

      final validUntil = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      final count = int.tryParse(_countController.text) ?? 1;

      // 3. Create Pass (Get Token from backend)
      final token = await ref.read(firestoreServiceProvider).createGuestPass(
        residentId: user.id, 
        visitorName: _nameController.text.trim(),
        validUntil: validUntil,
        guestCount: count,
        additionalInfo: _infoController.text.trim(),
      );

      // 4. Update UI with Correct Token
      final pass = GuestPass(
        id: const Uuid().v4(), // Placeholder ID, not used in UI
        residentId: user.id,
        visitorName: _nameController.text.trim(), 
        validUntil: validUntil,
        token: token, 
        isUsed: false,
        createdAt: DateTime.now(),
        guestCount: count,
        additionalInfo: _infoController.text.trim(),
      );

      setState(() => _currentPass = pass);
    } catch (e) {
      if (mounted) {
        String msg = 'Unable to generate pass. Please check your connection and try again.';
        if (e.toString().contains('permission')) msg = 'Missing permissions.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sharePass() async {
    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/guest_pass.png').create();
      await imagePath.writeAsBytes(image);

      final text = '🔒 *ApnaGate Guest Pass*\n' // Updated name
                   'Guest: ${_currentPass!.visitorName}\n'
                   'Valid Until: ${_currentPass!.validUntil.toString().substring(0, 16)}\n'
                   'Token: ${_currentPass!.token}';

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(imagePath.path)], text: text);
    } catch (e) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Could not share pass. Please try taking a screenshot manually.'), backgroundColor: Colors.orange)
          );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(title: const Text('Gate Pass'), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        child: Container(
          // Min height to fill screen minus appbar
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 100),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Color(0xFF101015)],
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, 
            children: [
            if (_currentPass != null) ...[
              // ✨ HOLOGRAPHIC PASS CARD
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E), // Solid color for screenshot
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             const Text('GUEST PASS', style: TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold)),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                               child: const Text('ACTIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                             )
                          ],
                        ),
                        const SizedBox(height: 24),

                        // QR Container - CENTERED
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: _currentPass!.token,
                              version: QrVersions.auto,
                              size: 200,
                              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          _currentPass!.token,
                          style: const TextStyle(fontSize: 18, color: Colors.white, letterSpacing: 4, fontFamily: 'Courier', fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 16),

                        _buildDetailRow('GUEST', _currentPass!.visitorName),
                        const SizedBox(height: 8),
                        _buildDetailRow('GUESTS COUNT', '${_currentPass!.guestCount} Person(s)'),
                        const SizedBox(height: 8),
                        _buildDetailRow('VALID UNTIL', _currentPass!.validUntil.toString().substring(0, 16)),
                        if (_currentPass!.additionalInfo != null && _currentPass!.additionalInfo!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow('NOTE', _currentPass!.additionalInfo!),
                        ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ] else ...[
                // Input Form
               Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: const Color(0xFF1E1E1E),
                   borderRadius: BorderRadius.circular(24),
                   border: Border.all(color: Colors.white10),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start, 
                   children: [
                     const Text('New Guest Pass', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 24),
                     
                     TextField(
                       controller: _nameController,
                       style: const TextStyle(color: Colors.white),
                       decoration: _inputDecoration('Guest Name', Icons.person),
                     ),
                     const SizedBox(height: 16),
                     
                     TextField(
                       controller: _countController,
                       style: const TextStyle(color: Colors.white),
                       keyboardType: TextInputType.number,
                       decoration: _inputDecoration('Number of People', Icons.group),
                     ),
                     const SizedBox(height: 16),

                     TextField(
                       controller: _infoController,
                       style: const TextStyle(color: Colors.white),
                       decoration: _inputDecoration('Additional Note (Optional)', Icons.note),
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 32),
            ],
            
            // ACTION BUTTONS
            if (_currentPass != null)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'SHARE PASS',
                      icon: Icons.share,
                      color: Colors.green,
                      onTap: _sharePass,
                      isGradient: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      label: 'NEW PASS',
                      icon: Icons.refresh,
                      color: Colors.white12,
                      onTap: () => setState(() {
                        _currentPass = null;
                        _nameController.clear();
                        _countController.text = '1';
                        _infoController.clear();
                      }),
                    ),
                  ),
                ],
              )
            else
              _buildActionButton(
                label: _isLoading ? 'GENERATING...' : 'GENERATE PASS',
                icon: Icons.auto_awesome,
                color: Colors.blueAccent,
                onTap: _isLoading ? null : _generatePass,
                isGradient: true,
              ),

          ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent)),
      filled: true,
      fillColor: Colors.black54,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButton({
    required String label, 
    IconData? icon, 
    required Color color, 
    required VoidCallback? onTap,
    bool isGradient = false,
  }) {
    return SizedBox(
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: isGradient ? [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 5))
          ] : [],
          gradient: isGradient ? LinearGradient(colors: [color, color.withValues(alpha: 0.8)]) : null,
          color: isGradient ? null : color,
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: icon != null 
             ? (label == 'GENERATING...' 
                 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                 : Icon(icon, color: Colors.white))
             : const SizedBox.shrink(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
