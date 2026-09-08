import 'dart:async';
import 'package:flutter/material.dart';
import '../../../routes/app_routes.dart';

class VolunteerIncomingAlertScreen extends StatefulWidget {
  const VolunteerIncomingAlertScreen({super.key});

  @override
  State<VolunteerIncomingAlertScreen> createState() => _VolunteerIncomingAlertScreenState();
}

class _VolunteerIncomingAlertScreenState extends State<VolunteerIncomingAlertScreen>
    with SingleTickerProviderStateMixin {
  int _remainingSeconds = 17;
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
    return Scaffold(
      backgroundColor: const Color(0xFFE50914), // Vibrant Alert Red
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Top Label: SOS ALERT NEARBY
              const Text(
                'SOS ALERT NEARBY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 36),

              // Animated Hazard Circle
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF2A37).withValues(alpha: 0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.15 + (_pulseController.value * 0.15)),
                          blurRadius: 20 + (_pulseController.value * 12),
                          spreadRadius: 4 + (_pulseController.value * 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Main Headline: Someone nearby needs help
              const Text(
                'Someone nearby needs help',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 36),

              // 3-Column Metrics Row: Distance, Direction, Auto-skip
              Row(
                children: [
                  _buildMetricItem('420m', 'Distance'),
                  _buildMetricItem('↗ NE', 'Direction'),
                  _buildMetricItem(_formatTimer(_remainingSeconds), 'Auto-skip'),
                ],
              ),
              const SizedBox(height: 36),

              // Privacy Protection Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFB50710).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Exact location and identity unlock only after you accept \u2014 this keeps every user\u2019s privacy protected.',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ),

              const Spacer(),

              // Bottom Actions Row: Can't Help & Accept and Respond
              Row(
                children: [
                  // Can't Help Button
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white60, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        child: const Text(
                          "Can't Help",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Accept & Respond Button
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _timer?.cancel();
                          Navigator.pushReplacementNamed(context, AppRoutes.volunteerTracking);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFB50710),
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Accept & Respond',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB50710),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
