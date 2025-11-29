// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:attendance_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AttendanceApp());

    // Verify that the splash screen is shown initially
    expect(find.text('Smart Attendance'), findsOneWidget);
    expect(find.text('QR-Based Attendance System'), findsOneWidget);
  });
}
