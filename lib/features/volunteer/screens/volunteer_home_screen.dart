import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../services/volunteer_service.dart';

class VolunteerHomeScreen extends StatefulWidget {
  const VolunteerHomeScreen({super.key});

  @override
  State<VolunteerHomeScreen> createState() => _VolunteerHomeScreenState();
}

class _VolunteerHomeScreenState extends State<VolunteerHomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  bool _isOnDuty = true;
  bool _isLoading = true;

  Map<String, dynamic> _profileData = {};
  Map<String, dynamic> _earningsData = {'total': 3500, 'pending': 0};
  List<Map<String, dynamic>> _transactions = [];

  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _loadData();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final profile = await VolunteerService().loadVolunteerProfile();
    final duty = await VolunteerService().getDutyStatus();
    final earnings = await VolunteerService().getVolunteerEarnings();
    final txns = await VolunteerService().getEarningsTransactions();

    if (mounted) {
      setState(() {
        _profileData = profile;
        _isOnDuty = duty;
        _earningsData = earnings;
        _transactions = txns;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDuty(bool value) async {
    setState(() => _isOnDuty = value);
    await VolunteerService().toggleDutyStatus(value);
    if (value) {
      if (!_radarController.isAnimating) _radarController.repeat();
    } else {
      _radarController.stop();
    }
  }

  Future<void> _settleEarnings() async {
    final pending = (_earningsData['pending'] as num?)?.toInt() ?? 0;
    if (pending <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending earnings to settle right now.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final updated = await VolunteerService().settlePendingEarnings();
    final txns = await VolunteerService().getEarningsTransactions();
    setState(() {
      _earningsData = updated;
      _transactions = txns;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('₹$pending successfully verified & settled to Total Earnings!'),
        backgroundColor: AppColors.safeGreen,
      ),
    );
  }

  void _triggerTestAlert() {
    Navigator.pushNamed(
      context,
      AppRoutes.volunteerIncomingAlert,
      arguments: {
        'userName': 'Sneha Kapoor',
        'victimName': 'Sneha Kapoor',
        'phone': '+91 98765 43210',
        'userPhone': '+91 98765 43210',
        'planName': 'Volunteer Protection',
        'alertType': 'Volunteer Protection',
        'amount': 500,
        'distance': '420m away',
        'userLocation': 'Near Metro Pillar 42, Andheri West, Mumbai',
        'address': 'Near Metro Pillar 42, Andheri West, Mumbai',
        'paymentId': 'SAF-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      },
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(text: _profileData['fullName'] ?? _profileData['name'] ?? 'Aarav Sharma');
    final phoneCtrl = TextEditingController(text: _profileData['phone'] ?? '+91 98201 12345');
    final instCtrl = TextEditingController(text: _profileData['institution'] ?? 'St. Xavier\'s College, Mumbai');
    String affiliation = _profileData['affiliation'] ?? 'College / Campus (NSS-NCC)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Volunteer Profile',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneCtrl,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: instCtrl,
              decoration: InputDecoration(
                labelText: 'Institution / Organization',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  await VolunteerService().updateVolunteerProfile(
                    name: nameCtrl.text,
                    phone: phoneCtrl.text,
                    institution: instCtrl.text,
                    affiliation: affiliation,
                  );
                  Navigator.pop(ctx);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                child: const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: _buildAppBar(),
      body: _buildSelectedTab(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final name = _profileData['fullName'] ?? _profileData['name'] ?? 'Aarav Sharma';

    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                // Avatar with online dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFFFEEF3),
                      child: Text(
                        name.isNotEmpty ? name[0] : 'V',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _isOnDuty ? AppColors.safeGreen : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, color: Color(0xFF00897B), size: 16),
                        ],
                      ),
                      Text(
                        _isOnDuty ? 'On Duty • Active in 1.8km radius' : 'Off Duty • Standby Mode',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _isOnDuty ? AppColors.safeGreen : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Power / Duty Switch
                Transform.scale(
                  scale: 0.85,
                  child: Switch.adaptive(
                    value: _isOnDuty,
                    activeColor: AppColors.safeGreen,
                    onChanged: _toggleDuty,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildRadarTab();
      case 1:
        return _buildEarningsTab();
      case 2:
        return _buildProfileTab();
      default:
        return _buildRadarTab();
    }
  }

  // --------------------------------------------------------------------------
  // TAB 0: RADAR / DUTY DASHBOARD
  // --------------------------------------------------------------------------
  Widget _buildRadarTab() {
    final totalEarnings = (_earningsData['total'] as num?)?.toInt() ?? 3500;
    final pendingEarnings = (_earningsData['pending'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Earnings Overview Card (Step 5: Earn Money)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL EARNINGS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Verified Escrow',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹$totalEarnings',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pending Verification',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '₹$pendingEarnings',
                          style: TextStyle(
                            color: pendingEarnings > 0 ? const Color(0xFFFFD54F) : Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    if (pendingEarnings > 0)
                      ElevatedButton.icon(
                        onPressed: _settleEarnings,
                        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF0D9488), size: 16),
                        label: const Text('1-Tap Settle', style: TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w800, fontSize: 12.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Live Radar Radar Scanner Widget
          Container(
            width: double.infinity,
            height: 270,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFEEF2F6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isOnDuty)
                  AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(260, 260),
                        painter: _RadarWavePainter(progress: _radarController.value),
                      );
                    },
                  ),
                // Center Pulse Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: _isOnDuty ? const Color(0xFFFFEEF3) : const Color(0xFFF0F0F0),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _isOnDuty ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent,
                        blurRadius: 18,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isOnDuty ? Icons.radar_rounded : Icons.power_settings_new_rounded,
                    color: _isOnDuty ? AppColors.primary : Colors.grey,
                    size: 36,
                  ),
                ),
                // Radar status caption
                Positioned(
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isOnDuty ? const Color(0xFFF0FDF4) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _isOnDuty ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      _isOnDuty ? 'Scanning 1.8km Radius for Distress Alerts...' : 'Duty is OFF. Turn ON to receive alerts.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isOnDuty ? const Color(0xFF166534) : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Simulator / Demo SOS Alert Trigger
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFCCD3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF2D55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emergency_share_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulate SOS Alert',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Test Step 1: 60s Alert & ₹500 Earning',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _triggerTestAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2D55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Test Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: EARNINGS & TRANSACTION HISTORY (Step 5: Transaction History)
  // --------------------------------------------------------------------------
  Widget _buildEarningsTab() {
    final totalEarnings = (_earningsData['total'] as num?)?.toInt() ?? 3500;
    final pendingEarnings = (_earningsData['pending'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total & Pending summary cards row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Balance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('₹$totalEarnings', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F766E))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending Escrow', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('₹$pendingEarnings', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (pendingEarnings > 0) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _settleEarnings,
                icon: const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                label: Text('Settle & Move ₹$pendingEarnings to Total Balance', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Text(
            'Transaction History',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),

          if (_transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: const Text('No transactions yet.', style: TextStyle(color: AppColors.textMuted)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final txn = _transactions[i];
                final isPending = txn['status'] == 'Pending Verification';

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                          color: isPending ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn['title'] ?? 'Emergency Protection Assistance',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${txn['victimName'] ?? 'Victim'} • ${txn['date'] ?? 'Today'}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                            Text(
                              'Ref: ${txn['paymentId'] ?? txn['id']}',
                              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+₹${txn['amount'] ?? 500}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isPending ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPending ? 'PENDING' : 'SETTLED',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: isPending ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: VOLUNTEER PROFILE
  // --------------------------------------------------------------------------
  Widget _buildProfileTab() {
    final name = _profileData['fullName'] ?? _profileData['name'] ?? 'Aarav Sharma';
    final email = _profileData['email'] ?? 'aarav.sharma@nss.org';
    final phone = _profileData['phone'] ?? '+91 98201 12345';
    final institution = _profileData['institution'] ?? 'St. Xavier\'s College, Mumbai';
    final affiliation = _profileData['affiliation'] ?? 'College / Campus (NSS-NCC)';
    final responses = _profileData['respondedCount'] ?? 14;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Profile Top Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFFFEEF3),
                  child: Text(
                    name.isNotEmpty ? name[0] : 'V',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, color: Color(0xFF00897B), size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _showEditProfileDialog,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Volunteer Credentials & Stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Credentials & Impact', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 14),
                _buildInfoRow(Icons.account_balance_outlined, 'Affiliation', affiliation),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildInfoRow(Icons.school_outlined, 'Institution', institution),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildInfoRow(Icons.phone_outlined, 'Phone', phone),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildInfoRow(Icons.favorite_outline_rounded, 'Rescues Responded', '$responses Missions Completed'),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildInfoRow(Icons.star_outline_rounded, 'Safety Rating', '4.9 / 5.0 (Exceptional)'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.roleSelection, (route) => false);
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFE50914), size: 18),
              label: const Text('Switch Role / Logout', style: TextStyle(color: Color(0xFFE50914), fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFFF1F2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) => setState(() => _selectedTabIndex = index),
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.radar_outlined),
            activeIcon: Icon(Icons.radar_rounded),
            label: 'Duty & Radar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _RadarWavePainter extends CustomPainter {
  final double progress;

  _RadarWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + (i * 0.33)) % 1.0;
      final radius = waveProgress * maxRadius;
      final opacity = (1.0 - waveProgress).clamp(0.0, 1.0) * 0.45;

      final paint = Paint()
        ..color = const Color(0xFFFF2D8D).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarWavePainter oldDelegate) => oldDelegate.progress != progress;
}
