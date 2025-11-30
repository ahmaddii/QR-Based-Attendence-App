// screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';
import 'teacher/teacher_home_screen.dart';
import 'student/student_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  _checkAuthAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Initialize auth to check if user is already logged in
    await authProvider.initialize();
    
    if (!mounted) return;
    
    // Navigate based on auth state
    if (authProvider.isLoggedIn && authProvider.userRole != null) {
      if (authProvider.userRole == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherHomeScreen()),
        );
      } else if (authProvider.userRole == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // Deep Indigo
              Color(0xFF283593), // Indigo
              Color(0xFF3949AB), // Lighter Indigo
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                  .scale(duration: 3000.ms, begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
                  .then()
                  .scale(duration: 3000.ms, begin: const Offset(1.2, 1.2), end: const Offset(1, 1)),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                  .scale(duration: 4000.ms, begin: const Offset(1, 1), end: const Offset(1.3, 1.3))
                  .then()
                  .scale(duration: 4000.ms, begin: const Offset(1.3, 1.3), end: const Offset(1, 1)),
            ),
            
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // QR Code Icon with glowing effect
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5C6BC0).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ).animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack)
                      .fadeIn()
                      .then()
                      .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                  
                  const SizedBox(height: 40),
                  
                  // App Title
                  const Text(
                    'Smart Attendance',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ).animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                  
                  const SizedBox(height: 12),
                  
                  // Subtitle
                  Text(
                    'QR-Based Attendance System',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w300,
                    ),
                  ).animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 60),
                  
                  // Loading indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ).animate()
                      .fadeIn(delay: 700.ms, duration: 600.ms)
                      .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
                ],
              ),
            ),
            
            // Bottom branding
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    'Powered by Modern Technology',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 1,
                      fontWeight: FontWeight.w300,
                    ),
                  ).animate()
                      .fadeIn(delay: 900.ms, duration: 800.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}