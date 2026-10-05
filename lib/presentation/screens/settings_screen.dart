import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';
import 'package:field_visit_app/presentation/screens/map_settings_screen.dart';
import 'package:field_visit_app/presentation/screens/security_settings_screen.dart';
import 'package:field_visit_app/presentation/screens/storage_settings_screen.dart';

/// Central Settings hub.
///
/// The drawer used to send "Settings" straight to [SecuritySettingsScreen],
/// which made the other configuration screens (storage, map credential)
/// effectively hidden. Everything configurable now lives behind this list.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(authProvider).valueOrNull?.roles ?? const [];
    final isAdmin =
        roles.any((r) => r == 'super-admin' || r == 'special-super-admin');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _groupLabel(context, 'SECURITY'),
          _tile(
            context,
            icon: Icons.lock_person_rounded,
            color: const Color(0xFF059669),
            title: 'Security & Privacy',
            subtitle: 'PIN, biometrics, OTP channel',
            screen: const SecuritySettingsScreen(),
          ),
          const SizedBox(height: 20),
          _groupLabel(context, 'MAPS'),
          _tile(
            context,
            icon: Icons.map_rounded,
            color: const Color(0xFF0EA5E9),
            title: 'Map API Credential',
            subtitle: 'Google Maps key for Live Route',
            screen: const MapSettingsScreen(),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 20),
            _groupLabel(context, 'ADMINISTRATION'),
            _tile(
              context,
              icon: Icons.cloud_outlined,
              color: const Color(0xFF6366F1),
              title: 'Storage Settings',
              subtitle: 'Provider, bucket and connection test',
              screen: const StorageSettingsScreen(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _groupLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.25)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
