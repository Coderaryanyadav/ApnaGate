
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// 🚀 TEST SCRIPT: FULL APP NOTIFICATION FLOW
/// This script checks:
/// 1. If we can find the resident (Aryan Yadav in A-1101) in Supabase.
/// 2. If that resident has a valid 'onesignal_player_id'.
/// 3. If we can successfully send a 'Visitor Arrival' push to that exact ID.

Future<void> main() async {
  // CONFIGURATION
  const supabaseUrl = 'https://jfsnnxrgrpmgdbuombba.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impmc25ueHJncnBtZ2RidW9tYmJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwODYzMzMsImV4cCI6MjA4MDY2MjMzM30.l63-huBoyjeHvpFkiz57XZQa8RdUq4SmbCGD5QRUCEU';
  
  const oneSignalAppId = '5e9deb0b-b39a-4259-ae19-5f9d05840b03';
  final oneSignalApiKey = Platform.environment['ONESIGNAL_REST_API_KEY'] ?? 'YOUR_ONESIGNAL_REST_API_KEY';

  print('\n🔵 STARTING NOTIFICATION AUDIT FOR: Aryan Yadav (A-1101) 🔵\n');

  // STEP 1: FIND RESIDENT & CHECK PLAYER ID
  print('1️⃣  Querying Supabase Config...');
  final queryUrl = Uri.parse('$supabaseUrl/rest/v1/profiles?wing=eq.A&flat_number=eq.1101&select=id,name,onesignal_player_id');
  
  String? playerId;
  String? residentName;

  try {
    final response = await http.get(
      queryUrl,
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final user = data.first;
        residentName = user['name'];
        playerId = user['onesignal_player_id'];
        
        print('   ✅ Found Resident: $residentName');
        if (playerId != null && playerId.length > 5) {
          print('   ✅ Found Player ID: $playerId');
        } else {
          print('   ❌ NO PLAYER ID FOUND! The user must open the new App-Release to sync it.');
          return; // Stop here if no ID
        }
      } else {
        print('   ❌ Resident Not Found in A-1101');
        return;
      }
    } else {
      print('   ❌ Supabase Error: ${response.statusCode}');
      return;
    }
  } catch (e) {
    print('   ❌ Exception during DB Check: $e');
    return;
  }

  // STEP 2: SEND TEST PUSH
  print('\n2️⃣  Sending Test Push to Device...');
  
  final notificationUrl = Uri.parse('https://onesignal.com/api/v1/notifications');
  final body = jsonEncode({
    'app_id': oneSignalAppId,
    'include_player_ids': [playerId], // Direct Target
    'headings': {'en': '🔔 TEST: Visitor Arrived!'},
    'contents': {'en': 'This confirms your app can receive background alerts.'},
    'data': {'type': 'visitor_arrival', 'visitor_id': 'TEST_123'},
    'android_sound': 'notification',
    'priority': 10,
  });

  try {
    final pushResponse = await http.post(
      notificationUrl,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Basic $oneSignalApiKey',
      },
      body: body,
    );

    print('   Response: ${pushResponse.statusCode}');
    print('   Body: ${pushResponse.body}');

    if (pushResponse.statusCode == 200) {
      final json = jsonDecode(pushResponse.body);
      if (json['recipients'] > 0) {
         print('\n✅ ✅ SUCCESS! Notification sent successfully to 1 device.');
      } else {
         print('\n❌ SENT BUT NO RECIPIENTS? OneSignal accepted it but found no valid tokens.');
      }
    } else {
      print('\n❌ FAILED to send notification.');
    }

  } catch (e) {
     print('   ❌ Exception Sending Push: $e');
  }
}
