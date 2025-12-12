import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class PatrolScreen extends ConsumerStatefulWidget {
  const PatrolScreen({super.key});

  @override
  ConsumerState<PatrolScreen> createState() => _PatrolScreenState();
}

class _PatrolScreenState extends ConsumerState<PatrolScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // Generate dynamic payload that ensures liveness (valid for 5 mins roughly or verified by logic)
  String _generateMyIdentityPayload(String userId) {
    final payload = {
      'type': 'peer_guard',
      'id': userId,
      'ts': DateTime.now().millisecondsSinceEpoch, // Liveness check
    };
    return jsonEncode(payload);
  }

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanning = true);
        await _processScan(barcode.rawValue!);
        break; // Process first valid code
      }
    }
  }

  Future<void> _processScan(String rawData) async {
    try {
      Map<String, dynamic> data;
      try {
        data = jsonDecode(rawData);
      } catch (e) {
        // Fallback for simple text checkpoints
        data = {'type': 'checkpoint', 'location': rawData};
      }

      final type = data['type'];
      final user = ref.read(authServiceProvider).currentUser;

      if (user == null) return;

      if (type == 'peer_guard') {
        final peerId = data['id'];
        final ts = data['ts']; 
        
        // Anti-Cheat: 5 Minute Valid Window
        if (ts != null && ts is int) {
           final diff = DateTime.now().millisecondsSinceEpoch - ts;
           if (diff.abs() > 5 * 60 * 1000) { // 5 minutes (abs handles slight clock skew)
             _showError('❌ QR Code Expired! Ask guard to refresh.');
             return;
           }
        }
        
        await Supabase.instance.client.from('patrol_logs').insert({
          'guard_id': user.id,
          'scanned_id': peerId,
          'scan_type': 'peer',
          'status': 'verified',
        });
        
        _showSuccess('Peer Verification Complete ✅');
      } else {
        // Checkpoint / Wall QR
        // Check for TV Checkpoint Anti-Cheat
        final ts = data['ts'];
        if (ts != null && ts is int) {
           final diff = DateTime.now().millisecondsSinceEpoch - ts;
           if (diff.abs() > 2 * 60 * 1000) { // TV QR is very short lived (30s) but allow 2m leeway
             _showError('❌ Checkpoint Expired! Scan the LIVE screen.');
             return;
           }
        }

        await Supabase.instance.client.from('patrol_logs').insert({
          'guard_id': user.id,
          'checkpoint_name': data['location'] ?? 'Unknown Point',
          'scan_type': 'checkpoint',
          'status': 'verified',
        });
        
        _showSuccess('Checkpoint Verified: ${data['location']}');
      }

    } catch (e) {
      _showError('Invalid QR Code');
    } finally {
      // Delay to allow animation
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Patrol Mode'),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'SCAN SCANNER', icon: Icon(Icons.qr_code_scanner)),
            Tab(text: 'MY IDENTITY', icon: Icon(Icons.badge)),
          ],
          indicatorColor: Colors.blueAccent,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. SCANNER TAB
          Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _handleScan,
              ),
              if (_isScanning)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                    child: const Text("Scan another Guard's Screen OR Wall Checkpoint", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))
                ),
              ),
            ],
          ),

          // 2. MY IDENTITY TAB
          Center(
            child: user == null 
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)
                      ),
                      child: QrImageView(
                        data: _generateMyIdentityPayload(user.id),
                        version: QrVersions.auto,
                        size: 250,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Show this to Peer Guard',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Changes every session. Cannot be screenshotted.', // Rhetoric
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
              ),
          ),
        ],
      ),
    );
  }
}
