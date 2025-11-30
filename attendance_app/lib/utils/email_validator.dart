// Create this file: lib/utils/email_validator.dart

class EmailValidator {
  // SZABIST Email Domains
  static const String studentDomain = '@szabist-isb.pk';
  static const String teacherDomain = '@szabist-isb.edu.pk';

  /// Check if email is valid student email
  static bool isStudentEmail(String email) {
    return email.toLowerCase().trim().endsWith(studentDomain);
  }

  /// Check if email is valid teacher email  
  static bool isTeacherEmail(String email) {
    return email.toLowerCase().trim().endsWith(teacherDomain);
  }

  /// Get roll number from student email (e.g., 2380230@szabist-isb.pk -> 2380230)
  static String? getRollNumber(String email) {
    if (isStudentEmail(email)) {
      return email.split('@').first;
    }
    return null;
  }
}