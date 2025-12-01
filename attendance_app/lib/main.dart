import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/teacher/teacher_login_screen.dart';
import 'screens/teacher/teacher_home_screen.dart';
import 'screens/student/student_login_screen.dart';
import 'screens/student/student_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Supabase is configured
  if (!SupabaseConfig.isConfigured) {
    print(' WARNING: Supabase credentials not configured!');
    print(
      'Please update lib/config/supabase_config.dart with your Supabase credentials.',
    );
    print(
      'Get your credentials from: https://supabase.com/dashboard/project/_/settings/api',
    );
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  } catch (e) {
    print('❌ Error initializing Supabase: $e');
    print(
      'Please check your Supabase configuration in lib/config/supabase_config.dart',
    );
    rethrow;
  }

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Attendance',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          textTheme: AppTheme.lightTheme.textTheme.apply(fontFamily: 'Poppins'),
        ),
        home: const SplashScreen(),
        routes: {
          '/role-selection': (context) => const RoleSelectionScreen(),
          '/teacher-login': (context) => const TeacherLoginScreen(),
          '/teacher-home': (context) => const TeacherHomeScreen(),
          '/student-login': (context) => const StudentLoginScreen(),
          '/student-home': (context) => const StudentHomeScreen(),
        },
      ),
    );
  }
}
