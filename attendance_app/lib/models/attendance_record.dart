class AttendanceRecord {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final DateTime markedAt;
  final String status; // present, absent, late
  final String? subject;
  final String? className;
  final String? section;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.markedAt,
    required this.status,
    this.subject,
    this.className,
    this.section,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'studentId': studentId,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'markedAt': markedAt.toIso8601String(),
      'status': status,
      'subject': subject,
      'className': className,
      'section': section,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      sessionId: json['sessionId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      rollNumber: json['rollNumber'] ?? '',
      markedAt: DateTime.parse(json['markedAt']),
      status: json['status'] ?? 'present',
      subject: json['subject'],
      className: json['className'],
      section: json['section'],
    );
  }
}
