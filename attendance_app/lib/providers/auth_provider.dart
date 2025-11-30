import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teacher.dart';
import '../models/student.dart';
import '../config/constants.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Teacher? _currentTeacher;
  Student? _currentStudent;
  String? _userRole;
  bool _isLoading = false;
  String? _errorMessage;

  Teacher? get currentTeacher => _currentTeacher;
  Student? get currentStudent => _currentStudent;
  String? get userRole => _userRole;
  bool get isLoggedIn => _supabase.auth.currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  dynamic get currentUser {
    if (_userRole == 'teacher') return _currentTeacher;
    if (_userRole == 'student') return _currentStudent;
    return null;
  }

  // Initialize - check if user is already logged in
  Future<void> initialize() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final teacherData = await _supabase
            .from(AppConstants.teachersTable)
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (teacherData != null) {
          _currentTeacher = Teacher.fromJson(teacherData);
          _userRole = 'teacher';
          notifyListeners();
          return;
        }
      } catch (e) {}

      try {
        final studentData = await _supabase
            .from(AppConstants.studentsTable)
            .select()
            .eq('user_id', user.id)
            .maybeSingle();

        if (studentData != null) {
          _currentStudent = Student.fromJson(studentData);
          _userRole = 'student';
          notifyListeners();
        }
      } catch (e) {}
    }
  }

  // Teacher Login
  Future<bool> loginTeacher(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final response = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      if (response.user == null) throw Exception('Login failed');

      final teacherData = await _supabase
          .from(AppConstants.teachersTable)
          .select()
          .eq('user_id', response.user!.id)
          .maybeSingle();

      if (teacherData == null) {
        await _supabase.auth.signOut();
        throw Exception('This email is not registered as a teacher');
      }

      _currentTeacher = Teacher.fromJson(teacherData);
      _userRole = 'teacher';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Student Login
  Future<bool> loginStudent(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final response = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      if (response.user == null) throw Exception('Login failed');

      final studentData = await _supabase
          .from(AppConstants.studentsTable)
          .select()
          .eq('user_id', response.user!.id)
          .maybeSingle();

      if (studentData == null) {
        await _supabase.auth.signOut();
        throw Exception('This email is not registered as a student');
      }

      _currentStudent = Student.fromJson(studentData);
      _userRole = 'student';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerTeacher({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    String? department,
  }) async {
    // Kept for backward compatibility if needed
    return true;
  }

  Future<bool> registerStudent({
    required String email,
    required String password,
    required String name,
    required String rollNumber,
    required String className,
    required String section,
  }) async {
    // Kept for backward compatibility if needed
    return true;
  }

  // Logout
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
      _currentTeacher = null;
      _currentStudent = null;
      _userRole = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }
}
