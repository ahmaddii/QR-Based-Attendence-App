import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/teacher.dart';
import '../../widgets/custom_textfield.dart';
import '../../widgets/custom_button.dart';
import 'qr_display_screen.dart';

class StartAttendanceScreen extends StatefulWidget {
  const StartAttendanceScreen({super.key});

  @override
  State<StartAttendanceScreen> createState() => _StartAttendanceScreenState();
}

class _StartAttendanceScreenState extends State<StartAttendanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _classController = TextEditingController();
  final _sectionController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _classController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attendanceProvider =
          Provider.of<AttendanceProvider>(context, listen: false);
      final teacher = authProvider.currentUser as Teacher?;

      if (teacher == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher not found. Please login again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      try {
        final success = await attendanceProvider.startSession(
          teacherId: teacher.id,
          subject: _subjectController.text.trim(),
          className: _classController.text.trim(),
          section: _sectionController.text.trim(),
        );

        if (success && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const QRDisplayScreen(),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start session. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = e.toString().replaceFirst('Exception: ', '');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $errorMessage'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Attendance'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.qr_code,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Create Attendance Session',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in the details to generate QR code',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                CustomTextField(
                  controller: _subjectController,
                  label: 'Subject',
                  hint: 'e.g., Mathematics',
                  prefixIcon: Icons.book,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter subject name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _classController,
                  label: 'Class',
                  hint: 'e.g., CS-A',
                  prefixIcon: Icons.class_,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter class name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _sectionController,
                  label: 'Section',
                  hint: 'e.g., A',
                  prefixIcon: Icons.group,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter section';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Consumer<AttendanceProvider>(
                  builder: (context, attendanceProvider, child) {
                    return CustomButton(
                      text: 'Generate QR Code',
                      onPressed:
                          attendanceProvider.isLoading ? null : _startSession,
                      isLoading: attendanceProvider.isLoading,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
