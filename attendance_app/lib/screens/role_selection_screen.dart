// screens/role_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8EAF6),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo/Icon at top
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 50,
                    color: Color(0xFF1A237E),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
                
                const SizedBox(height: 32),
                
                Text(
                  'Welcome!',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3, end: 0),
                
                const SizedBox(height: 12),
                
                Text(
                  'Choose your role to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms),
                
                const SizedBox(height: 60),

                // Teacher Card
                RoleCard(
                  title: 'Teacher',
                  subtitle: 'Start attendance sessions',
                  icon: Icons.school_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF283593)],
                  ),
                  onTap: () => Navigator.pushNamed(context, '/teacher-login'),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3, end: 0),

                const SizedBox(height: 20),

                // Student Card
                RoleCard(
                  title: 'Student',
                  subtitle: 'Mark your attendance',
                  icon: Icons.person_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
                  ),
                  onTap: () => Navigator.pushNamed(context, '/student-login'),
                ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.3, end: 0),

                const Spacer(),

                // Bottom decoration
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1A237E).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Smart Attendance System v1.0',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// widgets/role_card.dart
class RoleCard extends StatefulWidget {
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
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(widget.icon, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}