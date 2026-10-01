import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/presentation/providers/auth_api_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final first = TextEditingController();
  final last = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    first.dispose();
    last.dispose();
    email.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await ref.read(authApiProvider).register({
        'first_name': first.text.trim(),
        'last_name': last.text.trim(),
        'email': email.text.trim(),
        'password': password.text,
        'password_confirmation': confirm.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please sign in.'),
          backgroundColor: AppColors.cellfinGreen,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is DioException && e.response?.data is Map) {
          final data = e.response!.data as Map;
          msg = (data['message'] ?? data['errors'] ?? e.message).toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cellfinGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Form Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 440),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(26),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Register as a new field operations specialist',
                            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 20),

                          // Name Row
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: first,
                                  decoration: InputDecoration(
                                    labelText: 'First Name *',
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: last,
                                  decoration: InputDecoration(
                                    labelText: 'Last Name',
                                    filled: true,
                                    fillColor: const Color(0xFFF9FAFB),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Email
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Work Email *',
                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF136B3E), size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: password,
                            obscureText: _obscurePass,
                            decoration: InputDecoration(
                              labelText: 'Password (8+ chars) *',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF136B3E), size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v == null || v.length < 8 ? 'Minimum 8 characters' : null,
                          ),
                          const SizedBox(height: 14),

                          // Confirm Password
                          TextFormField(
                            controller: confirm,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password *',
                              prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF136B3E), size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => v != password.text ? 'Passwords do not match' : null,
                          ),
                          const SizedBox(height: 22),

                          // Register Action
                          ElevatedButton(
                            onPressed: loading ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF136B3E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            child: loading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text(
                                    'CREATE ACCOUNT',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already registered? ', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Color(0xFFFFB300),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFFFB300),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
