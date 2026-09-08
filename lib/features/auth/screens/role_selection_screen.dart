import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Pink Header Banner
            _buildTopBanner(size),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Your Role',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Select how you want to use the Safora Women Safety Network.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 1. Emergency User Card (Direct to Home)
                  _buildRoleCard(
                    context: context,
                    title: 'Emergency User',
                    subtitle: 'Direct access to SOS button, live location sharing, fake call, and safety tools.',
                    badge: 'Instant Access',
                    badgeColor: AppColors.primary,
                    icon: Icons.shield_rounded,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.lightPinkCard,
                    borderColor: const Color(0xFFFFD4E2),
                    onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                    },
                  ),

                  const SizedBox(height: 18),

                  // 2. Volunteer Card (To Become a Volunteer flow)
                  _buildRoleCard(
                    context: context,
                    title: 'Join as Volunteer',
                    subtitle: 'Help women in distress nearby as a verified community responder.',
                    badge: 'Verified Network',
                    badgeColor: const Color(0xFF00897B),
                    icon: Icons.volunteer_activism_rounded,
                    iconColor: const Color(0xFF00897B),
                    iconBg: const Color(0xFFE0F2F1),
                    borderColor: const Color(0xFFB2DFDB),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.volunteerIntro);
                    },
                  ),

                  const SizedBox(height: 32),

                  // Footer note
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textMuted),
                        SizedBox(width: 6),
                        Text(
                          'Encrypted & 100% Private Safety Network',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildTopBanner(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.26,
      decoration: const BoxDecoration(
        color: AppColors.headerPink,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Center(
        child: Container(
          width: 115,
          height: 115,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/images/Logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.primary,
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
