import 'package:flutter_test/flutter_test.dart';
import 'package:app/supabase_config.dart';

void main() {
  group('SupabaseConfig Tests', () {
    test('Supabase URL is valid and non-empty', () {
      expect(SupabaseConfig.supabaseUrl, isNotEmpty);
      expect(SupabaseConfig.url, isNotEmpty);
      expect(Uri.parse(SupabaseConfig.supabaseUrl).isScheme('https'), isTrue);
    });

    test('Supabase Anon Key is configured', () {
      expect(SupabaseConfig.supabaseAnonKey, isNotEmpty);
      expect(SupabaseConfig.anonKey, isNotEmpty);
      // Ensure it's a valid JWT format (3 dot-separated parts)
      final parts = SupabaseConfig.supabaseAnonKey.split('.');
      expect(parts.length, 3);
    });

    test('OneSignal App ID is configured', () {
      expect(SupabaseConfig.oneSignalAppId, isNotEmpty);
    });
  });
}
