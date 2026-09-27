import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/presentation/providers/auth_api_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final key = GlobalKey<FormState>();
  final first = TextEditingController();
  final last = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;
  @override void dispose() { first.dispose(); last.dispose(); email.dispose(); password.dispose(); confirm.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (!key.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await ref.read(authApiProvider).register({'first_name': first.text.trim(), 'last_name': last.text.trim(), 'email': email.text.trim(), 'password': password.text, 'password_confirmation': confirm.text});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful. Please login.')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_message(e)), backgroundColor: AppTheme.errorColor));
    } finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: key,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Create account', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextFormField(controller: first, decoration: const InputDecoration(labelText: 'First name'), validator: (v) => v == null || v.trim().isEmpty ? 'First name is required' : null),
                const SizedBox(height: 12),
                TextFormField(controller: last, decoration: const InputDecoration(labelText: 'Last name')),
                const SizedBox(height: 12),
                TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => v == null || !v.contains('@') ? 'Valid email is required' : null),
                const SizedBox(height: 12),
                TextFormField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password'), validator: (v) => v == null || v.length < 8 ? 'Minimum 8 characters' : null),
                const SizedBox(height: 12),
                TextFormField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password'), validator: (v) => v != password.text ? 'Passwords do not match' : null),
                const SizedBox(height: 24),
                loading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: submit, child: const Text('Register')),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Already have an account? Login')),
              ]),
            ),
          ),
        ),
      );
}

String _message(Object e) => e is DioException && e.response?.data is Map ? ((e.response!.data as Map)['message'] ?? (e.response!.data as Map)['errors'] ?? e.message).toString() : e.toString();
