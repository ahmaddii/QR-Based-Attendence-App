import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import 'session_detail_screen.dart';

class TeacherReportsScreen extends StatefulWidget {
  const TeacherReportsScreen({super.key});

  @override
  State<TeacherReportsScreen> createState() => _TeacherReportsScreenState();
}

class _TeacherReportsScreenState extends State<TeacherReportsScreen> {
  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A237E),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
        ),
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, child) {
          if (attendanceProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1A237E),
                strokeWidth: 3,
              ),
            );
          }

          final sessions = attendanceProvider.sessions;

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No sessions to analyze',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start an attendance session to see reports',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          // Calculate statistics
          final totalSessions = sessions.length;
          final activeSessions = sessions.where((s) => s.isActive).length;
          final completedSessions = totalSessions - activeSessions;
          
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          final todaySessions = sessions.where((s) => 
            s.startTime.isAfter(todayStart) || 
            s.startTime.isAtSameMomentAs(todayStart)
          ).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistics Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A237E).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session Overview',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Your Attendance Analytics',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Statistics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total\nSessions',
                        totalSessions.toString(),
                        Icons.assessment_rounded,
                        const Color(0xFF1A237E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Active\nNow',
                        activeSessions.toString(),
                        Icons.play_circle_rounded,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Completed\nSessions',
                        completedSessions.toString(),
                        Icons.check_circle_rounded,
                        const Color(0xFFFF6F00),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Today\'s\nSessions',
                        todaySessions.toString(),
                        Icons.today_rounded,
                        const Color(0xFF7B1FA2),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Recent Sessions Header
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
                    Text(
                      'Recent Sessions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${sessions.length} Total',
                        style: const TextStyle(
                          color: Color(0xFF1A237E),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Sessions List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SessionDetailScreen(
                                  session: session,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Status Avatar
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: session.isActive
                                          ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                                          : [Colors.grey[600]!, Colors.grey[700]!],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (session.isActive
                                                ? const Color(0xFF4CAF50)
                                                : Colors.grey[600]!)
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    session.isActive
                                        ? Icons.play_arrow_rounded
                                        : Icons.check_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // Session Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.subject,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A237E),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.class_rounded,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${session.className} - ${session.section}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 12,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${session.startTime.day}/${session.startTime.month}/${session.startTime.year}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 12,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Status Badge & Arrow
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: session.isActive
                                            ? const Color(0xFF4CAF50).withOpacity(0.1)
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: session.isActive
                                              ? const Color(0xFF4CAF50).withOpacity(0.3)
                                              : Colors.grey[400]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        session.isActive ? 'ACTIVE' : 'DONE',
                                        style: TextStyle(
                                          color: session.isActive
                                              ? const Color(0xFF4CAF50)
                                              : Colors.grey[700],
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}