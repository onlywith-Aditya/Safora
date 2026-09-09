import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../routes/app_routes.dart';
import '../../auth/services/auth_service.dart';

class EmergencyPaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? planData;

  const EmergencyPaymentScreen({super.key, this.planData});

  @override
  State<EmergencyPaymentScreen> createState() => _EmergencyPaymentScreenState();
}

class _EmergencyPaymentScreenState extends State<EmergencyPaymentScreen> {
  String _selectedMethod = 'upi_gpay'; // 'upi_gpay', 'upi_phonepe', 'upi_paytm', 'card', 'netbanking'
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController(text: '4532 •••• •••• 8921');
  final TextEditingController _cardExpiryController = TextEditingController(text: '08/28');
  final TextEditingController _cardCvvController = TextEditingController(text: '•••');
  String _selectedBank = 'HDFC Bank';

  bool _isProcessing = false;
  bool _isSuccess = false;
  String _transactionId = '';

  @override
  void initState() {
    super.initState();
    _transactionId = 'SAF-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    // Simulate real-time payment gateway processing
    await Future.delayed(const Duration(milliseconds: 1600));

    final user = AuthService().currentUser;
    final userName = user != null ? (user['name'] ?? 'Priya Sharma') : 'Priya Sharma';
    final userPhone = user != null ? (user['phone'] ?? '+91 98765 43210') : '+91 98765 43210';
    final userEmail = user != null ? (user['email'] ?? 'priya@safora.app') : 'priya@safora.app';
    final userId = user != null ? (user['uid'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}') : 'usr_${DateTime.now().millisecondsSinceEpoch}';
    final planName = widget.planData?['planName'] ?? 'Volunteer Protection';
    final amount = widget.planData?['amount'] ?? 500;

    // Dispatch Emergency Alert to Firestore & local storage with payment and user information
    final alertPayload = {
      'alertId': 'alert_${DateTime.now().millisecondsSinceEpoch}',
      'paymentId': _transactionId,
      'transactionId': _transactionId,
      'amount': amount,
      'amountPaid': amount,
      'paymentStatus': 'PAID',
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'phone': userPhone,
      'alertType': planName,
      'userLocation': 'Near Metro Pillar 42, Andheri West, Mumbai',
      'location': {
        'address': 'Near Metro Pillar 42, Andheri West, Mumbai',
        'latitude': 19.1136,
        'longitude': 72.8697,
        'distance': '420m away',
        'eta': planName.contains('Priority') ? '2 min' : '3 min',
      },
      'assignedVolunteer': {
        'name': 'Arjun Mehta',
        'phone': '+91 98765 43210',
        'rating': 4.9,
        'affiliation': 'Verified NSS Safety Cadet',
        'status': 'en_route',
      },
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      final firestoreData = Map<String, dynamic>.from(alertPayload);
      firestoreData['timestamp'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance.collection('emergency_alerts').add(firestoreData);
      await FirebaseFirestore.instance.collection('sos_alerts').add(firestoreData);
    } catch (_) {}

    // Save payment ID and payment amount into user profile & payments collection in Firestore
    await AuthService().recordUserPayment(
      paymentId: _transactionId,
      amount: amount,
      planName: planName,
      paymentMethod: _selectedMethod,
      alertId: alertPayload['alertId'] as String?,
    );

    await LocalStorageService().saveActiveEmergency(alertPayload);

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final planName = widget.planData?['planName'] ?? 'Volunteer Protection';
    final amount = widget.planData?['amount'] ?? 500;
    final eta = widget.planData?['eta'] ?? '3-5 mins';

    if (_isSuccess) {
      return _buildSuccessView(planName, amount);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Secure Emergency Payment',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lock_rounded, color: AppColors.safeGreen, size: 14),
                  SizedBox(width: 4),
                  Text(
                    '256-bit SSL',
                    style: TextStyle(
                      color: AppColors.safeGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                _buildPlanSummaryCard(planName, amount, eta),

                const SizedBox(height: 22),

                const Text(
                  'SELECT PAYMENT METHOD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 12),

                // UPI Methods
                _buildPaymentOptionGroup(
                  title: 'UPI Instant Payment',
                  icon: Icons.qr_code_2_rounded,
                  children: [
                    _buildRadioMethod(
                      id: 'upi_gpay',
                      title: 'Google Pay',
                      subtitle: 'Fastest 1-tap checkout',
                      iconAsset: Icons.account_balance_wallet_rounded,
                    ),
                    const Divider(height: 1),
                    _buildRadioMethod(
                      id: 'upi_phonepe',
                      title: 'PhonePe',
                      subtitle: 'UPI Auto-detect',
                      iconAsset: Icons.flash_on_rounded,
                    ),
                    const Divider(height: 1),
                    _buildRadioMethod(
                      id: 'upi_paytm',
                      title: 'Paytm UPI',
                      subtitle: 'Instant response guarantee',
                      iconAsset: Icons.account_balance_wallet_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Card Payment
                _buildPaymentOptionGroup(
                  title: 'Debit / Credit Card',
                  icon: Icons.credit_card_rounded,
                  children: [
                    _buildRadioMethod(
                      id: 'card',
                      title: 'Visa / Mastercard / RuPay',
                      subtitle: 'Saved Card (•••• 8921)',
                      iconAsset: Icons.credit_card,
                    ),
                    if (_selectedMethod == 'card') ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _cardNumberController,
                              decoration: InputDecoration(
                                labelText: 'Card Number',
                                prefixIcon: const Icon(Icons.credit_card_rounded),
                                filled: true,
                                fillColor: AppColors.inputBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _cardExpiryController,
                                    decoration: InputDecoration(
                                      labelText: 'Valid Thru',
                                      filled: true,
                                      fillColor: AppColors.inputBg,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _cardCvvController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'CVV',
                                      filled: true,
                                      fillColor: AppColors.inputBg,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 14),

                // Net Banking
                _buildPaymentOptionGroup(
                  title: 'Net Banking',
                  icon: Icons.account_balance_rounded,
                  children: [
                    _buildRadioMethod(
                      id: 'netbanking',
                      title: 'Net Banking',
                      subtitle: 'All major Indian banks supported',
                      iconAsset: Icons.account_balance,
                    ),
                    if (_selectedMethod == 'netbanking') ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedBank,
                          items: ['HDFC Bank', 'State Bank of India', 'ICICI Bank', 'Axis Bank', 'Kotak Mahindra']
                              .map((bank) => DropdownMenuItem(value: bank, child: Text(bank)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedBank = val ?? _selectedBank),
                          decoration: InputDecoration(
                            labelText: 'Choose Bank',
                            filled: true,
                            fillColor: AppColors.inputBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),

                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Security Note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.verified_user_rounded, color: AppColors.safeGreen, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Zero cancellation fee if volunteer does not arrive in ETA.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Pay Button Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: CustomButton(
                  text: _isProcessing ? 'Processing Secure Payment...' : 'Pay ₹$amount & Dispatch Help',
                  isLoading: _isProcessing,
                  onPressed: _isProcessing ? null : _processPayment,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSummaryCard(String planName, int amount, String eta) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B0916), Color(0xFF14030A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'EMERGENCY DISPATCH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'ETA $eta',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Nearest safety volunteer sent immediately',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              Text(
                '₹$amount',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRadioMethod({
    required String id,
    required String title,
    required String subtitle,
    required IconData iconAsset,
  }) {
    final isSelected = _selectedMethod == id;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(iconAsset, color: isSelected ? AppColors.primary : Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  /// Step 4: Payment Success Screen View
  Widget _buildSuccessView(String planName, int amount) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Green Checkmark
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8EE),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.safeGreen,
                    size: 68,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '₹$amount paid for $planName',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Transaction ID: $_transactionId',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              // Dispatch Notice Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.lightPinkCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.radar_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Alert Sent to Nearby Volunteers',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Verified NSS safety volunteer has accepted and is rushing to your coordinates.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Step 5 Navigation Button
              CustomButton(
                text: 'Track Volunteer Live',
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.clientTracking,
                    arguments: {
                      'planName': planName,
                      'amount': amount,
                      'transactionId': _transactionId,
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
