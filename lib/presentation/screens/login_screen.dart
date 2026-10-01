import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';
import 'package:field_visit_app/presentation/screens/main_screen.dart';
import 'package:field_visit_app/presentation/screens/register_screen.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

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
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final result = await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      result.when(
        data: (user) {
          if (mounted && user != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        },
        loading: () {},
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.cellfinGreen,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF136B3E), // Cellfin Signature Forest Green
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ─── CELLFIN STYLE LOGO BOX ───────────────────
                      _buildLogo(),
                      const SizedBox(height: 28),

                      // ─── LOGIN FORM CARD ──────────────────────────
                      Container(
                        constraints: const BoxConstraints(maxWidth: 420),
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
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1F2937),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Enter your credentials to access field operations',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Receiver Account / Email Field
                              CellfinInputField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                hint: 'Receiver Account / Email Address',
                                prefixIcon: const Icon(Icons.account_circle_outlined, color: Color(0xFF6B7280), size: 22),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email or user ID';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // CellFin 6 Digit Pin / Password Field (Exact screenshot match!)
                              CellfinInputField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                hint: 'CellFin 6 Digit Pin / Password',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF6B7280), size: 22),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: const Color(0xFF6B7280),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your PIN or password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Forgot password link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Contact your field administrator to reset password.')),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      color: Color(0xFF136B3E),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Submit Button (Solid Forest Green, 10px radius, Exact match to screenshot)
                              ElevatedButton(
                                onPressed: authState.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF136B3E),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: authState.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                      )
                                    : const Text(
                                        'Submit',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an officer account? ",
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              'Register here',
                              style: TextStyle(
                                color: Color(0xFFFFB300), // Golden Yellow
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
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF136B3E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.location_city_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Field',
                      style: TextStyle(
                        color: Color(0xFF136B3E),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextSpan(
                      text: 'Visit',
                      style: TextStyle(
                        color: Color(0xFFFFB300),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Operations & Sales Management',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
