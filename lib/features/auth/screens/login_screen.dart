import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_input.dart';
import '../../../routes/app_routes.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService().login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      _showError(result.errorMessage ?? 'Login failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopBanner(size),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Login to continue',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    CustomInputField(
                      label: 'Email',
                      hintText: 'Enter your email',
                      controller: _emailController,
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Please enter your email';
                        if (!val.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    CustomInputField(
                      label: 'Password',
                      hintText: 'Enter your password',
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
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please enter your password';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Login',
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Color(0xFFE2E2E2))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text('OR', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: Color(0xFFE2E2E2))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Create New Account',
                      isOutlined: true,
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(Size size) {
    return Container(
      width: double.infinity,
      height: size.height * 0.26,
      decoration: const BoxDecoration(
        color: AppColors.headerPink,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Center(
        child: Container(
          width: 115,
          height: 115,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/images/Logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.primary,
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}