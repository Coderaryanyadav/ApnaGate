
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const supabaseUrl = 'https://jfsnnxrgrpmgdbuombba.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impmc25ueHJncnBtZ2RidW9tYmJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwODYzMzMsImV4cCI6MjA4MDY2MjMzM30.l63-huBoyjeHvpFkiz57XZQa8RdUq4SmbCGD5QRUCEU';

Future<void> main() async {
  print('1️⃣  Checking Database Schema for "onesignal_player_id"...');
  try {
    // Try to select the specific column
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/profiles?select=onesignal_player_id&limit=1'), 
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
      },
    );

    if (response.statusCode == 200) {
      print('   ✅ Column EXISTS and is readable.');
    } else {
      print('   ❌ STATUS: ${response.statusCode}');
      print('   ❌ ERROR: ${response.body}');
      print('   ⚠️ The column "onesignal_player_id" might be MISSING or RLS is blocking access.');
    }
  } catch (e) {
    print('   ❌ Exception: $e');
  }
}
