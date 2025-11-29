// providers/attendance_provider.dart (Supabase - Fixed Version)
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../config/constants.dart';

class AttendanceProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  List<AttendanceSession> _sessions = [];
  AttendanceSession? _activeSession;
  List<AttendanceRecord> _records = [];
  RealtimeChannel? _realtimeChannel;
  bool _isLoading = false;

  List<AttendanceSession> get sessions => _sessions;
  AttendanceSession? get activeSession => _activeSession;
  AttendanceSession? get currentSession => _activeSession;
  List<AttendanceRecord> get records => _records;
  bool get isLoading => _isLoading;

  // Create new attendance session
  Future<AttendanceSession> createSession({
    required String teacherId,
    required String subject,
    required String className,
    required String section,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final sessionId = _uuid.v4();
      final qrCode = _uuid.v4(); // Generate QR code
      final now = DateTime.now();

      final sessionData = {
        'id': sessionId,
        'teacher_user_id': teacherId,
        'subject': subject,
        'class_name': className,
        'section': section,
        'qr_code': qrCode,
        'start_time': now.toIso8601String(),
        'end_time': null,
        'is_active': true,
        'created_at': now.toIso8601String(),
      };

      // Insert session into database
      try {
        await _supabase.from(AppConstants.sessionsTable).insert(sessionData);
      } catch (insertError) {
        print('Database insert error: $insertError');
        print('Session data: $sessionData');
        rethrow;
      }

      final session = AttendanceSession(
        id: sessionId,
        teacherId: teacherId,
        subject: subject,
        className: className,
        section: section,
        qrCode: qrCode,
        startTime: now,
        isActive: true,
      );

      _activeSession = session;
      _sessions.insert(0, session);
      _isLoading = false;

      // Start listening for real-time updates
      _subscribeToAttendanceUpdates(sessionId);

      notifyListeners();

      return session;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error in createSession: $e');
      throw Exception('Failed to create session: ${e.toString()}');
    }
  }
  
  // Alias for createSession
  Future<bool> startSession({
    required String teacherId,
    required String subject,
    required String className,
    required String section,
  }) async {
    try {
      await createSession(
        teacherId: teacherId,
        subject: subject,
        className: className,
        section: section,
      );
      return true;
    } catch (e) {
      print('Error starting session: $e');
      rethrow;
    }
  }
  
  // Verify QR code and return session
  Future<AttendanceSession?> verifyQRCode(String qrCode) async {
    try {
      final sessionData = await _supabase
          .from(AppConstants.sessionsTable)
          .select()
          .eq('qr_code', qrCode)
          .eq('is_active', true)
          .maybeSingle();
      
      if (sessionData == null) {
        return null;
      }
      
      return AttendanceSession.fromJson({
        'id': sessionData['id'],
        'teacherId': sessionData['teacher_user_id'],
        'subject': sessionData['subject'] ?? '',
        'className': sessionData['class_name'] ?? '',
        'section': sessionData['section'] ?? '',
        'startTime': sessionData['start_time'],
        'endTime': sessionData['end_time'],
        'qrCode': sessionData['qr_code'] ?? '',
        'isActive': sessionData['is_active'] ?? false,
      });
    } catch (e) {
      return null;
    }
  }

  // Subscribe to real-time attendance updates for active session
  void _subscribeToAttendanceUpdates(String sessionId) {
    // Remove existing subscription if any
    _realtimeChannel?.unsubscribe();

    // Create new realtime subscription
    _realtimeChannel = _supabase
        .channel('attendance_$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: AppConstants.attendanceTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            // Real-time updates handled by database
            notifyListeners();
          },
        )
        .subscribe();
  }

  // Mark student attendance
  Future<bool> markAttendance({
    required String sessionId,
    required String studentId,
    String? studentName,
    String? rollNumber,
  }) async {
    try {
      print('Marking attendance - Session ID: $sessionId, Student ID: $studentId');
      
      // Check if session exists and is active
      final sessionResponse = await _supabase
          .from(AppConstants.sessionsTable)
          .select()
          .eq('id', sessionId)
          .maybeSingle();

      if (sessionResponse == null) {
        print('Error: Session not found with ID: $sessionId');
        throw Exception('Session not found');
      }

      final isActive = sessionResponse['is_active'] as bool;
      if (!isActive) {
        print('Error: Session is not active');
        throw Exception('Session is no longer active');
      }

      // Check if attendance already marked
      final existingRecord = await _supabase
          .from(AppConstants.attendanceTable)
          .select()
          .eq('session_id', sessionId)
          .eq('student_id', studentId)
          .maybeSingle();

      if (existingRecord != null) {
        print('Error: Attendance already marked for this student');
        throw Exception('Attendance already marked');
      }

      // Insert attendance record
      final attendanceData = {
        'id': _uuid.v4(),
        'session_id': sessionId,
        'student_id': studentId,
        'marked_at': DateTime.now().toIso8601String(),
      };
      
      print('Inserting attendance record: $attendanceData');
      
      try {
        await _supabase.from(AppConstants.attendanceTable).insert(attendanceData);
        print('Attendance marked successfully!');
      } catch (insertError) {
        print('Database insert error: $insertError');
        print('Attendance data: $attendanceData');
        rethrow;
      }

      // Update local state (realtime will also update, but this is immediate)
      notifyListeners();
      return true;
    } catch (e) {
      print('Error in markAttendance: $e');
      rethrow;
    }
  }

  // End session
  Future<void> endSession(String sessionId) async {
    try {
      await _supabase.from(AppConstants.sessionsTable).update({
        'is_active': false,
        'end_time': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);

      // Unsubscribe from realtime updates
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;

      if (_activeSession?.id == sessionId) {
        _activeSession = null;
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to end session: ${e.toString()}');
    }
  }

  // Fetch teacher's sessions with attendance count
  Future<void> fetchTeacherSessions(String teacherId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final sessionsData = await _supabase
          .from(AppConstants.sessionsTable)
          .select()
          .eq('teacher_user_id', teacherId)
          .order('start_time', ascending: false);

      _sessions = [];

      for (var sessionData in sessionsData) {
        final session = AttendanceSession.fromJson({
          'id': sessionData['id'],
          'teacherId': sessionData['teacher_user_id'],
          'subject': sessionData['subject'] ?? '',
          'className': sessionData['class_name'] ?? '',
          'section': sessionData['section'] ?? '',
          'startTime': sessionData['start_time'],
          'endTime': sessionData['end_time'],
          'qrCode': sessionData['qr_code'] ?? '',
          'isActive': sessionData['is_active'] ?? false,
        });

        _sessions.add(session);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to fetch sessions: ${e.toString()}');
    }
  }
  
  // Alias for fetchTeacherSessions
  Future<void> loadTeacherSessions(String teacherId) async {
    await fetchTeacherSessions(teacherId);
  }

  // Fetch student's attendance history
  Future<List<AttendanceRecord>> fetchStudentAttendance(
      String studentId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get all attendance records for this student
      // First get records, then fetch session details for each
      final attendanceRecords = await _supabase
          .from(AppConstants.attendanceTable)
          .select()
          .eq('student_id', studentId)
          .order('marked_at', ascending: false);

      // Get student info
      final studentData = await _supabase
          .from(AppConstants.studentsTable)
          .select()
          .eq('user_id', studentId)
          .maybeSingle();

      List<AttendanceRecord> records = [];

      for (var record in attendanceRecords) {
        // Fetch session details for each record
        final sessionId = record['session_id'] as String?;
        Map<String, dynamic>? sessionData;
        
        if (sessionId != null) {
          try {
            final sessionResponse = await _supabase
                .from(AppConstants.sessionsTable)
                .select()
                .eq('id', sessionId)
                .maybeSingle();
            sessionData = sessionResponse;
          } catch (e) {
            // Session might not exist, continue without it
          }
        }
        
        records.add(AttendanceRecord(
          id: record['id'] ?? '',
          sessionId: record['session_id'] ?? '',
          studentId: record['student_id'] ?? '',
          studentName: studentData?['name'] ?? '',
          rollNumber: studentData?['roll_number'] ?? '',
          markedAt: DateTime.parse(record['marked_at']),
          status: 'present',
          subject: sessionData?['subject'],
          className: sessionData?['class_name'],
          section: sessionData?['section'],
        ));
      }
      
      _records = records;
      _isLoading = false;
      notifyListeners();
      
      return records;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to fetch attendance: ${e.toString()}');
    }
  }
  
  // Alias for fetchStudentAttendance
  Future<void> loadStudentRecords(String studentId) async {
    await fetchStudentAttendance(studentId);
  }

  // Fetch attendance records for a specific session
  Future<List<AttendanceRecord>> fetchSessionAttendance(String sessionId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get all attendance records for this session
      final attendanceRecords = await _supabase
          .from(AppConstants.attendanceTable)
          .select()
          .eq('session_id', sessionId)
          .order('marked_at', ascending: false);

      List<AttendanceRecord> records = [];

      for (var record in attendanceRecords) {
        // Get student info
        final studentId = record['student_id'] as String?;
        Map<String, dynamic>? studentData;
        
        if (studentId != null) {
          try {
            final studentResponse = await _supabase
                .from(AppConstants.studentsTable)
                .select()
                .eq('user_id', studentId)
                .maybeSingle();
            studentData = studentResponse;
          } catch (e) {
            // Student might not exist
          }
        }

        // Get session info
        Map<String, dynamic>? sessionData;
        try {
          final sessionResponse = await _supabase
              .from(AppConstants.sessionsTable)
              .select()
              .eq('id', sessionId)
              .maybeSingle();
          sessionData = sessionResponse;
        } catch (e) {
          // Session might not exist
        }
        
        records.add(AttendanceRecord(
          id: record['id'] ?? '',
          sessionId: record['session_id'] ?? '',
          studentId: record['student_id'] ?? '',
          studentName: studentData?['name'] ?? 'Unknown',
          rollNumber: studentData?['roll_number'] ?? '',
          markedAt: DateTime.parse(record['marked_at']),
          status: 'present',
          subject: sessionData?['subject'],
          // Use student's class info if available, otherwise use session class info
          className: studentData?['class_name'] ?? sessionData?['class_name'],
          section: studentData?['section'] ?? sessionData?['section'],
        ));
      }
      
      _isLoading = false;
      notifyListeners();
      
      return records;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to fetch session attendance: ${e.toString()}');
    }
  }

  // Clean up realtime subscription when provider is disposed
  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
