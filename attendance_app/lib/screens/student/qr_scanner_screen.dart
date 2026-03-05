import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/attendance_session.dart';
import '../../services/qr_service.dart';
import '../../config/constants.dart';
import 'package:geolocator/geolocator.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;
  MobileScannerController _cameraController = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage(
          'Location services are disabled. Please enable them to mark attendance.',
          isError: true);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage('Location permissions are denied.', isError: true);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
          'Location permissions are permanently denied, we cannot request permissions.',
          isError: true);
      return;
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _handleScan(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);

    final student = authProvider.currentStudent;
    if (student == null) {
      _showMessage('Student not found', isError: true);
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    print('Processing QR scan for student: ${student.name}');
    print('Student ID from model: ${student.id}');

    try {
      // 1. Verify Format and Expiry First
      final qrService = QRService();
      final parsedData = qrService.parseQRData(qrData);

      if (parsedData == null) {
        _showMessage('Invalid QR code format.', isError: true);
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final isValid = qrService.isQRValid(qrData);

      if (!isValid) {
        _showMessage(
            'QR Code Expired. Please scan the current code on the board.',
            isError: true);
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // 2. Fetch User Location and Check Geofence
      _showMessage('Verifying location...', isError: false);

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
      } catch (e) {
        _showMessage('Could not get your location. Make sure GPS is on.',
            isError: true);
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        AppConstants.szabistLatitude,
        AppConstants.szabistLongitude,
      );

      print(
          'Student is $distanceInMeters meters away from SZABIST H-8/4 campus.');

      if (distanceInMeters > AppConstants.allowedGeofenceRadiusMeters) {
        _showMessage(
            'You are too far from campus (${distanceInMeters.toStringAsFixed(0)}m). You must be inside Szabist to mark attendance.',
            isError: true);
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // 3. Proceed with marking attendance
      AttendanceSession? session;

      if (parsedData.containsKey('session_id')) {
        final sessionId = parsedData['session_id'] as String;
        print('Parsed sessionId from valid JSON: $sessionId');
        session = await attendanceProvider.verifyQRCode(sessionId);
        print('Session found (from JSON): ${session != null}');
      }

      if (session == null) {
        _showMessage(
            'Invalid session. Please scan a valid QR code from an active session.',
            isError: true);
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Proceed to mark attendance using the found session
      final success = await attendanceProvider.markAttendance(
        sessionId: session.id,
        studentId: student.id, // Pass numeric student ID
      );

      if (success) {
        _showMessage('Attendance marked successfully!', isError: false);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        _showMessage('Failed to mark attendance', isError: true);
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error during attendance marking: $e');
      _showMessage('Error: $errorMessage', isError: true);
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mark Attendance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => _cameraController.toggleTorch(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
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
                  controller: _cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (!_isProcessing && barcode.rawValue != null) {
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
                if (_isProcessing)
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
