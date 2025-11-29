// screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ).animate().fadeIn().slideY(begin: -0.3, end: 0),
              const SizedBox(height: 8),
              Text(
                'Choose your role to continue',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 60),

              // Teacher Card
              RoleCard(
                title: 'Teacher',
                subtitle: 'Start attendance sessions',
                icon: Icons.school_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                ),
                onTap: () => Navigator.pushNamed(context, '/teacher-login'),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.3, end: 0),

              const SizedBox(height: 24),

              // Student Card
              RoleCard(
                title: 'Student',
                subtitle: 'Mark your attendance',
                icon: Icons.person_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                onTap: () => Navigator.pushNamed(context, '/student-login'),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.3, end: 0),

              const Spacer(),

              Text(
                'Smart Attendance System v1.0',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// widgets/role_card.dart
class RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const RoleCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 40, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}
