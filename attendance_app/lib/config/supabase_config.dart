class SupabaseConfig {
  // Supabase project credentials
  static const String supabaseUrl = 'https://sszhgdiflbebrppjlonp.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzemhnZGlmbGJlYnJwcGpsb25wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNzk3MTYsImV4cCI6MjA3OTk1NTcxNn0.u5uL3saGbM89xAdgD_8Xsb8QCdw3gcw8hqqhst2NaLA';
  
  // Check if credentials are configured
  static bool get isConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }
}
