
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  const appId = '5e9deb0b-b39a-4259-ae19-5f9d05840b03';
  final apiKey = Platform.environment['ONESIGNAL_REST_API_KEY'] ?? 'YOUR_ONESIGNAL_REST_API_KEY';
  
  print('🚀 Testing OneSignal Notification...');
  print('App ID: $appId');
  print('API Key: ${apiKey.substring(0, 10)}...');

  final url = Uri.parse('https://onesignal.com/api/v1/notifications');
  
  final headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Authorization': 'Basic $apiKey',
  };

  final body = jsonEncode({
    'app_id': appId,
    'included_segments': ['Total Subscriptions'], // Broadcast to all for testing
    'headings': {'en': 'Test Notification'},
    'contents': {'en': 'This is a test from the debug script.'},
  });

  try {
    final response = await http.post(url, headers: headers, body: body);
    
    print('Response Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      print('✅ SUCCESS! Credentials are valid.');
    } else {
      print('❌ FAILED. Check API Key and App ID.');
    }
  } catch (e) {
    print('❌ EXCEPTION: $e');
  }
}
