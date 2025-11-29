import 'user.dart';

class Student extends User {
  final String rollNumber;
  final String className;
  final String section;

  Student({
    required super.id,
    required super.name,
    required super.email,
    required this.rollNumber,
    required this.className,
    required this.section,
  }) : super(role: 'student');

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['rollNumber'] = rollNumber;
    json['className'] = className;
    json['section'] = section;
    return json;
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? json['user_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      rollNumber: json['rollNumber'] ?? json['roll_number'] ?? '',
      className: json['className'] ?? json['class_name'] ?? '',
      section: json['section'] ?? '',
    );
  }
}
