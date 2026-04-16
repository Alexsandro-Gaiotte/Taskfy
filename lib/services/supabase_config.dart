import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ATENÇÃO: Substitua os valores abaixo pela URL e Anon Key do seu projeto Supabase
  static const String supabaseUrl = 'https://qzedhpartiznuekcsobz.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF6ZWRocGFydGl6bnVla2Nzb2J6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNDE0NjcsImV4cCI6MjA5MTgxNzQ2N30.N4mqh_bNiINX2ANU_NNRSNCNHRoMbdpDkSD802AmBOo';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
