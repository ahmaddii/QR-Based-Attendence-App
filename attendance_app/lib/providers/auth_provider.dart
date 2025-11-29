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
      } catch (e) {
        // Not a teacher
      }

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
      } catch (e) {
        // Not a student
      }
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

      if (response.user == null) {
        throw Exception('Login failed');
      }

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

      if (response.user == null) {
        throw Exception('Login failed');
      }

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

  // Register Teacher
  Future<bool> registerTeacher({
    required String email,
    required String password,
    required String name,
    required String employeeId,
    String? department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();

      // Enhanced email validation
      if (cleanEmail.isEmpty) {
        throw Exception('Email cannot be empty');
      }

      // Check email format more thoroughly
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(cleanEmail)) {
        throw Exception('Please enter a valid email address (e.g., user@example.com)');
      }

      // Check if email parts are valid
      final emailParts = cleanEmail.split('@');
      if (emailParts.length != 2) {
        throw Exception('Invalid email format');
      }
      
      final localPart = emailParts[0];
      final domainPart = emailParts[1];
      
      if (localPart.isEmpty || domainPart.isEmpty) {
        throw Exception('Invalid email format');
      }
      
      if (!domainPart.contains('.')) {
        throw Exception('Email domain must contain a dot (e.g., @gmail.com)');
      }

      final response = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Registration failed: Unable to create user account');
      }

      final teacherData = {
        'user_id': response.user!.id,
        'name': name,
        'email': cleanEmail,
        'employee_id': employeeId,
        'department': department,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(AppConstants.teachersTable).insert(teacherData);

      if (response.session != null) {
        _currentTeacher = Teacher(
          id: response.user!.id,
          name: name,
          email: cleanEmail,
          department: department ?? '',
          employeeId: employeeId,
        );
        _userRole = 'teacher';
      } else {
        final loginResponse = await _supabase.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        if (loginResponse.user != null) {
          _currentTeacher = Teacher(
            id: loginResponse.user!.id,
            name: name,
            email: cleanEmail,
            department: department ?? '',
            employeeId: employeeId,
          );
          _userRole = 'teacher';
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      // Handle Supabase auth exceptions specifically
      String errorMsg = e.message;
      
      if (e.message.contains('email_address_invalid') || 
          e.message.contains('Invalid email address')) {
        errorMsg = 'The email address format is not accepted. Please use a valid email format (e.g., name@domain.com)';
      } else if (e.message.contains('User already registered')) {
        errorMsg = 'This email is already registered. Please login instead.';
      } else if (e.message.contains('Password')) {
        errorMsg = 'Password does not meet requirements. Please use a stronger password.';
      }
      
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register Student
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

      // Enhanced email validation
      if (cleanEmail.isEmpty) {
        throw Exception('Email cannot be empty');
      }

      // Check email format more thoroughly
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(cleanEmail)) {
        throw Exception('Please enter a valid email address (e.g., user@example.com)');
      }

      // Check if email parts are valid
      final emailParts = cleanEmail.split('@');
      if (emailParts.length != 2) {
        throw Exception('Invalid email format');
      }
      
      final localPart = emailParts[0];
      final domainPart = emailParts[1];
      
      if (localPart.isEmpty || domainPart.isEmpty) {
        throw Exception('Invalid email format');
      }
      
      if (!domainPart.contains('.')) {
        throw Exception('Email domain must contain a dot (e.g., @gmail.com)');
      }

      final existingStudent = await _supabase
          .from(AppConstants.studentsTable)
          .select()
          .eq('roll_number', rollNumber)
          .maybeSingle();

      if (existingStudent != null) {
        throw Exception('Roll number already registered');
      }

      // Try to sign up with Supabase
      // Note: If you get "email_address_invalid" error, check Supabase Dashboard:
      // Authentication > Settings > Email Auth > and ensure email validation is not too strict
      final response = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        emailRedirectTo: null, // Disable email redirect if not needed
      );

      if (response.user == null) {
        throw Exception('Registration failed: Unable to create user account');
      }

      final studentData = {
        'user_id': response.user!.id,
        'name': name,
        'email': cleanEmail,
        'roll_number': rollNumber,
        'class_name': className,
        'section': section,
        'created_at': DateTime.now().toIso8601String(),
      };

      print('Inserting student data: $studentData');
      
      try {
        await _supabase.from(AppConstants.studentsTable).insert(studentData);
        print('Student data inserted successfully');
      } catch (insertError) {
        print('Error inserting student data: $insertError');
        // If insert fails, try to clean up the auth user
        try {
          // Note: We can't delete auth users from client, but we can log the error
          print('Warning: Student record insert failed, but auth user was created');
        } catch (e) {
          print('Error during cleanup: $e');
        }
        rethrow;
      }

      if (response.session != null) {
        _currentStudent = Student(
          id: response.user!.id,
          name: name,
          email: cleanEmail,
          rollNumber: rollNumber,
          className: className,
          section: section,
        );
        _userRole = 'student';
      } else {
        final loginResponse = await _supabase.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        if (loginResponse.user != null) {
          _currentStudent = Student(
            id: loginResponse.user!.id,
            name: name,
            email: cleanEmail,
            rollNumber: rollNumber,
            className: className,
            section: section,
          );
          _userRole = 'student';
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      // Handle Supabase auth exceptions specifically
      String errorMsg = e.message;
      
      if (e.message.contains('email_address_invalid') || 
          e.message.contains('Invalid email address')) {
        errorMsg = 'The email address format is not accepted. Please use a valid email format (e.g., name@domain.com)';
      } else if (e.message.contains('User already registered')) {
        errorMsg = 'This email is already registered. Please login instead.';
      } else if (e.message.contains('Password')) {
        errorMsg = 'Password does not meet requirements. Please use a stronger password.';
      }
      
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      String errorMsg = e.toString();
      
      // Handle specific database errors
      if (errorMsg.contains('permission denied for table users')) {
        errorMsg = 'Database permission error. Please check your Supabase RLS policies and database triggers. The students table may have a trigger that needs proper permissions.';
      } else if (errorMsg.contains('permission denied')) {
        errorMsg = 'Permission denied. Please check your Supabase Row Level Security (RLS) policies for the students table. Ensure authenticated users can INSERT records.';
      } else if (errorMsg.contains('duplicate key')) {
        errorMsg = 'This email or roll number is already registered. Please use a different email or roll number.';
      } else if (errorMsg.contains('violates foreign key')) {
        errorMsg = 'Registration failed: Invalid reference. Please contact support.';
      }
      
      print('Student registration error: $errorMsg');
      _errorMessage = errorMsg.replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
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

