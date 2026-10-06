import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';
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
            SnackBar(content: Text(trOf(context, 'storageSavedSecure'))));
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
            SnackBar(content: Text(trOf(context, 'storageConnectionOk'))));
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
      appBar: AppBar(title: Text(trOf(context, 'storageSettings'))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(tr(ref, 'fileStorageProvider'),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                AppDropdownField<String>(
                  label: tr(ref, 'provider'),
                  icon: Icons.cloud_outlined,
                  value: provider,
                  options: [
                    AppDropdownOption(
                      value: 'local',
                      title: tr(ref, 'localStorage'),
                      subtitle: tr(ref, 'storeFilesLocal'),
                      leadingIcon: Icons.sd_storage_outlined,
                    ),
                    AppDropdownOption(
                      value: 's3',
                      title: 'Amazon S3',
                      subtitle: tr(ref, 'awsS3Bucket'),
                      leadingIcon: Icons.cloud_outlined,
                    ),
                    AppDropdownOption(
                      value: 'gcs',
                      title: 'Google Cloud Storage',
                      subtitle: tr(ref, 'gcsBucket'),
                      leadingIcon: Icons.cloud_outlined,
                    ),
                    AppDropdownOption(
                      value: 'azure',
                      title: 'Azure Blob Storage',
                      subtitle: tr(ref, 'azureContainer'),
                      leadingIcon: Icons.cloud_outlined,
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => provider = value ?? 'local'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(ref, 'useSelectedProvider')),
                  value: enabled,
                  activeColor: AppColors.cellfinGreen,
                  onChanged: (value) => setState(() => enabled = value),
                ),
                if (provider != 'local') ...[
                  _field(accessKey, tr(ref, 'accessKeyLabel')),
                  _field(secretKey, tr(ref, 'secretKeyLabel'),
                      obscure: true),
                  _field(region, tr(ref, 'regionLabel')),
                  _field(
                      bucket,
                      provider == 'azure'
                          ? tr(ref, 'containerName')
                          : tr(ref, 'bucketName')),
                  _field(endpoint, tr(ref, 'customEndpoint'),
                      keyboard: TextInputType.url),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(tr(ref, 'credentialsEncryptedNote'),
                        style: const TextStyle(color: Colors.grey)),
                  ),
                ],
                FilledButton.icon(
                    onPressed: saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(saving
                        ? tr(ref, 'saving')
                        : tr(ref, 'saveSettings'))),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                    onPressed: _test,
                    icon: const Icon(Icons.wifi_tethering),
                    label: Text(tr(ref, 'testConnection'))),
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
