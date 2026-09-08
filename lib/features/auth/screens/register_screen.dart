import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_input.dart';
import '../../../routes/app_routes.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 1; // 1: Personal Info, 2: Contacts, 3: Done

  // Step 1 Controllers
  final _step1FormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedBloodGroup;
  bool _obscurePassword = true;

  // Step 2 Controllers & Dynamic Contacts
  final List<Map<String, TextEditingController>> _contacts = [
    {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'relation': TextEditingController(),
    }
  ];

  bool _isLoading = false;

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    for (var c in _contacts) {
      c['name']?.dispose();
      c['phone']?.dispose();
      c['relation']?.dispose();
    }
    super.dispose();
  }

  void _addContact() {
    setState(() {
      _contacts.add({
        'name': TextEditingController(),
        'phone': TextEditingController(),
        'relation': TextEditingController(),
      });
    });
  }

  void _removeContact(int index) {
    if (_contacts.length > 1) {
      setState(() {
        _contacts[index]['name']?.dispose();
        _contacts[index]['phone']?.dispose();
        _contacts[index]['relation']?.dispose();
        _contacts.removeAt(index);
      });
    }
  }

  Future<void> _handleFinalSubmit() async {
    // Validate contacts
    for (int i = 0; i < _contacts.length; i++) {
      if (_contacts[i]['name']!.text.trim().isEmpty ||
          _contacts[i]['phone']!.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fill contact #${i + 1} name and phone number'),
            backgroundColor: AppColors.primary,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final userData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'age': _ageController.text.trim(),
      'bloodGroup': _selectedBloodGroup ?? 'Not Specified',
      'address': _addressController.text.trim(),
      'contacts': _contacts.map((c) => {
        'name': c['name']!.text.trim(),
        'phone': c['phone']!.text.trim(),
        'relation': c['relation']!.text.trim(),
      }).toList(),
    };

    final result = await AuthService().register(userData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      setState(() {
        _currentStep = 3; // Move to Done screen
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Registration error'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

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
            onPressed: () {
              if (_currentStep == 2) {
                setState(() => _currentStep = 1);
              } else if (_currentStep == 1) {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Create Account',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          centerTitle: false,
        ),
      ),
      body: Column(
        children: [
          // Step 1 - 2 - 3 Stepper Header
          _buildStepperHeader(),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildCurrentStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  /// Stepper Visual Progress Indicator (1: Personal Info -> 2: Contacts -> 3: Done)
  Widget _buildStepperHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          _buildStepItem(1, 'Personal\nInfo'),
          _buildStepLine(_currentStep >= 2),
          _buildStepItem(2, 'Contacts\n'),
          _buildStepLine(_currentStep >= 3),
          _buildStepItem(3, 'Done\n'),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepNumber, String title) {
    final bool isActive = _currentStep == stepNumber;
    final bool isPassed = _currentStep > stepNumber;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isActive || isPassed) ? AppColors.primary : const Color(0xFFEDEDED),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isPassed
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isPassed) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 22, left: 8, right: 8),
        height: 2,
        color: isPassed ? AppColors.primary : const Color(0xFFE5E5E5),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1PersonalInfo();
      case 2:
        return _buildStep2Contacts();
      case 3:
        return _buildStep3Done();
      default:
        return const SizedBox();
    }
  }

  /// -------------------------------------------------------------
  /// STEP 1: Personal Details
  /// -------------------------------------------------------------
  Widget _buildStep1PersonalInfo() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          CustomInputField(
            label: 'Full Name',
            hintText: 'e.g. Priya Sharma',
            controller: _nameController,
            prefixIcon: Icons.person_outline_rounded,
            isRequired: true,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
          ),
          const SizedBox(height: 14),

          CustomInputField(
            label: 'Email',
            hintText: 'you@example.com',
            controller: _emailController,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
          ),
          const SizedBox(height: 14),

          CustomInputField(
            label: 'Phone Number',
            hintText: '+91 98765 43210',
            controller: _phoneController,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isRequired: true,
            validator: (v) => (v == null || v.trim().length < 8) ? 'Enter a valid phone number' : null,
          ),
          const SizedBox(height: 14),

          CustomInputField(
            label: 'Password',
            hintText: 'Min 6 characters',
            controller: _passwordController,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            isRequired: true,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
          ),
          const SizedBox(height: 14),

          // Age and Blood Group Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomInputField(
                  label: 'Age',
                  hintText: 'Optional',
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blood Group',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBloodGroup,
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Select',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.inputHint,
                        ),
                        filled: true,
                        fillColor: AppColors.inputBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.inputFocusedBorder, width: 1.8),
                        ),
                      ),
                      items: _bloodGroups.map((group) {
                        return DropdownMenuItem(
                          value: group,
                          child: Text(group, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedBloodGroup = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          CustomInputField(
            label: 'Address',
            hintText: 'Optional',
            controller: _addressController,
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          CustomButton(
            text: 'Next: Emergency Contacts',
            onPressed: () {
              if (_step1FormKey.currentState!.validate()) {
                setState(() => _currentStep = 2);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// -------------------------------------------------------------
  /// STEP 2: Emergency Contacts
  /// -------------------------------------------------------------
  Widget _buildStep2Contacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Contacts',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),

        // List of Contact Cards
        ...List.generate(_contacts.length, (index) {
          final c = _contacts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightPinkCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD4E2), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contact #${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    if (_contacts.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.primary),
                        onPressed: () => _removeContact(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                CustomInputField(
                  label: 'Name',
                  hintText: 'Contact name',
                  controller: c['name'],
                  isRequired: true,
                ),
                const SizedBox(height: 10),

                CustomInputField(
                  label: 'Phone',
                  hintText: 'Phone number',
                  controller: c['phone'],
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                ),
                const SizedBox(height: 10),

                CustomInputField(
                  label: 'Relation',
                  hintText: 'e.g. Father, Mother, Friend',
                  controller: c['relation'],
                ),
              ],
            ),
          );
        }),

        // Add More Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _addContact,
            icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
            label: const Text(
              'Add More',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: AppColors.primaryLight,
                width: 1.5,
                style: BorderStyle.solid,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Bottom Actions: Back & Submit
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Back',
                isOutlined: true,
                onPressed: () => setState(() => _currentStep = 1),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: CustomButton(
                text: 'Submit',
                isLoading: _isLoading,
                onPressed: _handleFinalSubmit,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// -------------------------------------------------------------
  /// STEP 3: Done / Completion
  /// -------------------------------------------------------------
  Widget _buildStep3Done() {
    return Column(
      children: [
        const SizedBox(height: 30),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGlow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 54,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Account Created!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your emergency safety network is ready.\nYou can now access live monitoring and emergency alerts.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        CustomButton(
          text: 'Go to Dashboard',
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.home,
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}
