import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_visit_app/core/l10n/strings_bn.dart';
import 'package:field_visit_app/core/l10n/strings_en.dart';

/// Backend bridge, attached at runtime by the presentation layer
/// (see auth_provider) so core/l10n has no import cycle.
/// Returns true when the value also reached the server.
Future<bool> Function(String code)? pushLocaleToServer;

void registerLocaleBackend(Future<bool> Function(String code)? push) {
  pushLocaleToServer = push;
}

/// App language: 'en' or 'bn'.
///
/// Local-first: the choice applies instantly from SharedPreferences and is
/// then pushed to the backend (`PUT /profile {locale}`) so it follows the
/// user across devices. On login the server value wins, so a language set
/// on another phone appears here automatically.
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  static const _key = 'app_locale';

  bool get isBangla => state.languageCode == 'bn';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = switch (prefs.getString(_key)) {
      'bn' => 'bn',
      'en' => 'en',
      _ => null,
    };
    if (code != null) state = Locale(code);
  }

  /// Applies the language from the logged-in account (backend wins).
  /// Call after login / profile fetch; falls back to the saved device value.
  Future<void> syncFromServer(String? serverLocale) async {
    final code =
        switch (serverLocale) { 'bn' => 'bn', 'en' => 'en', _ => null };
    if (code == null) return;
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  Future<bool> setLocale(String code) async {
    if (code != 'bn' && code != 'en') return false;
    if (state.languageCode == code) return true;

    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);

    // Push to backend in the background; the app already switched.
    try {
      final push = pushLocaleToServer;
      if (push == null) return false;
      return await push(code);
    } catch (_) {
      // Offline or logged out: device value stays, syncs on next change/login.
      return false;
    }
  }

  Future<void> toggle() => setLocale(isBangla ? 'en' : 'bn');
}

/// Reads a localized string for the current locale.
/// Falls back to English, then to the key itself, so a missing Bangla
/// entry can never blank out the UI.
String tr(WidgetRef ref, String key) {
  final code = ref.watch(localeProvider).languageCode;
  if (code == 'bn') return bnStrings[key] ?? enStrings[key] ?? key;
  return enStrings[key] ?? key;
}

/// Same as [tr] for places that only have a BuildContext.
/// One-shot translation lookup — does NOT subscribe [context] to the
/// ProviderScope.
///
/// NOTE: a `listen: true` lookup registered the calling element (e.g. a
/// bottom-sheet/dialog body) as a dependent of the inherited
/// ProviderScope. If that route got popped while a provider notification
/// was mid-flight, the framework asserted on element unmount
/// (`framework.dart:6065 '_dependents.isEmpty'`). Reads are therefore
/// non-listening; code that must rebuild on locale change should use
/// [tr] inside a Consumer instead.
String trOf(BuildContext context, String key) {
  final container = ProviderScope.containerOf(context, listen: false);
  final code = container.read(localeProvider).languageCode;
  if (code == 'bn') return bnStrings[key] ?? enStrings[key] ?? key;
  return enStrings[key] ?? key;
}

/// Locale code the server understands; anything else becomes 'en'.
String normalizeLocale(String? code) => code == 'bn' ? 'bn' : 'en';
