import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../services/volunteer_service.dart';

class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key});

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen> with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  bool _isOnDuty = true; // Active by default to listen for alerts
  late AnimationController _radarController;
  final VolunteerService _volunteerService = VolunteerService();
  Map<String, dynamic>? _volunteerData;
  List<Map<String, dynamic>> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final data = await _volunteerService.loadVolunteerProfile();
    final history = await _volunteerService.getVolunteerHistory();
    final duty = await _volunteerService.loadVolunteerProfile().then((d) => d['dutyStatus'] != 'off_duty');
    if (mounted) {
      setState(() {
        _volunteerData = data;
        _historyList = history;
        _isOnDuty = duty;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _toggleDuty(bool value) {
    setState(() {
      _isOnDuty = value;
    });

    _volunteerService.updateDutyStatus(value);

    if (value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You are ON duty. Listening for SOS alerts from females nearby.'),
          backgroundColor: AppColors.safeGreen,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Test SOS',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.volunteerIncomingAlert);
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Log Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out from the Volunteer account?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _volunteerService.logoutVolunteer();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.roleSelection,
        (route) => false,
      );
    }
  }

  void _showEditProfileDialog() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController(
      text: _volunteerData?['fullName'] ?? _volunteerData?['name'] ?? '',
    );
    final phoneController = TextEditingController(
      text: _volunteerData?['phone'] ?? '',
    );
    final institutionController = TextEditingController(
      text: _volunteerData?['institution'] ?? '',
    );
    String affiliation = _volunteerData?['affiliation'] ?? 'College / Campus (NSS-NCC)';

    final affiliationsList = [
      'College / Campus (NSS-NCC)',
      'Registered NGO / Foundation',
      'Community Watch / Resident',
      'Emergency & Disaster Response',
      'Individual Guardian',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Volunteer Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildModalFieldLabel('Full Name'),
                const SizedBox(height: 6),
                _buildModalTextField(
                  controller: nameController,
                  icon: Icons.person_outline_rounded,
                  hint: 'Full Name',
                ),
                const SizedBox(height: 14),

                _buildModalFieldLabel('Phone Number'),
                const SizedBox(height: 6),
                _buildModalTextField(
                  controller: phoneController,
                  icon: Icons.phone_outlined,
                  hint: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 14),

                _buildModalFieldLabel('Affiliation'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD1DF), width: 1.2),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: affiliation,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      items: affiliationsList.map((item) {
                        return DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13.5)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => affiliation = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                _buildModalFieldLabel('Institution / Organization'),
                const SizedBox(height: 6),
                _buildModalTextField(
                  controller: institutionController,
                  icon: Icons.location_city_outlined,
                  hint: 'Institution / Organization',
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = {
                        'fullName': nameController.text.trim(),
                        'name': nameController.text.trim(),
                        'phone': phoneController.text.trim(),
                        'affiliation': affiliation,
                        'institution': institutionController.text.trim(),
                      };
                      await _volunteerService.updateVolunteerProfile(updated);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadAllData();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Volunteer Profile updated successfully!'),
                          backgroundColor: AppColors.safeGreen,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFFFF528E),
      ),
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFFF6495), size: 20),
        filled: true,
        fillColor: const Color(0xFFFFF4F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFD1DF), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF2B75), width: 1.6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildHomeTab(),
                _buildHistoryTab(),
                _buildProfileTab(),
              ],
            ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.history_rounded, 'History'),
                _buildNavItem(2, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _selectedTabIndex = index);
        if (index == 1 || index == 2) {
          _loadAllData();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF4E9B) : const Color(0xFF9E9E9E),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFFFF4E9B) : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TAB 0: HOME VIEW WITH LIVE FEMALE SOS ALERTS =================
  Widget _buildHomeTab() {
    final name = _volunteerData?['fullName'] ?? _volunteerData?['name'] ?? 'Arjun';
    final firstName = name.toString().split(' ').first;
    final responded = '${_volunteerData?['respondedCount'] ?? 14}';
    final rating = '${_volunteerData?['rating'] ?? '4.9'}★';
    final coverage = '${_volunteerData?['coverageRadiusKm'] ?? '1.8'}km';

    return Stack(
      children: [
        Container(
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF528E), Color(0xFFFF7DA7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ),

        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hi, $firstName 🤝',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                              onPressed: () {
                                Navigator.pushNamed(context, AppRoutes.volunteerIncomingAlert);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Verified Volunteer',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Duty Status Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _isOnDuty ? 'You are ON duty' : 'You are OFF duty',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _isOnDuty ? const Color(0xFF10B981) : const Color(0xFF555B62),
                          ),
                        ),
                        const SizedBox(height: 14),

                        GestureDetector(
                          onTap: () => _toggleDuty(!_isOnDuty),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 84,
                            height: 46,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: _isOnDuty ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 300),
                              alignment: _isOnDuty ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.power_settings_new_rounded,
                                  color: _isOnDuty ? const Color(0xFF10B981) : const Color(0xFF2C2523),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text(
                          _isOnDuty
                              ? 'Active: Receiving SOS alerts sent by females in real-time'
                              : 'Go on-duty to start receiving nearby SOS alerts',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF757575),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // LIVE SOS ALERTS FEED SECTION (From Firestore Female SOS Messages)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emergency_rounded, color: Color(0xFFE51C23), size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Active SOS Alerts Nearby',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text('\u25CF', style: TextStyle(color: Color(0xFFE51C23), fontSize: 10)),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE51C23)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Stream Builder for Active Female SOS Alerts
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _volunteerService.getActiveFemaleSosAlertsStream(),
                  builder: (context, snapshot) {
                    final alerts = snapshot.data ?? [];
                    if (alerts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'No active SOS emergencies in your area right now. The network is safe.',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: alerts.map((alert) => _buildLiveSosCard(alert)).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 3-Column Stats Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildStatItem(responded, 'Responded'),
                        Container(width: 1, height: 36, color: const Color(0xFFF0F0F0)),
                        _buildStatItem(rating, 'Rating'),
                        Container(width: 1, height: 36, color: const Color(0xFFF0F0F0)),
                        _buildStatItem(coverage, 'Coverage'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Section Title: Coverage Area
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Coverage Area',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Coverage Area Grid Radar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          child: Container(
                            height: 180,
                            width: double.infinity,
                            color: const Color(0xFFEEF5FA),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(double.infinity, 180),
                                  painter: _GridPainter(),
                                ),
                                AnimatedBuilder(
                                  animation: _radarController,
                                  builder: (context, child) {
                                    final pulseValue = _radarController.value;
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 100 + (pulseValue * 24),
                                          height: 100 + (pulseValue * 24),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFFFF2D8D).withValues(alpha: (1 - pulseValue) * 0.6),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        CustomPaint(
                                          size: const Size(100, 100),
                                          painter: _DashedCirclePainter(
                                            color: const Color(0xFFFF2D8D).withValues(alpha: 0.7),
                                          ),
                                        ),
                                        Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF2D8D),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFFF2D8D).withValues(alpha: 0.4),
                                                blurRadius: 8,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Text(
                            "You'll be alerted for female SOS emergencies within $coverage while on-duty",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveSosCard(Map<String, dynamic> alert) {
    final victimName = alert['userName'] ?? 'Female User';
    final alertType = alert['alertType'] ?? 'Emergency SOS';
    final timeAgo = alert['timeAgo'] ?? 'Just now';
    final locationData = alert['location'];
    String address = 'Andheri West, Mumbai';
    String distance = '420m away';

    if (locationData is Map) {
      address = locationData['address'] ?? address;
      distance = locationData['distance'] ?? distance;
    } else if (locationData is String) {
      address = locationData;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE51C23).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECEE),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        victimName.isNotEmpty ? victimName[0] : 'F',
                        style: const TextStyle(
                          color: Color(0xFFE51C23),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        victimName,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        alertType,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE51C23),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  timeAgo,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE51C23)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFF757575), size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF555B62), fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                distance,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1976D2)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                _volunteerService.acceptSosAlert(alert);
                Navigator.pushNamed(
                  context,
                  AppRoutes.volunteerTracking,
                  arguments: alert,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE51C23),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                elevation: 3,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Accept & Respond to SOS',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 1: HISTORY VIEW =================
  Widget _buildHistoryTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Response History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Past accepted & resolved emergency alerts',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF757575)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_historyList.length} Resolved',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _historyList.isEmpty
                ? const Center(
                    child: Text('No previous responses yet', style: TextStyle(color: AppColors.textMuted)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: _historyList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _historyList[index];
                      final victimName = item['victimName'] ?? 'Victim';
                      final location = item['location'] ?? 'Nearby';
                      final alertType = item['alertType'] ?? 'Emergency';
                      final time = item['timestamp'] ?? 'Recently';
                      final responseTime = item['responseTime'] ?? '3 mins';
                      final distance = item['distance'] ?? '420m';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFE3EC),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          victimName.isNotEmpty ? victimName[0] : 'V',
                                          style: const TextStyle(
                                            color: Color(0xFFFF2D8D),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          victimName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          alertType,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFE51C23),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Safe',
                                        style: TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFF2F2F2)),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, color: Color(0xFF757575), size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF555B62)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  time,
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF9E9E9E)),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF9E9E9E)),
                                    const SizedBox(width: 3),
                                    Text(
                                      'ETA $responseTime ($distance)',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF555B62),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ================= TAB 2: PROFILE VIEW =================
  Widget _buildProfileTab() {
    final fullName = _volunteerData?['fullName'] ?? _volunteerData?['name'] ?? 'Arjun Mehta';
    final email = _volunteerData?['email'] ?? 'arjun.volunteer@safora.app';
    final phone = _volunteerData?['phone'] ?? '+91 98765 43210';
    final idType = _volunteerData?['idType'] ?? 'Aadhaar Card';
    final affiliation = _volunteerData?['affiliation'] ?? 'College / Campus (NSS-NCC)';
    final institution = _volunteerData?['institution'] ?? "St. Xavier's College";
    final responded = '${_volunteerData?['respondedCount'] ?? 14}';
    final rating = '${_volunteerData?['rating'] ?? '4.9'} ★';
    final coverage = '${_volunteerData?['coverageRadiusKm'] ?? '1.8'} km';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Volunteer Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF2D8D), size: 18),
                  label: const Text(
                    'Edit',
                    style: TextStyle(color: Color(0xFFFF2D8D), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF528E), Color(0xFFFF7DA7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF2D8D).withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        fullName.isNotEmpty ? fullName[0] : 'V',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF2D8D),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Verified Volunteer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                _buildProfileStatBox('Responses', responded, Icons.volunteer_activism_rounded),
                const SizedBox(width: 12),
                _buildProfileStatBox('Rating', rating, Icons.star_rounded),
                const SizedBox(width: 12),
                _buildProfileStatBox('Coverage', coverage, Icons.radar_rounded),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Submitted Verification Info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildProfileInfoTile(Icons.person_outline_rounded, 'Full Name', fullName),
                  const Divider(height: 20, color: Color(0xFFF2F2F2)),
                  _buildProfileInfoTile(Icons.phone_outlined, 'Phone Number', phone),
                  const Divider(height: 20, color: Color(0xFFF2F2F2)),
                  _buildProfileInfoTile(Icons.mail_outline_rounded, 'Email Address', email),
                  const Divider(height: 20, color: Color(0xFFF2F2F2)),
                  _buildProfileInfoTile(Icons.credit_card_rounded, 'Govt ID Type', idType),
                  const Divider(height: 20, color: Color(0xFFF2F2F2)),
                  _buildProfileInfoTile(Icons.business_outlined, 'Affiliation', affiliation),
                  if (institution.isNotEmpty) ...[
                    const Divider(height: 20, color: Color(0xFFF2F2F2)),
                    _buildProfileInfoTile(Icons.location_city_outlined, 'Institution / Org', institution),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF4757), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  backgroundColor: const Color(0xFFFFF5F5),
                ),
                onPressed: _handleLogout,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFFF4757), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Log Out from Volunteer Hub',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF4757),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStatBox(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFFF4E9B), size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF6495), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDCE8F2)
      ..strokeWidth = 1.0;

    const step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 36;
    const dashLength = (2 * math.pi) / dashCount;

    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = i * dashLength;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashLength,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
