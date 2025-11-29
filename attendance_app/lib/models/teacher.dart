import 'user.dart';

class Teacher extends User {
  final String department;
  final String employeeId;

  Teacher({
    required super.id,
    required super.name,
    required super.email,
    required this.department,
    required this.employeeId,
  }) : super(role: 'teacher');

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['department'] = department;
    json['employeeId'] = employeeId;
    return json;
  }

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] ?? json['user_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      department: json['department'] ?? '',
      employeeId: json['employeeId'] ?? json['employee_id'] ?? '',
    );
  }
}
