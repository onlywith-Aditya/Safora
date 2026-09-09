import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../fake_call/screens/fake_call_screen.dart';


class ClientVolunteerTrackingScreen extends StatefulWidget {
  final Map<String, dynamic>? alertData;

  const ClientVolunteerTrackingScreen({super.key, this.alertData});

  @override
  State<ClientVolunteerTrackingScreen> createState() => _ClientVolunteerTrackingScreenState();
}

class _ClientVolunteerTrackingScreenState extends State<ClientVolunteerTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _simulationTimer;

  int _etaSeconds = 180; // 3 minutes countdown
  int _distanceMeters = 420; // 420m away
  bool _hasArrived = false;
  bool _notifiedArrival = false;

  final String _volunteerName = 'Arjun Mehta';
  final String _volunteerPhone = '+91 98765 43210';
  final String _volunteerAffiliation = 'Verified NSS Safety Cadet';
  final double _volunteerRating = 4.9;
  final int _volunteerRescues = 14;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Live volunteer movement & arrival simulation
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_etaSeconds > 0) {
        setState(() {
          _etaSeconds -= 1;
          _distanceMeters = (_distanceMeters - 3).clamp(0, 420);
        });

        // Fast simulation for demo/feel if needed: when reaching 0, trigger arrival
        if (_distanceMeters <= 0 && !_hasArrived) {
          setState(() {
            _hasArrived = true;
          });
          _triggerArrivalNotification();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _triggerArrivalNotification() {
    if (_notifiedArrival) return;
    _notifiedArrival = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.safeGreen,
                size: 48,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Volunteer Has Arrived!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_volunteerName has arrived at your location. Please check your immediate surroundings.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _callVolunteer();
                    },
                    icon: const Icon(Icons.call_rounded, size: 18, color: Colors.white),
                    label: const Text('Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safeGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('I See Him', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _callVolunteer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FakeCallScreen(
          callerName: _volunteerName,
          callerNumber: 'Safety Volunteer • $_volunteerPhone',
          callerInitial: _volunteerName.isNotEmpty ? _volunteerName[0] : 'V',
        ),
      ),
    );
  }

  void _sendMessage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Message $_volunteerName',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickMessageChip(ctx, "I'm near the metro pillar"),
                _buildQuickMessageChip(ctx, "Wearing a black jacket"),
                _buildQuickMessageChip(ctx, "Please hurry, I feel unsafe"),
                _buildQuickMessageChip(ctx, "I'm inside the coffee shop"),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Type custom message to volunteer...',
                filled: true,
                fillColor: AppColors.inputBg,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message sent to volunteer'),
                        backgroundColor: AppColors.safeGreen,
                      ),
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMessageChip(BuildContext ctx, String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: AppColors.lightPinkCard,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () {
        Navigator.pop(ctx);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sent: "$text" to $_volunteerName'),
            backgroundColor: AppColors.safeGreen,
          ),
        );
      },
    );
  }

  void _resolveEmergency() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Resolve Emergency?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you safe and would you like to close this emergency response?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay Active', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.safeGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency resolved. Glad you are safe!'),
                  backgroundColor: AppColors.safeGreen,
                ),
              );
            },
            child: const Text('I Am Safe Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final etaMinutes = (_etaSeconds / 60).ceil();
    final progressFraction = (420.0 - _distanceMeters) / 420.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: const Color(0xFF1E0A10),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Volunteer En Route',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.sosRed.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sosRed, width: 1),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.emergency_rounded, color: AppColors.sosRed, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'LIVE SOS',
                          style: TextStyle(
                            color: AppColors.sosRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Live Map Area
          Expanded(
            child: Stack(
              children: [
                // Simulated Vector Map Canvas with Live Approaching Volunteer
                Container(
                  width: double.infinity,
                  color: const Color(0xFFEFF3F6),
                  child: CustomPaint(
                    painter: _LiveTrackingMapPainter(
                      progress: progressFraction,
                      pulseValue: _pulseController.value,
                    ),
                  ),
                ),

                // Top Live ETA Pill
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _hasArrived
                                ? const Color(0xFFE8F8EE)
                                : AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _hasArrived ? Icons.check_circle_rounded : Icons.directions_run_rounded,
                            color: _hasArrived ? AppColors.safeGreen : AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _hasArrived
                                    ? 'Volunteer Arrived at Location'
                                    : 'ETA $etaMinutes min (${_distanceMeters}m away)',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _hasArrived
                                    ? '$_volunteerName is nearby'
                                    : 'Approaching via Main Avenue',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _hasArrived ? AppColors.safeGreen : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_hasArrived) ...[
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _distanceMeters = 0;
                                _etaSeconds = 0;
                                _hasArrived = true;
                              });
                              _triggerArrivalNotification();
                            },
                            child: const Text(
                              'Test Arrival',
                              style: TextStyle(fontSize: 11, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Volunteer Profile & Quick Contact Sheet
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Volunteer Card Details
                  Row(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF2D8D), Color(0xFFFF629F)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'AM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.safeGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _volunteerName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7E6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFFFA502), size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        '$_volunteerRating',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFD68000),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_volunteerAffiliation • $_volunteerRescues Rescues',
                              style: const TextStyle(
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

                  const SizedBox(height: 18),

                  // Call & Message Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _callVolunteer,
                            icon: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
                            label: const Text(
                              'Call Volunteer',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.safeGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                            label: const Text(
                              'Message',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Resolve / Safe Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: _resolveEmergency,
                      child: const Text(
                        'I Am Safe (Complete Emergency)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Vector Canvas Painter to show live route and moving volunteer marker
class _LiveTrackingMapPainter extends CustomPainter {
  final double progress;
  final double pulseValue;

  _LiveTrackingMapPainter({
    required this.progress,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFDEE5EC)
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke;

    final routePaint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routeGlowPaint = Paint()
      ..color = const Color(0x332ECC71)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw Grid Roads
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.65), Offset(size.width, size.height * 0.65), roadPaint);
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), roadPaint);

    // Route Path from Volunteer Start (Top Right) to Woman Location (Bottom Left)
    final pStart = Offset(size.width * 0.75, size.height * 0.15);
    final pCorner1 = Offset(size.width * 0.75, size.height * 0.65);
    final pEnd = Offset(size.width * 0.25, size.height * 0.65);

    final path = Path();
    path.moveTo(pStart.dx, pStart.dy);
    path.lineTo(pCorner1.dx, pCorner1.dy);
    path.lineTo(pEnd.dx, pEnd.dy);

    canvas.drawPath(path, routeGlowPaint);
    canvas.drawPath(path, routePaint);

    // 1. Draw Woman Location (Target Beacon with Pulsing Rings)
    final womanRingPaint = Paint()
      ..color = AppColors.sosRed.withValues(alpha: 0.2 + (0.2 * pulseValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 + (8 * pulseValue);

    final womanDotPaint = Paint()..color = AppColors.sosRed;
    final womanInnerPaint = Paint()..color = Colors.white;

    canvas.drawCircle(pEnd, 18 + (6 * pulseValue), womanRingPaint);
    canvas.drawCircle(pEnd, 12, womanDotPaint);
    canvas.drawCircle(pEnd, 5, womanInnerPaint);

    // 2. Compute Live Volunteer Position along Path based on progress [0.0 -> 1.0]
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final distance = metric.length * progress.clamp(0.0, 1.0);
      final tangent = metric.getTangentForOffset(distance);
      final volunteerPos = tangent?.position ?? pStart;

      // Draw Volunteer Marker
      final volRingPaint = Paint()
        ..color = AppColors.primary.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      final volDotPaint = Paint()..color = AppColors.primary;
      final volCenterPaint = Paint()..color = Colors.white;

      canvas.drawCircle(volunteerPos, 16, volRingPaint);
      canvas.drawCircle(volunteerPos, 10, volDotPaint);
      canvas.drawCircle(volunteerPos, 4, volCenterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveTrackingMapPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulseValue != pulseValue;
  }
}
