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
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF43A047),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => controller.toggleTorch(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
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
                    borderColor: const Color(0xFF5C6BC0),
                  ),
                  child: Container(),
                ),
                // Processing overlay
                if (isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.7),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3949AB),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Processing...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3949AB).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF5C6BC0).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3949AB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Align QR code within frame',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Make sure the code is clear and well-lit',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final glowPaint = Paint()
      ..color = borderColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final width = size.width;
    final height = size.height;
    final cutOutSize = 280.0;
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
          const Radius.circular(20),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner borders with glow
    final cornerLength = 40.0;
    final borderPath = Path()
      // Top-left
      ..moveTo(left, top + cornerLength)
      ..lineTo(left, top + 10)
      ..arcToPoint(
        Offset(left + 10, top),
        radius: const Radius.circular(10),
      )
      ..lineTo(left + cornerLength, top)
      // Top-right
      ..moveTo(right - cornerLength, top)
      ..lineTo(right - 10, top)
      ..arcToPoint(
        Offset(right, top + 10),
        radius: const Radius.circular(10),
      )
      ..lineTo(right, top + cornerLength)
      // Bottom-right
      ..moveTo(right, bottom - cornerLength)
      ..lineTo(right, bottom - 10)
      ..arcToPoint(
        Offset(right - 10, bottom),
        radius: const Radius.circular(10),
      )
      ..lineTo(right - cornerLength, bottom)
      // Bottom-left
      ..moveTo(left + cornerLength, bottom)
      ..lineTo(left + 10, bottom)
      ..arcToPoint(
        Offset(left, bottom - 10),
        radius: const Radius.circular(10),
      )
      ..lineTo(left, bottom - cornerLength);

    canvas.drawPath(borderPath, glowPaint);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}