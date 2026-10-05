import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/presentation/providers/auth_api_provider.dart';
import 'package:field_visit_app/core/widgets/app_dropdown.dart';

class StorageSettingsScreen extends ConsumerStatefulWidget {
  const StorageSettingsScreen({super.key});

  @override
  ConsumerState<StorageSettingsScreen> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends ConsumerState<StorageSettingsScreen> {
  String provider = 'local';
  bool enabled = true;
  bool loading = true;
  bool saving = false;
  final accessKey = TextEditingController();
  final secretKey = TextEditingController();
  final region = TextEditingController();
  final bucket = TextEditingController();
  final endpoint = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    accessKey.dispose();
    secretKey.dispose();
    region.dispose();
    bucket.dispose();
    endpoint.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await ref.read(authApiProvider).storageSettings();
      final data =
          Map<String, dynamic>.from(response.data['data'] as Map? ?? {});
      if (mounted) {
        setState(() {
          provider = data['provider']?.toString() ?? 'local';
          enabled = data['enabled'] == true;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
      _showError(e);
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await ref.read(authApiProvider).updateStorageSettings({
        'provider': provider,
        'enabled': enabled,
        'credentials': {
          'access_key': accessKey.text.trim(),
          'secret_key': secretKey.text,
          'region': region.text.trim(),
          'bucket': bucket.text.trim(),
          'endpoint': endpoint.text.trim(),
        },
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage settings saved securely')));
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _test() async {
    try {
      await ref.read(authApiProvider).testStorageSettings();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage connection successful')));
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is DioException && error.response?.data is Map
        ? ((error.response!.data as Map)['message'] ??
                (error.response!.data as Map)['error'] ??
                error.message)
            .toString()
        : error.toString();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storage Settings')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('File storage provider',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                AppDropdownField<String>(
                  label: 'Provider',
                  icon: Icons.cloud_outlined,
                  value: provider,
                  options: const [
                    AppDropdownOption(
                      value: 'local',
                      title: 'Local Storage',
                      subtitle: 'Store files on this server',
                      leadingIcon: Icons.sd_storage_outlined,
                    ),
                    AppDropdownOption(
                      value: 's3',
                      title: 'Amazon S3',
                      subtitle: 'AWS S3 bucket',
                      leadingIcon: Icons.cloud_outlined,
                    ),
                    AppDropdownOption(
                      value: 'gcs',
                      title: 'Google Cloud Storage',
                      subtitle: 'GCS bucket',
                      leadingIcon: Icons.cloud_outlined,
                    ),
                    AppDropdownOption(
                      value: 'azure',
                      title: 'Azure Blob Storage',
                      subtitle: 'Azure container',
                      leadingIcon: Icons.cloud_outlined,
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => provider = value ?? 'local'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use selected provider'),
                  value: enabled,
                  activeColor: AppColors.cellfinGreen,
                  onChanged: (value) => setState(() => enabled = value),
                ),
                if (provider != 'local') ...[
                  _field(accessKey, 'Access key / Account name'),
                  _field(secretKey, 'Secret key / Account key', obscure: true),
                  _field(region, 'Region / Project ID'),
                  _field(bucket,
                      provider == 'azure' ? 'Container name' : 'Bucket name'),
                  _field(endpoint, 'Custom endpoint (optional)',
                      keyboard: TextInputType.url),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                        'Credentials are encrypted on the server and are never returned to the app after saving.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ],
                FilledButton.icon(
                    onPressed: saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Saving...' : 'Save settings')),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                    onPressed: _test,
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Test connection')),
              ],
            ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {bool obscure = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder())),
    );
  }
}
