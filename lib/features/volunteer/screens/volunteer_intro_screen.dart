import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class VolunteerIntroScreen extends StatelessWidget {
  const VolunteerIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6495), Color(0xFFFF8EB4)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Become a Volunteer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // Top Glowing Hot Pink App Icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF1D6B), Color(0xFFFF528E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4DFF1D6B),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.volunteer_activism_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Main Headline
                    const Text(
                      'Be the help that arrives first',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description text
                    const Text(
                      'When a woman near you sends an SOS, you can be notified instantly and reach her before authorities do. Verified volunteers only.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Feature Items
                    _buildFeatureItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Get nearby alerts',
                      description: "Only when you're on-duty and someone within range needs help.",
                    ),

                    const SizedBox(height: 18),

                    _buildFeatureItem(
                      icon: Icons.shield_outlined,
                      title: 'Privacy protected',
                      description: 'You see distance only, until you choose to accept.',
                    ),

                    const SizedBox(height: 18),

                    _buildFeatureItem(
                      icon: Icons.people_outline_rounded,
                      title: 'Verified community',
                      description: 'Every volunteer is ID-checked and approved before going live.',
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom CTA Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.volunteerVerification);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1D6B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0x66FF1D6B),
                      ),
                      child: const Text(
                        'Join as Volunteer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'By joining, you agree to respond responsibly and follow in-app safety guidance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.3,
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

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F2F2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF2B75), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
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
