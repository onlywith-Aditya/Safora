import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class HelpTypeBottomSheet extends StatelessWidget {
  const HelpTypeBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HelpTypeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.sosRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: AppColors.sosRed,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Choose Emergency Help',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Select the level of protection you need right now',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Option 1: Free SOS
          _buildHelpOptionCard(
            context: context,
            title: 'Free SOS',
            priceTag: 'FREE',
            priceColor: AppColors.safeGreen,
            badgeText: 'Basic Alert',
            badgeBgColor: const Color(0xFFE8F8EE),
            badgeTextColor: AppColors.safeGreen,
            description: 'Alert only her emergency contacts with live GPS coordinates and audio feed.',
            icon: Icons.family_restroom_rounded,
            iconColor: const Color(0xFF2E7D32),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.sos);
            },
          ),

          const SizedBox(height: 14),

          // Option 2: Volunteer Protection (₹500)
          _buildHelpOptionCard(
            context: context,
            title: 'Volunteer Protection',
            priceTag: '₹500',
            priceColor: AppColors.primary,
            badgeText: 'Recommended',
            badgeBgColor: AppColors.lightPinkCard,
            badgeTextColor: AppColors.primary,
            description: 'A verified volunteer comes to help her immediately in person (3-5 mins ETA).',
            icon: Icons.volunteer_activism_rounded,
            iconColor: AppColors.primary,
            isHighlighted: true,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.payment,
                arguments: {
                  'planName': 'Volunteer Protection',
                  'amount': 500,
                  'eta': '3-5 mins',
                  'description': 'Verified volunteer dispatched directly to your location',
                },
              );
            },
          ),

          const SizedBox(height: 14),

          // Option 3: Priority Protection (₹1000)
          _buildHelpOptionCard(
            context: context,
            title: 'Priority Protection',
            priceTag: '₹1000',
            priceColor: const Color(0xFFE65100),
            badgeText: 'Fastest Response',
            badgeBgColor: const Color(0xFFFFF3E0),
            badgeTextColor: const Color(0xFFE65100),
            description: 'Fastest response guaranteed. Top-priority multi-volunteer dispatch + instant police escalation.',
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFF57C00),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.payment,
                arguments: {
                  'planName': 'Priority Protection',
                  'amount': 1000,
                  'eta': '1-3 mins',
                  'description': 'Fastest guaranteed multi-response & priority dispatch',
                },
              );
            },
          ),

          const SizedBox(height: 14),

          // Quick Cancel
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpOptionCard({
    required BuildContext context,
    required String title,
    required String priceTag,
    required Color priceColor,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFFFFF7FA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted ? AppColors.primary : Colors.grey.shade200,
            width: isHighlighted ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        priceTag,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: priceColor,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
