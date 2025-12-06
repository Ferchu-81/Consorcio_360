import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Reemplaza estos valores con los que YA usabas en tu main.dart anterior
  static const String supabaseUrl = 'https://whgdymgatbkadyejvfhu.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndoZ2R5bWdhdGJrYWR5ZWp2Zmh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1OTA2MzEsImV4cCI6MjA3OTE2NjYzMX0.C22g5p2IS3idg0WksZ0PgnG1Er_K5d5iFdjB4pJlGX0';

  static SupabaseClient get client => Supabase.instance.client;
}


