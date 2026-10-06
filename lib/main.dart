import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';
import 'package:field_visit_app/core/l10n/strings_en.dart';
import 'package:field_visit_app/core/theme/app_theme.dart';
import 'package:field_visit_app/data/auth_api.dart';
import 'package:field_visit_app/data/models/user.dart';
import 'package:field_visit_app/presentation/screens/login_screen.dart';
import 'package:field_visit_app/presentation/screens/main_screen.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';
import 'package:field_visit_app/presentation/providers/theme_provider.dart';

void main() {
  runApp(const ProviderScope(child: _BackendBridge(child: FieldVisitApp())));
}

/// Attaches the locale -> backend push once, so core/l10n never imports
/// presentation providers (no import cycle) yet language changes still
/// reach `PUT /profile {locale}`.
class _BackendBridge extends ConsumerStatefulWidget {
  final Widget child;
  const _BackendBridge({required this.child});

  @override
  ConsumerState<_BackendBridge> createState() => _BackendBridgeState();
}

class _BackendBridgeState extends ConsumerState<_BackendBridge> {
  @override
  void initState() {
    super.initState();
    registerLocaleBackend((code) async {
      try {
        final api = AuthApi(
          publicClient: ref.read(authApiClientProvider),
          userClient: ref.read(authUserApiClientProvider),
        );
        await api.updateProfile({'locale': code});
        return true;
      } catch (_) {
        return false;
      }
    });
  }

  @override
  void dispose() {
    registerLocaleBackend(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class FieldVisitApp extends ConsumerWidget {
  const FieldVisitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final darkMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    // Backend wins: a language saved on another device applies on login
    // and whenever the profile refetches.
    ref.listen<AsyncValue<User?>>(authProvider, (prev, next) {
      final code = next.valueOrNull?.locale;
      if (code == 'bn' || code == 'en') {
        ref.read(localeProvider.notifier).syncFromServer(code);
      }
    });

    return MaterialApp(
      title: enStrings['appName'] ?? 'Field Visit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('bn')],
      // Custom en/bn strings come from core/l10n (tr/ref), while the
      // framework widgets (Drawer, dialogs, date pickers) need the
      // Material + Cupertino delegates for their built-in labels.
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authState.value != null ? const MainScreen() : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
