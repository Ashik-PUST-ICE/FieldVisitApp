import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/utils/map_credentials_store.dart';
import 'package:field_visit_app/presentation/screens/map_screen.dart';

/// In-app form for the Google Maps credential.
///
/// The native Android Maps SDK only reads its key from AndroidManifest.xml at
/// process start, so the key is stored in [MapCredentialsStore] (encrypted) and
/// handed to the WebView-based map on the Map screen. Saving here takes effect
/// immediately - no rebuild required.
class MapSettingsScreen extends ConsumerStatefulWidget {
  const MapSettingsScreen({super.key});

  @override
  ConsumerState<MapSettingsScreen> createState() => _MapSettingsScreenState();
}

class _MapSettingsScreenState extends ConsumerState<MapSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _store = MapCredentialsStore();

  bool _obscure = true;
  bool _loading = true;
  bool _busy = false;
  MapKeyCheck? _check;
  String? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await _store.read();
    if (!mounted) return;
    setState(() {
      _controller.text = saved ?? '';
      _loading = false;
      _status = saved == null ? null : 'A key is already saved';
    });
  }

  Future<void> _test() async {
    setState(() {
      _busy = true;
      _check = null;
    });
    final result = await _store.validate(_controller.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _check = result;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    await _store.save(_controller.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _obscure = true;
      _status = 'Saved - the map now uses this key.';
      _check = null;
    });
  }

  Future<void> _clear() async {
    await _store.clear();
    if (!mounted) return;
    setState(() {
      _controller.clear();
      _status = 'Key removed.';
      _check = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map API Credential')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Maps API Key',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Stored encrypted on this device and used by the '
                          'Live Route map. Applies immediately.',
                          style: TextStyle(fontSize: 12.5),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _controller,
                            obscureText: _obscure,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: 'API Key',
                              hintText: 'AIza...',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Enter your Google Maps API key'
                                : null,
                          ),
                        ),
                        if (_status != null) ...[
                          const SizedBox(height: 10),
                          Text(_status!, style: const TextStyle(fontSize: 12)),
                        ],
                        if (_check != null) ...[
                          const SizedBox(height: 12),
                          _CheckRow(check: _check!),
                        ],
                        const SizedBox(height: 18),
                        _buttons(context),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _openMapTile(context),
                const SizedBox(height: 16),
                const _HelpCard(),
              ],
            ),
    );
  }

  Widget _buttons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _test,
                icon: const Icon(Icons.wifi_tethering_rounded),
                label: const Text('Test key'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy ? null : _clear,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Remove saved key'),
        ),
      ],
    );
  }

  Widget _openMapTile(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.map_outlined, color: AppColors.cellfinGreen),
        title: const Text('Open Live Route map'),
        subtitle: const Text('See the map using the saved key'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const MapScreen())),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final MapKeyCheck check;
  const _CheckRow({required this.check});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          check.valid
              ? Icons.check_circle_rounded
              : Icons.error_outline_rounded,
          size: 18,
          color: check.valid ? AppColors.success : AppColors.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(check.message, style: const TextStyle(fontSize: 12.5)),
        ),
      ],
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Before the key works',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            SizedBox(height: 8),
            Text(
              '1. In Google Cloud Console enable "Maps JavaScript API".\n'
              '2. Create an API key and restrict it to this app.\n'
              '3. Paste it above and press Save.',
              style: TextStyle(fontSize: 12.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
