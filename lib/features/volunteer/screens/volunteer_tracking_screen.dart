import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../services/volunteer_service.dart';

class VolunteerTrackingScreen extends StatelessWidget {
  const VolunteerTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: const Color(0xFFE50914),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Responding to SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Upper Area: Live Map & Route Tracker
          Expanded(
            child: Stack(
              children: [
                // Map Background Grid
                Container(
                  width: double.infinity,
                  color: const Color(0xFFEEF5FA),
                  child: CustomPaint(
                    painter: _MapRoutePainter(),
                  ),
                ),

                // Floating ETA Badge
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'ETA 3 min \u2022 420m away',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Sheet: Victim Info, Checklist, Actions
          Container(
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Center drag pill handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Victim Card: Avatar + Name + Active badge
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFCCD9),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              color: Color(0xFFFF2D8D),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name & Details
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sneha K.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Manual SOS \u2022 Andheri West',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Active Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              '\u25CF',
                              style: TextStyle(
                                color: Color(0xFFE51C23),
                                fontSize: 10,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Color(0xFFE51C23),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // While Responding Guidance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WHILE RESPONDING',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF2D8D),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),

                        _buildCheckItem(
                          icon: Icons.check,
                          iconColor: const Color(0xFF10B981),
                          text: 'Call police / helpline as you head there',
                          textColor: const Color(0xFF0F5132),
                        ),
                        const SizedBox(height: 8),

                        _buildCheckItem(
                          icon: Icons.check,
                          iconColor: const Color(0xFF10B981),
                          text: 'Stay visible and be a calm presence',
                          textColor: const Color(0xFF0F5132),
                        ),
                        const SizedBox(height: 8),

                        _buildCheckItem(
                          icon: Icons.close_rounded,
                          iconColor: const Color(0xFFE51C23),
                          text: 'Don\u2019t attempt physical confrontation',
                          textColor: const Color(0xFF842029),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons Row: Call Police & Mark Arrived
                  Row(
                    children: [
                      // Call Police
                      Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dialing Emergency Helpline 112...'),
                                  backgroundColor: AppColors.sosRed,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFF6495), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: const Text(
                              'Call Police',
                              style: TextStyle(
                                color: Color(0xFFFF2D8D),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Mark Arrived
                      Expanded(
                        flex: 6,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF2D8D), Color(0xFFFF528E)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF2D8D).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              VolunteerService().logSosResponse(
                                victimName: 'Sneha K.',
                                location: 'Andheri West',
                              );
                              Navigator.pushReplacementNamed(context, AppRoutes.volunteerResolved);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: const Text(
                              'Mark Arrived',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Map Grid and Dotted Route
class _MapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFFDCE8F2)
      ..strokeWidth = 1.2;

    const step = 70.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Start & Destination points
    final start = Offset(size.width * 0.22, size.height * 0.65);
    final end = Offset(size.width * 0.78, size.height * 0.28);
    final controlPoint = Offset(size.width * 0.40, size.height * 0.50);

    // 3. Draw Dotted Curve Route
    final routePaint = Paint()
      ..color = const Color(0xFF1976D2)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Approximate dashed bezier curve
    const segments = 28;
    for (int i = 0; i < segments; i += 2) {
      final t1 = i / segments;
      final t2 = (i + 1) / segments;

      final p1 = _getQuadraticBezierPoint(start, controlPoint, end, t1);
      final p2 = _getQuadraticBezierPoint(start, controlPoint, end, t2);

      canvas.drawLine(p1, p2, routePaint);
    }

    // 4. Start Point (Volunteer Locator Marker)
    // Outer translucent blue circle
    canvas.drawCircle(
      start,
      14,
      Paint()..color = const Color(0x331976D2),
    );
    // Middle white circle
    canvas.drawCircle(
      start,
      8,
      Paint()..color = Colors.white,
    );
    // Inner solid blue circle
    canvas.drawCircle(
      start,
      5,
      Paint()..color = const Color(0xFF1976D2),
    );

    // 5. Destination Marker (Red Pin)
    _drawRedPin(canvas, end);
  }

  Offset _getQuadraticBezierPoint(Offset p0, Offset p1, Offset p2, double t) {
    final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
    final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  void _drawRedPin(Canvas canvas, Offset position) {
    // Red pin head
    final pinPaint = Paint()..color = const Color(0xFFE51C23);
    canvas.drawCircle(Offset(position.dx, position.dy - 6), 9, pinPaint);

    // Pin pointer triangle
    final path = Path()
      ..moveTo(position.dx - 8, position.dy - 6)
      ..lineTo(position.dx + 8, position.dy - 6)
      ..lineTo(position.dx, position.dy + 5)
      ..close();
    canvas.drawPath(path, pinPaint);

    // Pin white inner dot
    canvas.drawCircle(Offset(position.dx, position.dy - 6), 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
