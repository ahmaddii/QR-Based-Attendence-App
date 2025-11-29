import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/teacher.dart';
import '../../widgets/attendance_card.dart';
import 'session_detail_screen.dart';

class TeacherHistoryScreen extends StatefulWidget {
  const TeacherHistoryScreen({super.key});

  @override
  State<TeacherHistoryScreen> createState() => _TeacherHistoryScreenState();
}

class _TeacherHistoryScreenState extends State<TeacherHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final teacher = authProvider.currentUser as Teacher?;

    if (teacher != null) {
      await attendanceProvider.loadTeacherSessions(teacher.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, child) {
          if (attendanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = attendanceProvider.sessions;

          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance sessions yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionDetailScreen(session: session),
                    ),
                  );
                },
                child: AttendanceCard(
                  title: session.subject,
                  subtitle: '${session.className} - ${session.section}',
                  date: session.startTime,
                  status: session.isActive ? 'Active' : 'Completed',
                  statusColor: session.isActive ? Colors.green : Colors.grey,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
