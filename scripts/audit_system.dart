
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// 🕵️‍♂️ SYSTEM AUDIT & TEST SCRIPT
/// Tests: Database Connection, Resident Health, Notification Delivery (User & Guard), and SOS Routing.

// --- CONFIGURATION (UPDATED) ---
const supabaseUrl = 'https://jfsnnxrgrpmgdbuombba.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impmc25ueHJncnBtZ2RidW9tYmJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwODYzMzMsImV4cCI6MjA4MDY2MjMzM30.l63-huBoyjeHvpFkiz57XZQa8RdUq4SmbCGD5QRUCEU';
const oneSignalAppId = '5e9deb0b-b39a-4259-ae19-5f9d05840b03';
final oneSignalApiKey = Platform.environment['ONESIGNAL_REST_API_KEY'] ?? 'YOUR_ONESIGNAL_REST_API_KEY';

// Test Target
const targetWing = 'A';
const targetFlat = '1101';

Future<void> main() async {
  print('\n════════════════════════════════════════════════════════════');
  print('    🕵️‍♂️  APNA GATE: BRUTAL SYSTEM AUDIT  🕵️‍♂️');
  print('════════════════════════════════════════════════════════════\n');

  // 1. SUPABASE CHECK
  print('1️⃣  Checking Database Connection...');
  try {
    final response = await http.get(Uri.parse('$supabaseUrl/rest/v1/society_config?select=*'), headers: {
      'apikey': supabaseKey,
      'Authorization': 'Bearer $supabaseKey',
    });
    if (response.statusCode == 200) {
      print('   ✅ Database is ONLINE.');
    } else {
      print('   ❌ Database Error: ${response.statusCode}');
      exit(1);
    }
  } catch (e) {
    print('   ❌ Connection Failed: $e');
    exit(1);
  }

  // 2. RESIDENT HEALTH CHECK
  print('\n2️⃣  Checking Resident (A-1101) Status...');
  String? playerId;
  String? residentId;
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/profiles?wing=eq.$targetWing&flat_number=eq.$targetFlat&name=ilike.Aryan*&select=id,name,onesignal_player_id'),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
      },
    );
    final data = jsonDecode(response.body) as List;
    if (data.isNotEmpty) {
      final user = data.first;
      residentId = user['id'];
      playerId = user['onesignal_player_id'];
      print('   ✅ Resident Found: ${user['name']}');
      
      if (playerId != null && playerId!.length > 10) {
        print('   ✅ Device ID Present: ${playerId!.substring(0, 8)}...');
      } else {
        print('   ❌ CRITICAL: NO DEVICE ID! Notifications will FAIL.');
        print('      👉 Action: Open the app on the resident device to sync ID.');
      }
    } else {
      print('   ❌ Resident Not Found!');
      exit(1);
    }
  } catch (e) {
    print('   ❌ Error checking resident: $e');
  }

  // 3. VISITOR ARRIVAL NOTIFICATION (Resident Test)
  if (playerId != null) {
    print('\n3️⃣  Testing "Visitor Arrival" Notification (to Resident)...');
    await sendOneSignalPush(
      title: '🧪 Test: Visitor Arrival',
      message: 'If you see this, Visitor Notifications are FIXED.',
      targetPlayerIds: [playerId!],
      data: {'type': 'visitor_arrival', 'visitor_id': 'TEST_AUDIT'},
    );
  }

  // 4. SOS NOTIFICATION (Guard Test)
  print('\n4️⃣  Testing "SOS Alert" Notification (to Guards)...');
  // We target by Segment "Active Users" filtered by Tag "role=guard"
  await sendOneSignalPush(
    title: '🧪 Test: SOS Alert',
    message: 'Testing Guard Alert System. Please ignore.',
    targetTags: [{'field': 'tag', 'key': 'role', 'relation': '=', 'value': 'guard'}],
    data: {'type': 'sos_alert', 'wing': 'TEST', 'flat_number': '000'},
  );
  
  print('\n════════════════════════════════════════════════════════════');
  print('✅  AUDIT COMPLETE. CHECK YOUR DEVICES.');
  print('════════════════════════════════════════════════════════════\n');
}

Future<void> sendOneSignalPush({
  required String title,
  required String message,
  List<String>? targetPlayerIds,
  List<Map<String, dynamic>>? targetTags,
  Map<String, dynamic>? data,
}) async {
  final body = {
    'app_id': oneSignalAppId,
    'headings': {'en': title},
    'contents': {'en': message},
    'data': data ?? {},
    'android_sound': 'notification',
    'priority': 10,
  };

  if (targetPlayerIds != null) {
    // ⚠️ CRITICAL CHANGE: v5 SDK produces Subscription IDs, not legacy Player IDs.
    // The API requires 'include_subscription_ids' for these new IDs.
    body['include_subscription_ids'] = targetPlayerIds;
  } else if (targetTags != null) {
    body['filters'] = targetTags;
  }

  try {
    final response = await http.post(
      Uri.parse('https://onesignal.com/api/v1/notifications'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Basic $oneSignalApiKey',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('   ✅ Sent! Response: ${response.body}');
    } else {
      print('   ❌ Failed: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('   ❌ Exception: $e');
  }
}
