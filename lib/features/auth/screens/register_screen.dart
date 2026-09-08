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
  int _currentStep = 1;

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _selectedBloodGroup;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<Map<String, TextEditingController>> _contacts = [
    {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'relation': TextEditingController(),
    }
  ];

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

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
    for (int i = 0; i < _contacts.length; i++) {
      final name = _contacts[i]['name']!.text.trim();
      final phone = _contacts[i]['phone']!.text.trim();
      final relation = _contacts[i]['relation']!.text.trim();
      if (name.isEmpty || phone.isEmpty || relation.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields for Contact #${i + 1}')),
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
      'bloodGroup': _selectedBloodGroup ?? 'O+',
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
      setState(() => _currentStep = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? 'Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerPink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _currentStep == 1 ? _buildStep1() : _currentStep == 2 ? _buildStep2() : _buildStep3(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          _stepCircle(1, 'Personal'),
          _stepLine(_currentStep >= 2),
          _stepCircle(2, 'Contacts'),
          _stepLine(_currentStep >= 3),
          _stepCircle(3, 'Done'),
        ],
      ),
    );
  }

  Widget _stepCircle(int step, String label) {
    final active = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primary : Color(0xFFEDEDED),
          ),
          child: Center(
            child: _currentStep > step
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text('$step', style: TextStyle(color: active ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: active ? AppColors.primary : AppColors.textMuted)),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18), color: active ? AppColors.primary : Color(0xFFE5E5E5)),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomInputField(
            label: 'Full Name',
            hintText: 'e.g. Priya Sharma',
            controller: _nameController,
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          CustomInputField(
            label: 'Email',
            hintText: 'you@example.com',
            controller: _emailController,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
          ),
          const SizedBox(height: 14),
          CustomInputField(
            label: 'Phone',
            hintText: '+91 98765 43210',
            controller: _phoneController,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().length < 8) ? 'Valid phone required' : null,
          ),
          const SizedBox(height: 14),
          CustomInputField(
            label: 'Password',
            hintText: 'Min 6 characters',
            controller: _passwordController,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomInputField(
                  label: 'Age',
                  hintText: '24',
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedBloodGroup,
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _bloodGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _selectedBloodGroup = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomInputField(
            label: 'Address',
            hintText: 'Your address',
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
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(_contacts.length, (index) {
            final nameController = _contacts[index]['name']!;
            final phoneController = _contacts[index]['phone']!;
            final relationController = _contacts[index]['relation']!;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightPinkCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contact #${index + 1}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
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
                    controller: nameController,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  CustomInputField(
                    label: 'Phone',
                    hintText: 'Phone number',
                    controller: phoneController,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  CustomInputField(
                    label: 'Relation',
                    hintText: 'e.g. Father, Mother, Friend',
                    controller: relationController,
                    prefixIcon: Icons.favorite_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            );
          }),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _addContact,
              icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
              label: const Text('Add More', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: CustomButton(text: 'Back', isOutlined: true, onPressed: () => setState(() => _currentStep = 1)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: CustomButton(text: 'Submit', isLoading: _isLoading, onPressed: _handleFinalSubmit),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 50),
        ),
        const SizedBox(height: 20),
        const Text('Account Created!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('Your safety network is ready.'),
        const SizedBox(height: 30),
        CustomButton(
          text: 'Go to Dashboard',
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
        ),
      ],
    );
  }
}