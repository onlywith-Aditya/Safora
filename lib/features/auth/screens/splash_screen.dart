import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../routes/app_routes.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Entrance Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Timer for navigation (transitions to role selection screen)
    _timer = Timer(const Duration(milliseconds: 2500), () async {
      final isLoggedIn = await AuthService().tryAutoLogin();
      if (mounted) {
        if (isLoggedIn) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // -------------------------------------------------------------
          // BACKGROUND DECORATIVE ORBS
          // -------------------------------------------------------------

          // 1. Top-Left Soft Pink Orb
          Positioned(
            top: -size.width * 0.15,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.65,
              height: size.width * 0.65,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orbTopLeft,
              ),
            ),
          ),

          // 2. Middle-Right Soft Pink Orb
          Positioned(
            top: size.height * 0.20,
            right: -size.width * 0.18,
            child: Container(
              width: size.width * 0.45,
              height: size.width * 0.45,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orbMiddleRight,
              ),
            ),
          ),

          // 3. Bottom-Right Large Soft Pink Orb
          Positioned(
            bottom: -size.height * 0.08,
            right: -size.width * 0.22,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orbBottomRight,
              ),
            ),
          ),

          // -------------------------------------------------------------
          // CENTER CONTENT (App Logo, Titles & Loading Dots)
          // -------------------------------------------------------------
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Official Safora Logo Badge
                    _buildAppLogo(),

                    const SizedBox(height: 28),

                    // App Name Title
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 2.0,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Tagline / Subtitle
                    const Text(
                      AppStrings.appTagline,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 38),

                    // Three Animated Loading Dots
                    const _PulsingDotsIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// App Center Badge with Official Safora Logo Image & Soft Glow
  Widget _buildAppLogo() {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGlow,
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          AppStrings.logoPath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback gracefully to icon if asset is loading
            return Container(
              color: AppColors.primary,
              child: const Icon(
                Icons.shield_outlined,
                size: 54,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// THREE PULSING / BOUNCING DOTS WIDGET
// -------------------------------------------------------------
class _PulsingDotsIndicator extends StatefulWidget {
  const _PulsingDotsIndicator();

  @override
  State<_PulsingDotsIndicator> createState() => _PulsingDotsIndicatorState();
}

class _PulsingDotsIndicatorState extends State<_PulsingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.33;
            final progress = (_dotsController.value - delay) % 1.0;
            final opacity = (progress < 0.5)
                ? (0.3 + (progress * 1.4))
                : (1.0 - ((progress - 0.5) * 1.4));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(
                  alpha: opacity.clamp(0.25, 0.9),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
