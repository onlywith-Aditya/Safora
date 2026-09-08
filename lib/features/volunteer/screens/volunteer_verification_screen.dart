import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../routes/app_routes.dart';
import '../services/volunteer_service.dart';

class VolunteerVerificationScreen extends StatefulWidget {
  const VolunteerVerificationScreen({super.key});

  @override
  State<VolunteerVerificationScreen> createState() => _VolunteerVerificationScreenState();
}

class _VolunteerVerificationScreenState extends State<VolunteerVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _institutionController = TextEditingController();

  String _selectedIdType = 'Aadhaar Card';
  String _selectedAffiliation = 'College / Campus (NSS-NCC)';
  bool _hasUploadedId = false;
  String _uploadedFileName = '';
  bool _isLoading = false;

  final List<String> _idTypes = [
    'Aadhaar Card',
    'PAN Card',
    'Voter ID',
    'Driving License',
    'Student / Employee ID',
  ];

  final List<String> _affiliations = [
    'College / Campus (NSS-NCC)',
    'Registered NGO / Foundation',
    'Community Watch / Resident',
    'Emergency & Disaster Response',
    'Individual Guardian',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  void _handleUploadId() {
    setState(() {
      _hasUploadedId = true;
      _uploadedFileName = 'govt_id_${DateTime.now().millisecondsSinceEpoch % 10000}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID Photo attached successfully'),
        backgroundColor: AppColors.safeGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_hasUploadedId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your Government ID photo'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Collect all data at the LAST stage
    final volunteerData = {
      'name': _nameController.text.trim(),
      'fullName': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : 'volunteer_${_phoneController.text.trim().replaceAll(' ', '')}@safora.app',
      'password': _passwordController.text.trim().isNotEmpty
          ? _passwordController.text
          : 'vol123456',
      'idType': _selectedIdType,
      'affiliation': _selectedAffiliation,
      'institution': _institutionController.text.trim(),
      'idPhoto': _uploadedFileName,
      'role': 'volunteer',
      'isVerified': false,
      'verificationStatus': 'pending',
    };

    // Save to Firestore 'volunteers' collection and Local Device Storage
    final result = await VolunteerService().registerVolunteer(volunteerData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, AppRoutes.volunteerPending);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Verification submission failed'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6495), Color(0xFFFF8EB4)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Volunteer Verification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner
              const Text(
                'We verify every volunteer to keep the network safe. This usually takes under 24 hours.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              _buildFieldLabel('Full Name*'),
              const SizedBox(height: 8),
              _buildTextCard(
                hint: 'e.g. Arjun Mehta',
                icon: Icons.person_outline_rounded,
                controller: _nameController,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
              ),
              const SizedBox(height: 18),

              // Phone Number
              _buildFieldLabel('Phone Number*'),
              const SizedBox(height: 8),
              _buildTextCard(
                hint: '+91 98765 43210',
                icon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().length < 8) ? 'Enter valid phone number' : null,
              ),
              const SizedBox(height: 18),

              // Email
              _buildFieldLabel('Email Address*'),
              const SizedBox(height: 8),
              _buildTextCard(
                hint: 'arjun.mehta@email.com',
                icon: Icons.mail_outline_rounded,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 18),

              // Password
              _buildFieldLabel('Set Volunteer Password*'),
              const SizedBox(height: 8),
              _buildTextCard(
                hint: 'Min 6 characters',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Password must be min 6 characters' : null,
              ),
              const SizedBox(height: 18),

              // Government ID Type
              _buildFieldLabel('Government ID Type*'),
              const SizedBox(height: 8),
              _buildDropdownCard(
                icon: Icons.credit_card_rounded,
                value: _selectedIdType,
                items: _idTypes,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedIdType = val);
                },
              ),
              const SizedBox(height: 18),

              // Upload ID Photo Box
              _buildFieldLabel('Upload ID Photo*'),
              const SizedBox(height: 8),
              _buildUploadBox(),
              const SizedBox(height: 18),

              // Affiliation
              _buildFieldLabel('Affiliation*'),
              const SizedBox(height: 8),
              _buildDropdownCard(
                icon: Icons.business_outlined,
                value: _selectedAffiliation,
                items: _affiliations,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedAffiliation = val);
                },
              ),
              const SizedBox(height: 18),

              // Institution / Organization Name
              _buildFieldLabel('Institution / Organization Name'),
              const SizedBox(height: 8),
              _buildTextCard(
                hint: "e.g. St. Xavier's College",
                icon: Icons.location_city_outlined,
                controller: _institutionController,
              ),
              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: 'Submit for Verification',
                isLoading: _isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFFFF528E),
      ),
    );
  }

  Widget _buildTextCard({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFC0A4AD),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFFF6495), size: 22),
        filled: true,
        fillColor: const Color(0xFFFFF4F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFFD1DF), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF2B75), width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.dangerRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.dangerRed, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildDropdownCard({
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD1DF), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6495), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFF6495)),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                items: items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox() {
    return InkWell(
      onTap: _handleUploadId,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4F7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hasUploadedId ? AppColors.safeGreen : const Color(0xFFFFB8CE),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _hasUploadedId ? Icons.check_circle_outline_rounded : Icons.file_upload_outlined,
              color: _hasUploadedId ? AppColors.safeGreen : const Color(0xFFFF2B75),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              _hasUploadedId ? 'ID Attached: $_uploadedFileName' : 'Tap to upload front side',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _hasUploadedId ? AppColors.safeGreen : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'JPG or PNG, max 5MB',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
