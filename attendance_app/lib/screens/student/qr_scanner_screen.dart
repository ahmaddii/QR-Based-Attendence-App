import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/student.dart';
import '../../models/attendance_session.dart';
import '../../services/qr_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String qrData) async {
    setState(() {
      isProcessing = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final student = authProvider.currentUser as Student?;

    if (student == null) {
      _showMessage('Student not found', isError: true);
      setState(() {
        isProcessing = false;
      });
      return;
    }

    // Get the authenticated user ID from Supabase (this is what the foreign key expects)
    // The foreign key constraint expects the ID from auth.users table, not from students table
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    final studentUserId = currentUser?.id;

    if (studentUserId == null) {
      _showMessage('User not authenticated', isError: true);
      setState(() {
        isProcessing = false;
      });
      return;
    }

    print('Student ID from auth.users: $studentUserId');
    print('Student ID from model: ${student.id}');

    // Try to verify QR code - it could be a UUID directly or JSON
    AttendanceSession? session;
    
    print('Scanned QR Code: $qrData');
    
    // First try as direct QR code (UUID)
    session = await attendanceProvider.verifyQRCode(qrData);
    print('Session found (direct): ${session != null}');
    
    // If that fails, try parsing as JSON (if QR service format is used)
    if (session == null) {
      try {
        final qrService = QRService();
        final parsedData = qrService.parseQRData(qrData);
        if (parsedData != null && parsedData.containsKey('sessionId')) {
          final sessionId = parsedData['sessionId'] as String;
          print('Parsed sessionId from JSON: $sessionId');
          session = await attendanceProvider.verifyQRCode(sessionId);
          print('Session found (from JSON): ${session != null}');
        }
      } catch (e) {
        print('Error parsing QR as JSON: $e');
        // Not JSON format, continue
      }
    }

    if (session == null) {
      print('Session verification failed - QR code not found or session inactive');
      _showMessage('Invalid or expired QR code. Please scan a valid QR code from an active session.', isError: true);
      setState(() {
        isProcessing = false;
      });
      return;
    }
    
    print('Session verified: ${session.subject} - ${session.className} - ${session.section}');

    try {
      // Use the authenticated user ID (from Supabase auth) instead of student.id
      // This ensures the foreign key constraint is satisfied
      final success = await attendanceProvider.markAttendance(
        sessionId: session.id,
        studentId: studentUserId, // Use auth user ID, not student table ID
        studentName: student.name,
        rollNumber: student.rollNumber,
      );

      if (success) {
        _showMessage('Attendance marked successfully!', isError: false);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showMessage('Failed to mark attendance', isError: true);
        setState(() {
          isProcessing = false;
        });
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error marking attendance: $errorMessage');
      _showMessage('Error: $errorMessage', isError: true);
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (!isProcessing && barcode.rawValue != null) {
                        _handleScan(barcode.rawValue!);
                        break;
                      }
                    }
                  },
                ),
                // Custom overlay
                CustomPaint(
                  painter: QRScannerOverlay(
                    borderColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Container(),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black87,
              child: Center(
                child: isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Align QR code within the frame',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom overlay painter
class QRScannerOverlay extends CustomPainter {
  final Color borderColor;

  QRScannerOverlay({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final width = size.width;
    final height = size.height;
    final cutOutSize = 300.0;
    final left = (width - cutOutSize) / 2;
    final top = (height - cutOutSize) / 2;
    final right = left + cutOutSize;
    final bottom = top + cutOutSize;

    // Draw overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left, top, right, bottom),
          const Radius.circular(10),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw border
    final borderPath = Path()
      ..moveTo(left, top + 30)
      ..lineTo(left, top)
      ..lineTo(left + 30, top)
      ..moveTo(right - 30, top)
      ..lineTo(right, top)
      ..lineTo(right, top + 30)
      ..moveTo(right, bottom - 30)
      ..lineTo(right, bottom)
      ..lineTo(right - 30, bottom)
      ..moveTo(left + 30, bottom)
      ..lineTo(left, bottom)
      ..lineTo(left, bottom - 30);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
