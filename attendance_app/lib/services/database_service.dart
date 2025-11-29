import '../models/attendance_session.dart';
import '../models/attendance_record.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Mock database - replace with actual database
  final List<AttendanceSession> _sessions = [];
  final List<AttendanceRecord> _records = [];

  // Create attendance session
  Future<AttendanceSession> createSession(AttendanceSession session) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _sessions.add(session);
    return session;
  }

  // Get active sessions for a teacher
  Future<List<AttendanceSession>> getTeacherSessions(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _sessions.where((s) => s.teacherId == teacherId).toList();
  }

  // End session
  Future<void> endSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      final session = _sessions[index];
      _sessions[index] = AttendanceSession(
        id: session.id,
        teacherId: session.teacherId,
        subject: session.subject,
        className: session.className,
        section: session.section,
        startTime: session.startTime,
        endTime: DateTime.now(),
        qrCode: session.qrCode,
        isActive: false,
      );
    }
  }

  // Mark attendance
  Future<AttendanceRecord> markAttendance(AttendanceRecord record) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _records.add(record);
    return record;
  }

  // Get student attendance records
  Future<List<AttendanceRecord>> getStudentRecords(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _records.where((r) => r.studentId == studentId).toList();
  }

  // Get session attendance records
  Future<List<AttendanceRecord>> getSessionRecords(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _records.where((r) => r.sessionId == sessionId).toList();
  }

  // Verify session by QR code
  Future<AttendanceSession?> verifySession(String qrCode) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _sessions.firstWhere(
        (s) => s.qrCode == qrCode && s.isActive,
      );
    } catch (e) {
      return null;
    }
  }
}
