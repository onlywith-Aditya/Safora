import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../fake_call/screens/fake_call_screen.dart';
import '../services/volunteer_service.dart';

class VolunteerTrackingScreen extends StatefulWidget {
  final Map<String, dynamic>? alertData;

  const VolunteerTrackingScreen({super.key, this.alertData});

  @override
  State<VolunteerTrackingScreen> createState() => _VolunteerTrackingScreenState();
}

class _VolunteerTrackingScreenState extends State<VolunteerTrackingScreen> {
  bool _isNavigating = false;
  bool _isArrived = false;

  void _callWoman(String name, String phone) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FakeCallScreen(
          callerName: name,
          callerNumber: 'Woman in Distress • $phone',
          callerInitial: name.isNotEmpty ? name[0] : 'W',
        ),
      ),
    );
  }

  void _handleMarkArrived() {
    setState(() {
      _isArrived = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as Arrived! Victim notified you are at the location.'),
        backgroundColor: AppColors.safeGreen,
      ),
    );
  }

  void _handleMarkResolved(String victimName, String location, int amount, String? paymentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.safeGreen),
            SizedBox(width: 8),
            Text('Confirm Safety', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text(
          'Confirm that $victimName is safe and the emergency situation has been successfully resolved.\n\n₹$amount will be added to your pending earnings.',
          style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await VolunteerService().logSosResponse(
                victimName: victimName,
                location: location,
                duration: '6 mins response',
                earnedAmount: amount,
                paymentId: paymentId,
              );
              if (mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.volunteerResolved,
                  arguments: {
                    'victimName': victimName,
                    'amount': amount,
                    'location': location,
                    'paymentId': paymentId,
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.safeGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Confirm & Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final victimName = widget.alertData?['victimName'] ?? widget.alertData?['userName'] ?? 'Sneha Kapoor';
    final amount = (widget.alertData?['amount'] as num?)?.toInt() ?? 500;
    final alertType = widget.alertData?['alertType'] ?? widget.alertData?['planName'] ?? 'Volunteer Protection';
    final address = widget.alertData?['address'] ?? widget.alertData?['userLocation'] ?? 'Near Metro Pillar 42, Andheri West, Mumbai';
    final phone = widget.alertData?['phone'] ?? widget.alertData?['userPhone'] ?? '+91 98765 12345';
    final distance = widget.alertData?['distance'] ?? '420m away';
    final paymentId = widget.alertData?['paymentId'] ?? widget.alertData?['transactionId'] ?? 'SAF-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: const Color(0xFFE50914),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  const Spacer(),
                  // Earning Confirmation Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Earn ₹$amount',
                      style: const TextStyle(
                        color: Color(0xFFB50710),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
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

                // Floating Status & Turn-by-Turn Card
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isArrived ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isArrived ? Icons.check_circle_rounded : Icons.navigation_rounded,
                            color: _isArrived ? AppColors.safeGreen : const Color(0xFFE50914),
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
                                _isArrived
                                    ? 'You Have Arrived on Scene'
                                    : (_isNavigating ? 'In 150m turn right onto Main Ave' : 'ETA 3 min • $distance'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isArrived ? 'Ensure victim safety & calm presence' : address,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
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
                ),
              ],
            ),
          ),

          // Bottom Sheet: Victim Info, Earning, Checklist, Actions
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
                  const SizedBox(height: 12),

                  // Victim Card: Avatar + Name + Earning Confirmed
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFCCD9),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            victimName.isNotEmpty ? victimName[0] : 'S',
                            style: const TextStyle(
                              color: Color(0xFFFF2D8D),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name & Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              victimName,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$alertType • $distance',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF757575),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Earning Amount Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Text(
                          '+₹$amount',
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Earning & Payment Confirmation Subtext
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE0B2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFFE65100), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Payment Verified: ₹$amount Paid • Ref: $paymentId',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick Action Buttons Row: Navigation & Call Woman
                  Row(
                    children: [
                      // Navigation Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() => _isNavigating = !_isNavigating);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_isNavigating ? 'Turn-by-turn navigation started' : 'Navigation paused'),
                                  backgroundColor: AppColors.primary,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: Icon(
                              _isNavigating ? Icons.navigation_rounded : Icons.directions_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            label: Text(
                              _isNavigating ? 'Navigating' : 'Navigation',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary, width: 1.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Call Woman Button
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _callWoman(victimName, phone),
                            icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                            label: const Text(
                              'Call Woman',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.safeGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Step 4: Arrived / Resolved Primary Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!_isArrived) {
                          _handleMarkArrived();
                        } else {
                          _handleMarkResolved(victimName, address, amount, paymentId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isArrived ? AppColors.safeGreen : const Color(0xFFE50914),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        elevation: 4,
                      ),
                      child: Text(
                        _isArrived ? 'Mark Resolved (Woman Safe) & Earn ₹$amount' : 'Mark "Arrived" at Scene',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
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

    const segments = 28;
    for (int i = 0; i < segments; i += 2) {
      final t1 = i / segments;
      final t2 = (i + 1) / segments;

      final p1 = _getQuadraticBezierPoint(start, controlPoint, end, t1);
      final p2 = _getQuadraticBezierPoint(start, controlPoint, end, t2);

      canvas.drawLine(p1, p2, routePaint);
    }

    // 4. Start Point (Volunteer Locator Marker)
    canvas.drawCircle(start, 14, Paint()..color = const Color(0x331976D2));
    canvas.drawCircle(start, 8, Paint()..color = Colors.white);
    canvas.drawCircle(start, 5, Paint()..color = const Color(0xFF1976D2));

    // 5. Destination Marker (Woman's Red Pin)
    _drawRedPin(canvas, end);
  }

  Offset _getQuadraticBezierPoint(Offset p0, Offset p1, Offset p2, double t) {
    final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
    final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
    return Offset(x, y);
  }

  void _drawRedPin(Canvas canvas, Offset position) {
    final pinPaint = Paint()..color = const Color(0xFFE51C23);
    canvas.drawCircle(Offset(position.dx, position.dy - 6), 9, pinPaint);

    final path = Path()
      ..moveTo(position.dx - 8, position.dy - 6)
      ..lineTo(position.dx + 8, position.dy - 6)
      ..lineTo(position.dx, position.dy + 5)
      ..close();
    canvas.drawPath(path, pinPaint);

    canvas.drawCircle(Offset(position.dx, position.dy - 6), 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
