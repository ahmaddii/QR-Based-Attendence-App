// screens/teacher/teacher_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import 'start_attendance_screen.dart';
import 'teacher_history_screen.dart';
import 'teacher_reports_screen.dart';
import 'teacher_settings_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({Key? key}) : super(key: key);

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Set status bar color to match theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSessions();
    });
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final teacher = authProvider.currentTeacher;
    
    if (teacher != null) {
      await attendanceProvider.fetchTeacherSessions(teacher.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final teacher = authProvider.currentTeacher;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with SafeArea
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  teacher?.name ?? 'Teacher',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Row(
                                      children: const [
                                        Icon(Icons.logout_rounded, color: Color(0xFFE53935)),
                                        SizedBox(width: 12),
                                        Text('Logout'),
                                      ],
                                    ),
                                    content: const Text(
                                      'Are you sure you want to logout?',
                                      style: TextStyle(height: 1.5),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFE53935),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                        ),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await authProvider.logout();
                                  if (context.mounted) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/role-selection',
                                      (route) => false,
                                    );
                                  }
                                }
                              },
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Stats Cards Row
                      Consumer<AttendanceProvider>(
                        builder: (context, attendanceProvider, child) {
                          final sessions = attendanceProvider.sessions;
                          final today = DateTime.now();
                          final todayStart = DateTime(today.year, today.month, today.day);
                          final weekStart = todayStart.subtract(Duration(days: today.weekday - 1));
                          
                          final todayCount = sessions.where((s) => 
                            s.startTime.isAfter(todayStart) || 
                            s.startTime.isAtSameMomentAs(todayStart)
                          ).length;
                          
                          final weekCount = sessions.where((s) => 
                            s.startTime.isAfter(weekStart) || 
                            s.startTime.isAtSameMomentAs(weekStart)
                          ).length;
                          
                          final totalCount = sessions.length;
                          
                          return Row(
                            children: [
                              Expanded(
                                child: _buildMiniStatCard(
                                  'Today',
                                  todayCount.toString(),
                                  Icons.today_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMiniStatCard(
                                  'This Week',
                                  weekCount.toString(),
                                  Icons.calendar_month_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMiniStatCard(
                                  'Total',
                                  totalCount.toString(),
                                  Icons.assessment_rounded,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Main Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Primary Action - Start Attendance (Full Width)
                  _buildPrimaryActionCard(
                    context,
                    'Start Attendance Session',
                    'Generate QR code for students',
                    Icons.qr_code_2_rounded,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StartAttendanceScreen(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Secondary Actions Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryActionCard(
                          'History',
                          Icons.history_rounded,
                          const Color(0xFF4CAF50),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TeacherHistoryScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSecondaryActionCard(
                          'Reports',
                          Icons.bar_chart_rounded,
                          const Color(0xFFFF6F00),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TeacherReportsScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSecondaryActionCard(
                          'Settings',
                          Icons.tune_rounded,
                          const Color(0xFF7B1FA2),
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TeacherSettingsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}