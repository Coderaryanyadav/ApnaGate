
class SupabaseConfig {
  static const String supabaseUrl = 'https://jfsnnxrgrpmgdbuombba.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impmc25ueHJncnBtZ2RidW9tYmJhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwODYzMzMsImV4cCI6MjA4MDY2MjMzM30.l63-huBoyjeHvpFkiz57XZQa8RdUq4SmbCGD5QRUCEU';
  
  // OneSignal configuration
  static const String oneSignalAppId = '5e9deb0b-b39a-4259-ae19-5f9d05840b03'; 
  // static const String oneSignalRestApiKey = 'REMOVED_FOR_SECURITY_USE_EDGE_FUNCTIONS';

  // Aliases for compatibility with existing code
  static const String url = supabaseUrl;
  static const String anonKey = supabaseAnonKey;
}
