import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'user_dashboard_screen.dart';
import 'dashboard_screen.dart';
import 'volunteer_dashboard_screen.dart';

/// Three-role landing screen — the entry point after auth.
///
/// Routes to:
///  • User  → UserDashboardScreen
///  • Operations Dashboard → DashboardScreen (Command Center)
///  • Volunteer  → VolunteerDashboardScreen
class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigate(Widget screen) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 48),

                  // ── Logo ──────────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_hospital,
                      color: Colors.black,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Headline ──────────────────────────────────
                  const Text(
                    'MediLink AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose Your Role',
                    style: TextStyle(
                      color: AppColors.primary.withOpacity(0.85),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Connecting people, resources, and volunteers\nthrough AI-powered coordination',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.accent.withOpacity(0.6),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Role Cards ────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _RoleCard(
                            icon: Icons.person_outline,
                            title: 'User',
                            tagline: 'Find beds, oxygen, and emergency recommendations',
                            description: 'Ask AI for the best hospital for your emergency, view nearest available centers, and get real-time shortage alerts.',
                            gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                            delay: 0,
                            onTap: () => _navigate(const UserDashboardScreen()),
                          ),
                          const SizedBox(height: 16),
                          _RoleCard(
                            icon: Icons.dashboard_customize,
                            title: 'Operations Dashboard',
                            tagline: 'Monitor network health, update resources, manage AI transfers',
                            description: 'Access the command center to update hospital inventory, monitor shortage alerts, and review AI redistribution suggestions.',
                            gradient: const [Color(0xFFFFD700), Color(0xFFF59E0B)],
                            delay: 1,
                            onTap: () => _navigate(const DashboardScreen()),
                          ),
                          const SizedBox(height: 16),
                          _RoleCard(
                            icon: Icons.volunteer_activism,
                            title: 'Volunteer',
                            tagline: 'Accept missions, deliver resources, save lives',
                            description: 'See pending tasks, get matched to needs using intelligent proximity algorithms, coordinate deliveries, and track your community impact.',
                            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                            delay: 2,
                            onTap: () => _navigate(const VolunteerDashboardScreen()),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                  // ── Footer ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI Engine Active · Firebase Connected',
                          style: TextStyle(
                            color: AppColors.accent.withOpacity(0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                    ],
                  ),
                  Positioned(
                    top: 16,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<AppState>().authService.signOut();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(Icons.logout, color: Colors.white70, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Role Card Widget
// ────────────────────────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.tagline,
    required this.description,
    required this.gradient,
    required this.delay,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String tagline;
  final String description;
  final List<Color> gradient;
  final int delay;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.gradient.first;

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surface,
                _isPressed ? color.withOpacity(0.08) : AppColors.panel,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isPressed
                  ? color.withOpacity(0.5)
                  : color.withOpacity(0.2),
              width: _isPressed ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(_isPressed ? 0.15 : 0.06),
                blurRadius: _isPressed ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(widget.icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.tagline,
                      style: TextStyle(
                        color: color.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.accent.withOpacity(0.5),
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: color.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
