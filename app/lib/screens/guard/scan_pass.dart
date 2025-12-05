import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/firestore_service.dart';

class ScanPassScreen extends ConsumerStatefulWidget {
  const ScanPassScreen({super.key});

  @override
  ConsumerState<ScanPassScreen> createState() => _ScanPassScreenState();
}

class _ScanPassScreenState extends ConsumerState<ScanPassScreen> {
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? token = barcodes.first.rawValue;
    if (token == null) return;

    setState(() => _isProcessing = true);

    try {
      // Direct Firestore query instead of Cloud Function
      final firestore = ref.read(firestoreServiceProvider);
      final pass = await firestore.getGuestPassByToken(token);

      if (!mounted) return;

      if (pass == null) {
        _showResult(false, 'Invalid Token', '');
        return;
      }

      if (pass.isUsed) {
        _showResult(false, 'Pass already used', '');
        return;
      }

      if (pass.validUntil.isBefore(DateTime.now())) {
        _showResult(false, 'Pass expired', '');
        return;
      }

      // Mark as used
      await firestore.markGuestPassUsed(pass.id);
      _showResult(true, 'ACCESS GRANTED', pass.visitorName);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
        );
         setState(() => _isProcessing = false);
      }
    }
  }

  void _showResult(bool isValid, String message, String visitor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isValid ? 'ACCESS GRANTED' : 'ACCESS DENIED'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: TextStyle(
              color: isValid ? Colors.green : Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
            if (isValid && visitor.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Visitor: $visitor'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isValid) {
                Navigator.pop(context);
              } else {
                 setState(() => _isProcessing = false);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Guest Pass')),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
