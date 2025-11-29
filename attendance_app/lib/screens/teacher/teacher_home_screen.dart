// screens/teacher/teacher_home_screen.dart
import 'package:flutter/material.dart';
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
    // Defer loading until after the first frame is built
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        teacher?.name ?? 'Teacher',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/role-selection',
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Quick Stats Card
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
                  
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('Today', todayCount.toString(), Icons.today_rounded),
                            _buildStat(
                                'This Week', weekCount.toString(), Icons.calendar_today_rounded),
                            _buildStat('Total', totalCount.toString(), Icons.assessment_rounded),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Main Actions
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      context,
                      'Start Attendance',
                      Icons.qr_code_2_rounded,
                      const Color(0xFF4CAF50),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StartAttendanceScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      context,
                      'History',
                      Icons.history_rounded,
                      const Color(0xFF2196F3),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherHistoryScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      context,
                      'Reports',
                      Icons.analytics_rounded,
                      const Color(0xFFFF9800),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherReportsScreen(),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      context,
                      'Settings',
                      Icons.settings_rounded,
                      const Color(0xFF9C27B0),
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeacherSettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
