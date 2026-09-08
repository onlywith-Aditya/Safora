import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../routes/app_routes.dart';

class SafeRouteScreen extends StatelessWidget {
  const SafeRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: AppColors.headerPink,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Safe Route Navigator',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_location_rounded, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Live trip shared with emergency contacts'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Safety Score Banner
          _buildSafetyScoreBanner(),

          // Interactive Map Simulation Area
          Expanded(
            child: Stack(
              children: [
                _buildMapCanvas(),

                // Floating Turn-by-Turn Card
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildNavigationInstructionCard(),
                ),

                // Floating SOS Quick Button
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: AppColors.sosRed,
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.sos),
                    child: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Route Details Card & Action
          _buildBottomDetails(context),
        ],
      ),
    );
  }

  Widget _buildSafetyScoreBanner() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.safeGreen, width: 1),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_rounded, color: AppColors.safeGreen, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '96% Safe Route',
                      style: TextStyle(
                        color: AppColors.safeGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '• Well-Lit Streets',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Text(
            '12 min (1.8 km)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Simulated Map with Vector Grid, Safe Route Polyline, and Markers
  Widget _buildMapCanvas() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEFF3F6),
      child: CustomPaint(
        painter: _MapCanvasPainter(),
      ),
    );
  }

  Widget _buildNavigationInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.turn_right_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'In 200m, turn right onto Main Avenue',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'High CCTV density • Active streetlights',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.safeGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDetails(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildFeaturePill(Icons.local_police_outlined, '2 Police Booths'),
              const SizedBox(width: 10),
              _buildFeaturePill(Icons.videocam_outlined, '14 Safe CCTVs'),
              const SizedBox(width: 10),
              _buildFeaturePill(Icons.local_hospital_outlined, '1 Clinic'),
            ],
          ),
          const SizedBox(height: 18),
          CustomButton(
            text: 'Start Safe Walk Navigation',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Safe Walk navigation started. Live tracking on.'),
                  backgroundColor: AppColors.safeGreen,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lightPinkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Canvas Painter to render street grid and green safe polyline
class _MapCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final streetPaint = Paint()
      ..color = const Color(0xFFDEE5EC)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke;

    final routeGlowPaint = Paint()
      ..color = const Color(0x332ECC71)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routePaint = Paint()
      ..color = const Color(0xFF2ECC71)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw City Roads Grid
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), streetPaint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.7), streetPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), streetPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), streetPaint);

    // Draw Safe Route Polyline
    final path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.85);
    path.lineTo(size.width * 0.3, size.height * 0.3);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width * 0.7, size.height * 0.15);

    canvas.drawPath(path, routeGlowPaint);
    canvas.drawPath(path, routePaint);

    // Draw Start Location (Pulsing User Location)
    final userDotPaint = Paint()..color = AppColors.primary;
    final userRingPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final startPoint = Offset(size.width * 0.3, size.height * 0.85);
    canvas.drawCircle(startPoint, 16, userRingPaint);
    canvas.drawCircle(startPoint, 8, userDotPaint);

    // Draw End Destination Pin
    final endPoint = Offset(size.width * 0.7, size.height * 0.15);
    final endPinPaint = Paint()..color = const Color(0xFF27AE60);
    canvas.drawCircle(endPoint, 10, endPinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
