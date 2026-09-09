import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_input.dart';
import '../../../routes/app_routes.dart';
import '../../auth/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool isStandalone;
  const ProfileScreen({super.key, this.isStandalone = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  void _showEditProfileModal() {
    final user = AuthService().currentUser;
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user?['name'] ?? 'Priya Sharma');
    final phoneCtrl = TextEditingController(text: user?['phone'] ?? '+91 98765 43210');
    final addressCtrl = TextEditingController(
      text: user?['address'] ?? '',
    );
    String? selectedBloodGroup = user?['bloodGroup'] ?? 'O+';
    if (!_bloodGroups.contains(selectedBloodGroup)) {
      selectedBloodGroup = 'O+';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sbContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Profile Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    CustomInputField(
                      label: 'Full Name',
                      hintText: 'Enter full name',
                      controller: nameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      isRequired: true,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    CustomInputField(
                      label: 'Phone Number',
                      hintText: 'Enter phone number',
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      isRequired: true,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        if (v.trim().length < 8) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    RichText(
                      text: const TextSpan(
                        text: 'Blood Group',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        children: [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBloodGroup,
                      dropdownColor: Colors.white,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please select blood group'
                          : null,
                      decoration: InputDecoration(
                        hintText: 'Select Blood Group',
                        filled: true,
                        fillColor: AppColors.inputBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                            width: 1.2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.inputFocusedBorder,
                            width: 1.8,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.dangerRed,
                            width: 1.2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.dangerRed,
                            width: 1.8,
                          ),
                        ),
                      ),
                      items: _bloodGroups.map((group) {
                        return DropdownMenuItem(
                          value: group,
                          child: Text(group, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (v) => setModalState(() => selectedBloodGroup = v),
                    ),
                    const SizedBox(height: 12),

                    CustomInputField(
                      label: 'Address',
                      hintText: 'Enter your address',
                      controller: addressCtrl,
                      maxLines: 2,
                      isRequired: true,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your address'
                          : null,
                    ),
                    const SizedBox(height: 22),

                    CustomButton(
                      text: 'Save Changes',
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final address = addressCtrl.text.trim();

                        if (name.isEmpty ||
                            phone.isEmpty ||
                            address.isEmpty ||
                            selectedBloodGroup == null) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('All profile fields are required'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                          return;
                        }

                        // Persist to Cloud Firestore and local state
                        await AuthService().updateUserProfile(
                          name: name,
                          phone: phone,
                          bloodGroup: selectedBloodGroup!,
                          address: address,
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated successfully'),
                              backgroundColor: AppColors.safeGreen,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final name = (user?['fullName'] ?? user?['name'] ?? 'Priya Sharma').toString();
    final email = (user?['email'] ?? 'priya.sharma@email.com').toString();
    final phone = (user?['phone'] ?? '+91 98765 43210').toString();
    final bloodGroup = (user?['bloodGroup'] ?? 'O+').toString();
    final address = (user?['address'] ?? '').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    final contactsRaw = user?['contacts'] ?? user?['emergencyContacts'];
    final List<Map<String, dynamic>> contactList = [];
    if (contactsRaw is List) {
      for (var c in contactsRaw) {
        if (c is Map) {
          contactList.add({
            'name': c['name']?.toString() ?? '',
            'phone': c['phone']?.toString() ?? '',
            'relation': c['relation']?.toString() ?? 'Contact',
          });
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Pink Banner with Overlapping Avatar
            _buildHeader(context, initial),

            const SizedBox(height: 12),

            // User Name & Email
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 24),

            // Profile Information Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: phone,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.water_drop_outlined,
                    label: 'Blood Group',
                    value: bloodGroup,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: address.isEmpty ? 'Not Provided' : address,
                  ),

                  const SizedBox(height: 24),

                  // Emergency Contacts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.contacts).then((_) {
                            if (mounted) setState(() {});
                          });
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Dynamic Contact Previews from Firestore
                  if (contactList.isNotEmpty)
                    ...contactList.take(2).map((c) {
                      final cName = c['name'] ?? 'Contact';
                      final cRel = c['relation'] ?? 'Relation';
                      final cPhone = c['phone'] ?? '';
                      final cInitial = cName.isNotEmpty ? cName[0].toUpperCase() : 'C';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildContactPreviewCard(cName, cRel, cPhone, cInitial),
                      );
                    })
                  else ...[
                    _buildContactPreviewCard('Rajesh Sharma', 'Father', '+91 98765 43210', 'R'),
                    const SizedBox(height: 10),
                    _buildContactPreviewCard('Anita Verma', 'Sister', '+91 91234 56744', 'A'),
                  ],

                  const SizedBox(height: 24),

                  // Action Buttons
                  CustomButton(
                    text: 'Edit Profile',
                    isOutlined: true,
                    onPressed: _showEditProfileModal,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Log Out',
                    isOutlined: true,
                    textColor: AppColors.primaryDark,
                    onPressed: () async {
                      await AuthService().logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.roleSelection,
                          (route) => false,
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  /// Header with Curved Pink Background and Centered Floating Avatar
  Widget _buildHeader(BuildContext context, String initial) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 45),
          decoration: const BoxDecoration(
            color: AppColors.headerPink,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  if (widget.isStandalone) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  }
                },
              ),
            ),
          ),
        ),

        // Floating Avatar
        Positioned(
          bottom: 0,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFB8D2),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactPreviewCard(String name, String relation, String maskedPhone, String initial) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB8D2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  relation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            maskedPhone,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: 3, // Profile Tab Active
        onTap: (idx) {
          if (idx == 0) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          } else if (idx == 1) {
            Navigator.pushReplacementNamed(context, AppRoutes.contacts);
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
    );
  }
}
