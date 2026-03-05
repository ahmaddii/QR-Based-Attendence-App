import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/constants.dart';

class QRService {
  // Singleton pattern
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  // Generate QR code data for attendance session
  String generateQRData({
    required String sessionId,
    required String teacherId,
    required String subject,
    required String className,
    required String section,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'sessionId': sessionId,
      'teacherId': teacherId,
      'subject': subject,
      'class': className,
      'section': section,
      'timestamp': timestamp,
    };

    // Create a hash for verification
    final jsonData = jsonEncode(data);
    final bytes = utf8.encode(jsonData);
    final hash = sha256.convert(bytes);

    data['hash'] = hash.toString();

    return jsonEncode(data);
  }

  // Parse QR code data
  Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return null;
    }
  }

  // Validate QR code (check if not expired)
  bool isQRValid(String qrData,
      {Duration validityDuration = AppConstants.qrCodeRefreshInterval}) {
    final data = parseQRData(qrData);
    if (data == null) return false;

    final timestamp = data['timestamp'] as int?;
    if (timestamp == null) return false;

    final qrTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    return now.difference(qrTime) <= validityDuration;
  }
}
