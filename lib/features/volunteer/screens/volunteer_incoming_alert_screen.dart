import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class VolunteerIncomingAlertScreen extends StatefulWidget {
  final Map<String, dynamic>? alertData;

  const VolunteerIncomingAlertScreen({super.key, this.alertData});

  @override
  State<VolunteerIncomingAlertScreen> createState() => _VolunteerIncomingAlertScreenState();
}

class _VolunteerIncomingAlertScreenState extends State<VolunteerIncomingAlertScreen>
    with SingleTickerProviderStateMixin {
  int _remainingSeconds = 60; // 60 seconds to respond
  Timer? _timer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        if (mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final victimName = widget.alertData?['userName'] ?? widget.alertData?['victimName'] ?? 'Sneha Kapoor';
    final earningAmount = widget.alertData?['amount'] ?? 500;
    final distance = widget.alertData?['distance'] ?? '420m';
    final alertType = widget.alertData?['planName'] ?? widget.alertData?['alertType'] ?? 'Volunteer Protection';
    final paymentId = widget.alertData?['paymentId'] ?? widget.alertData?['transactionId'] ?? 'SAF-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final userPhone = widget.alertData?['userPhone'] ?? widget.alertData?['phone'] ?? '+91 98765 43210';
    final userAddress = widget.alertData?['userLocation'] ?? widget.alertData?['location']?['address'] ?? widget.alertData?['address'] ?? 'Near Metro Pillar 42, Andheri West';

    return Scaffold(
      backgroundColor: const Color(0xFFE50914), // Urgent Alert Red
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Label: SOS ALERT NEARBY
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'URGENT EMERGENCY ALERT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Animated Hazard Circle
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF2A37),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15 + (_pulseController.value * 0.2)),
                          blurRadius: 24 + (_pulseController.value * 12),
                          spreadRadius: 6 + (_pulseController.value * 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Main Headline: Woman needs help
              const Text(
                'Woman Needs Urgent Help',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$victimName is requesting on-site protection ($alertType)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // Guaranteed Earning & Payment Verified Badge Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF2E7D32), size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Guaranteed Earning',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Paid by user & held in escrow',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          '₹$earningAmount',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 18, color: Color(0xFFEEEEEE)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, color: AppColors.textSecondary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Payment ID: $paymentId',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PAID / VERIFIED',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 3-Column Metrics Row: Distance, Direction, 60s Countdown
              Row(
                children: [
                  _buildMetricItem(distance, 'Distance'),
                  _buildMetricItem('↗ NE', 'Direction'),
                  _buildMetricItem(_formatTimer(_remainingSeconds), 'Time Left'),
                ],
              ),

              const SizedBox(height: 14),

              // User & Location Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFB50710).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$victimName ($userPhone)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            userAddress,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom Actions Row: Decline & Accept & Earn ₹500
              Row(
                children: [
                  // Decline Button
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          _timer?.cancel();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Alert declined. Passed to next nearest volunteer.'),
                              backgroundColor: Color(0xFF555B62),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white60, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Accept & Earn Button
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _timer?.cancel();
                          final payload = Map<String, dynamic>.from(widget.alertData ?? {});
                          payload['victimName'] = victimName;
                          payload['amount'] = earningAmount;
                          payload['alertType'] = alertType;
                          payload['distance'] = distance;
                          payload['address'] = userAddress;
                          payload['phone'] = userPhone;
                          payload['paymentId'] = paymentId;

                          Navigator.pushReplacementNamed(
                            context,
                            AppRoutes.volunteerTracking,
                            arguments: payload,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFB50710),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'Accept & Earn ₹$earningAmount',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB50710),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
