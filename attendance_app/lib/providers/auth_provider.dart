// auth_provider.dart - WITH DEVICE BINDING ADDED AND DEVICE ID ON REGISTRATION

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
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

  String? get currentUserId {
    if (_userRole == 'teacher') return _currentTeacher?.id;
    if (_userRole == 'student') return _currentStudent?.id;
    return null;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // -------------------- DEVICE ID --------------------
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await deviceInfo.androidInfo;
      return info.id; // Android unique ID
    } else {
      final info = await deviceInfo.deviceInfo;
      return info.data.toString().hashCode.toString();
    }
  }

  // -------------------- INITIALIZE --------------------
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
      } catch (_) {}

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
      } catch (_) {}
    }
  }

  // -------------------- TEACHER LOGIN --------------------
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

  // -------------------- STUDENT LOGIN (DEVICE BINDING ADDED) --------------------
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

      // ----------- DEVICE BINDING CHECK -----------
      final currentDeviceId = await _getDeviceId();
      final savedDeviceId = studentData['device_id'];

      if (savedDeviceId == null || savedDeviceId.toString().isEmpty) {
        // First login → Bind device
        await _supabase.from(AppConstants.studentsTable).update(
            {'device_id': currentDeviceId}).eq('user_id', response.user!.id);
      } else if (savedDeviceId != currentDeviceId) {
        await _supabase.auth.signOut();
        throw Exception(
            'Login blocked.\nThis account is already linked to another device.');
      }

      // --------------------------------------------

      final updatedStudentData = await _supabase
          .from(AppConstants.studentsTable)
          .select()
          .eq('user_id', response.user!.id)
          .single();

      _currentStudent = Student.fromJson(updatedStudentData);
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

  // -------------------- OTP + TEACHER REGISTER --------------------

  Future<bool> sendTeacherOTP(String email) async {
    try {
      setLoading(true);
      setError(null);

      final cleanEmail = email.trim().toLowerCase();

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(cleanEmail)) {
        throw Exception('Please enter a valid email address');
      }

      final existingUser = await _supabase
          .from(AppConstants.teachersTable)
          .select('email')
          .eq('email', cleanEmail)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('This email is already registered');
      }

      await _supabase.auth.signInWithOtp(
        email: cleanEmail,
        emailRedirectTo: null,
      );

      setLoading(false);
      return true;
    } catch (e) {
      setError(e.toString().replaceFirst('Exception: ', ''));
      setLoading(false);
      return false;
    }
  }

  Future<bool> verifyAndRegisterTeacher({
    required String email,
    required String password,
    required String otp,
    required String name,
    required String employeeId,
    String? department,
  }) async {
    try {
      setLoading(true);
      setError(null);

      final cleanEmail = email.trim().toLowerCase();

      final authResponse = await _supabase.auth.verifyOTP(
        email: cleanEmail,
        token: otp,
        type: OtpType.email,
      );

      if (authResponse.user == null) {
        throw Exception('Invalid OTP. Please try again.');
      }

      await _supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      final teacherData = await _supabase
          .from(AppConstants.teachersTable)
          .insert({
            'user_id': authResponse.user!.id,
            'email': cleanEmail,
            'name': name,
            'employee_id': employeeId,
            'department': department,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      _currentTeacher = Teacher.fromJson(teacherData);
      _userRole = 'teacher';
      setLoading(false);
      return true;
    } catch (e) {
      try {
        await _supabase.auth.signOut();
      } catch (_) {}

      setError(e.toString().replaceFirst('Exception: ', ''));
      setLoading(false);
      return false;
    }
  }

  // -------------------- STUDENT REGISTER (DEVICE ID CAPTURED) --------------------
  Future<bool> registerStudent({
    required String email,
    required String password,
    required String name,
    required String rollNumber,
    required String className,
    required String section,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(cleanEmail)) {
        throw Exception('Please enter a valid email address');
      }

      final existingUser = await _supabase
          .from(AppConstants.studentsTable)
          .select('email')
          .eq('email', cleanEmail)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('This email is already registered');
      }

      final authResponse = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Registration failed. Please try again.');
      }

      // ----------------- GET DEVICE ID -----------------
      final deviceId = await _getDeviceId();

      final studentData = await _supabase
          .from(AppConstants.studentsTable)
          .insert({
            'user_id': authResponse.user!.id,
            'email': cleanEmail,
            'name': name,
            'roll_number': rollNumber,
            'class_name': className,
            'section': section,
            'device_id': deviceId, // <- DEVICE ID SAVED HERE
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

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

  // -------------------- LOGOUT --------------------
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
