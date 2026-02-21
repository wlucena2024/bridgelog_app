import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://dftsujktpouhgruqvmxo.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRmdHN1amt0cG91aGdydXF2bXhvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzOTQxNzEsImV4cCI6MjA4MDk3MDE3MX0.cFhFUcNuHmjqZf6yh_8mEqdEfHpwXi8No8bmgHIh94Q';

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
