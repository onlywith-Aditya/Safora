import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../fake_call/screens/fake_call_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  late AnimationController _sirenController;
  int _countdown = 5;
  Timer? _countdownTimer;
  bool _isDispatched = false;

  @override
  void initState() {
    super.initState();
    _sirenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        setState(() {
          _countdown = 0;
          _isDispatched = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _sirenController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E0A10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'EMERGENCY SOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Siren / Pulsing Radar Ring
              Column(
                children: [
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _sirenController,
                    builder: (context, child) {
                      return Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sosRed.withValues(
                            alpha: 0.15 + (0.25 * _sirenController.value),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sosRed.withValues(
                                alpha: 0.4 * _sirenController.value,
                              ),
                              blurRadius: 40,
                              spreadRadius: 15 * _sirenController.value,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [Color(0xFFFF2E40), Color(0xFFC70010)],
                              ),
                            ),
                            child: Center(
                              child: _countdown > 0
                                  ? Text(
                                      '$_countdown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.emergency_share_rounded,
                                      color: Colors.white,
                                      size: 54,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  Text(
                    _isDispatched
                        ? 'EMERGENCY ALERT DISPATCHED'
                        : 'DISPATCHING LIVE ALERT IN $_countdown SECONDS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _isDispatched ? AppColors.safeGreen : const Color(0xFFFF5268),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Live GPS coordinates and audio feed are actively being transmitted to emergency contacts & safety response team.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFC0B2B6),
                      height: 1.4,
                    ),
                  ),
                ],
              ),

              // Emergency Actions
              Column(
                children: [
                  // Call Police Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FakeCallScreen(
                              callerName: 'Police Emergency (112)',
                              callerNumber: 'Emergency Helpline • 112',
                              callerInitial: 'P',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.local_police_rounded, color: Colors.white),
                      label: const Text(
                        'Call Police (112)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Request Volunteer Protection Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
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
                      icon: const Icon(Icons.volunteer_activism_rounded, color: Colors.white),
                      label: const Text(
                        'Dispatch Volunteer (₹500)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // View Safe Route Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.safeRoute);
                      },
                      icon: const Icon(Icons.navigation_rounded, color: Colors.white70),
                      label: const Text(
                        'View Safe Route',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF55333E), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Cancel / Safe Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF55333E), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'I Am Safe (Cancel SOS)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
