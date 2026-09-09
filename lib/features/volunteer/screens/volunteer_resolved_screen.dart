import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class VolunteerResolvedScreen extends StatelessWidget {
  final String? victimName;
  final Map<String, dynamic>? resolvedData;

  const VolunteerResolvedScreen({
    super.key,
    this.victimName,
    this.resolvedData,
  });

  @override
  Widget build(BuildContext context) {
    final name = victimName ?? resolvedData?['victimName'] ?? 'The user';
    final amount = resolvedData?['amount'] ?? 500;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Green Check Circle
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5F7EB),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF27AE60),
                    size: 58,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              const Text(
                'Emergency Resolved!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                '$name is safe. Thank you for your swift on-site intervention as a verified safety volunteer.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // Earning Credited Card (Step 5: Earn Money)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rescue Earning',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF166534),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Added to Pending Earnings',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '+₹$amount',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFDCFCE7)),
                    Row(
                      children: const [
                        Icon(Icons.verified_outlined, color: Color(0xFF166534), size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Moves to Total Balance automatically upon safety confirmation.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Return to Dashboard Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.volunteerHome,
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Back to Dashboard & View Earnings',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
