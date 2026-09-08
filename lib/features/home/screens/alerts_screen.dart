import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';

class AlertsScreen extends StatelessWidget {
  final bool isStandalone;
  const AlertsScreen({super.key, this.isStandalone = false});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {
        'title': 'High Crowd Density Reported',
        'location': 'Near Andheri West Station',
        'time': '10 mins ago',
        'type': 'warning',
        'icon': Icons.warning_amber_rounded,
      },
      {
        'title': 'Safe Walk Check-in Successful',
        'location': 'Lokhandwala Complex',
        'time': '1 hour ago',
        'type': 'success',
        'icon': Icons.check_circle_outline_rounded,
      },
      {
        'title': 'Emergency SOS Test Dispatched',
        'location': 'Home Zone',
        'time': 'Yesterday, 8:40 PM',
        'type': 'sos',
        'icon': Icons.emergency_share_outlined,
      },
      {
        'title': 'New Police Patrol Booth Added',
        'location': 'Link Road, Andheri',
        'time': '2 days ago',
        'type': 'info',
        'icon': Icons.local_police_outlined,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: AppColors.headerPink,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () {
              if (isStandalone) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              }
            },
          ),
          title: const Text(
            'Safety & Alert Logs',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: false,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          Color badgeColor = AppColors.primary;
          Color iconColor = AppColors.primary;

          if (alert['type'] == 'warning') {
            badgeColor = const Color(0xFFFFF3E0);
            iconColor = AppColors.warningOrange;
          } else if (alert['type'] == 'success') {
            badgeColor = const Color(0xFFE8F8EE);
            iconColor = AppColors.safeGreen;
          } else if (alert['type'] == 'sos') {
            badgeColor = const Color(0xFFFFEBEE);
            iconColor = AppColors.sosRed;
          } else {
            badgeColor = AppColors.lightPinkCard;
            iconColor = AppColors.primary;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(alert['icon'] as IconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['title'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${alert['location']} • ${alert['time']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: 2, // Alerts Tab Active
          onTap: (idx) {
            if (idx == 0) {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            } else if (idx == 1) {
              Navigator.pushReplacementNamed(context, AppRoutes.contacts);
            } else if (idx == 3) {
              Navigator.pushReplacementNamed(context, AppRoutes.profile);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded),
              label: 'Contacts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
