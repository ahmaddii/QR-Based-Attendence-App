class AttendanceSession {
  final String id;
  final String teacherId;
  final String subject;
  final String className;
  final String section;
  final DateTime startTime;
  final DateTime? endTime;
  final String qrCode;
  final bool isActive;

  AttendanceSession({
    required this.id,
    required this.teacherId,
    required this.subject,
    required this.className,
    required this.section,
    required this.startTime,
    this.endTime,
    required this.qrCode,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacher_user_id': teacherId,
      'subject': subject,
      'class_name': className,
      'section': section,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'qr_code': qrCode,
      'is_active': isActive,
    };
  }

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] ?? '',
      teacherId: json['teacher_user_id'] ?? json['teacherId'] ?? json['teacher_id'] ?? '',
      subject: json['subject'] ?? '',
      className: json['class_name'] ?? json['className'] ?? '',
      section: json['section'] ?? '',
      startTime: json['start_time'] != null 
          ? (json['start_time'] is String 
              ? DateTime.parse(json['start_time']) 
              : json['start_time'])
          : (json['startTime'] != null 
              ? (json['startTime'] is String 
                  ? DateTime.parse(json['startTime']) 
                  : json['startTime'])
              : DateTime.now()),
      endTime: json['end_time'] != null
          ? (json['end_time'] is String 
              ? DateTime.parse(json['end_time']) 
              : json['end_time'])
          : (json['endTime'] != null
              ? (json['endTime'] is String 
                  ? DateTime.parse(json['endTime']) 
                  : json['endTime'])
              : null),
      qrCode: json['qr_code'] ?? json['qrCode'] ?? '',
      isActive: json['is_active'] ?? json['isActive'] ?? false,
    );
  }
}