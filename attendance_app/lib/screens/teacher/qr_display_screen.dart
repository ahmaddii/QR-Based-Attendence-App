import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/attendance_provider.dart';
import '../../config/constants.dart';
import 'dart:async';
import 'teacher_home_screen.dart';
import 'session_detail_screen.dart';
import '../../services/qr_service.dart';

class QRDisplayScreen extends StatefulWidget {
  const QRDisplayScreen({super.key});

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _qrTimer;
  String? _currentQRData;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // Defer initialization of QR code data until the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQRRotationTimer();
    });
  }

  void _startQRRotationTimer() {
    _generateQRData(); // Initial generation
    _qrTimer = Timer.periodic(AppConstants.qrCodeRefreshInterval, (timer) {
      if (mounted) {
        _generateQRData();
      }
    });
  }

  void _generateQRData() {
    final attendanceProvider =
        Provider.of<AttendanceProvider>(context, listen: false);
    final session = attendanceProvider.currentSession;

    if (session != null) {
      final qrService = QRService();
      setState(() {
        _currentQRData = qrService.generateQRData(
          sessionId: session.id,
          teacherId: session.teacherId,
          subject: session.subject,
          className: session.className,
          section: session.section,
        );
      });
    }
  }

  @override
  void dispose() {
    _qrTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final session = attendanceProvider.currentSession;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A237E),
        automaticallyImplyLeading: false,
        title: const Text(
          'Attendance QR Code',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // QR Code Card with Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          // Subject Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              session?.subject ?? 'Attendance',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Class Info
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A237E).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.class_rounded,
                                  color: const Color(0xFF1A237E),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${session?.className ?? ''} - ${session?.section ?? ''}',
                                  style: const TextStyle(
                                    color: Color(0xFF1A237E),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // QR Code - BIG!
                          if (_currentQRData != null)
                            QrImageView(
                              data: _currentQRData!,
                              version: QrVersions.auto,
                              size: 280,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF1A237E),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF1A237E),
                              ),
                            )
                          else
                            const SizedBox(
                              height: 280,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),

                          const SizedBox(height: 40),

                          // Info Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF4CAF50).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: Color(0xFF4CAF50),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Students can scan this QR code to mark their attendance',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  // View Attendance Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A237E).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (session != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SessionDetailScreen(session: session),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.people_rounded, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'View',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // End Session Button
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          // Show confirmation dialog
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: const [
                                  Icon(Icons.warning_rounded,
                                      color: Color(0xFFE53935)),
                                  SizedBox(width: 12),
                                  Text('End Session?'),
                                ],
                              ),
                              content: const Text(
                                'Are you sure you want to end this attendance session? This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE53935),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('End Session'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && session != null) {
                            await attendanceProvider.endSession(session.id);
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TeacherHomeScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.stop_circle_rounded, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'End',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
