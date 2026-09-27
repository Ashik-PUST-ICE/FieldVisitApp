import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/presentation/screens/login_screen.dart';
import 'package:field_visit_app/presentation/screens/main_screen.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';
import 'package:field_visit_app/presentation/providers/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: FieldVisitApp()));
}

class FieldVisitApp extends ConsumerWidget {
  const FieldVisitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final darkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Field Visit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: authState.value != null ? const MainScreen() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
