import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/presentation/screens/login_screen.dart';
import 'package:field_visit_app/presentation/screens/main_screen.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';

class FieldVisitApp extends ConsumerWidget {
  const FieldVisitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Field Visit',
      theme: AppTheme.lightTheme,
      home: authState.value != null ? const MainScreen() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
