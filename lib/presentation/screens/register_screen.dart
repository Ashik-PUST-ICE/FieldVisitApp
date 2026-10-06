import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
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
        SnackBar(
          content: Text(tr(ref, 'accountCreated')),
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
                          Text(
                            tr(ref, 'createAccount'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(ref, 'registerAsFieldOps'),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 20),

                          // Name Row
                          Row(
                            children: [
                              Expanded(
                                child: CellfinInputField(
                                  controller: first,
                                  hint: '${tr(ref, 'firstNameStar')} *',
                                  prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF6B7280),
                                      size: 20),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? tr(ref, 'required')
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CellfinInputField(
                                  controller: last,
                                  hint: tr(ref, 'lastNameLower'),
                                  prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      color: Color(0xFF6B7280),
                                      size: 20),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Email
                          CellfinInputField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            hint: '${tr(ref, 'workEmail')} *',
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: Color(0xFF6B7280), size: 20),
                            validator: (v) => v == null || !v.contains('@')
                                ? tr(ref, 'enterValidEmail')
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Password
                          CellfinInputField(
                            controller: password,
                            obscureText: _obscurePass,
                            hint: '${tr(ref, 'password8chars')} *',
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: Color(0xFF6B7280), size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF6B7280),
                                  size: 20),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                            validator: (v) => v == null || v.length < 8
                                ? tr(ref, 'passwordMinLength')
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Confirm Password
                          CellfinInputField(
                            controller: confirm,
                            obscureText: _obscureConfirm,
                            hint: '${tr(ref, 'confirmPassword')} *',
                            prefixIcon: const Icon(Icons.lock_reset_rounded,
                                color: Color(0xFF6B7280), size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF6B7280),
                                  size: 20),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                            validator: (v) => v != password.text
                                ? tr(ref, 'passwordsDoNotMatch')
                                : null,
                          ),
                          const SizedBox(height: 18),

                          // Submit Action
                          ElevatedButton(
                            onPressed: loading ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF136B3E),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.2))
                                : Text(
                                    tr(ref, 'submit'),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white),
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
                      Text(tr(ref, 'alreadyRegistered'),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          tr(ref, 'signIn'),
                          style: const TextStyle(
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
