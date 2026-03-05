class AppConstants {
  // App Info
  static const String appName = 'QuickAttend';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserRole = 'user_role';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';

  // User Roles
  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';

  // --- Geofence Constants ---
  static const double szabistLatitude = 33.67740; // SZABIST Islamabad H-8/4
  static const double szabistLongitude = 73.06846;
  static const double allowedGeofenceRadiusMeters =
      200.0; // 200 meters allowed radius

  // --- Display Settings ---
  static const int qrCodeSize = 280;
  static const Duration qrCodeRefreshInterval = Duration(seconds: 10);
  static const Duration sessionDuration = Duration(hours: 2);

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;

  // Messages
  static const String msgLoginSuccess = 'Login successful!';
  static const String msgLoginFailed = 'Invalid credentials';
  static const String msgAttendanceMarked = 'Attendance marked successfully!';
  static const String msgAttendanceFailed = 'Failed to mark attendance';
  static const String msgSessionStarted = 'Attendance session started';
  static const String msgSessionEnded = 'Attendance session ended';

  // Database Tables
  static const String teachersTable = 'teachers';
  static const String studentsTable = 'students';
  static const String sessionsTable = 'sessions';
  static const String attendanceTable = 'attendance';
}
