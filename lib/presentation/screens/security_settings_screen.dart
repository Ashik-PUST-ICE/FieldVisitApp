import 'package:dio/dio.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/presentation/providers/auth_api_provider.dart';
import 'package:field_visit_app/presentation/providers/auth_provider.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() =>
      _SecuritySettingsState();
}

class _SecuritySettingsState extends ConsumerState<SecuritySettingsScreen> {
  Map<String, dynamic> settings = {};
  bool loading = true;
  bool biometricBusy = false;

  bool _settingBool(String key) {
    final value = settings[key];
    return value == true ||
        value == 1 ||
        value?.toString().toLowerCase() == 'true' ||
        value?.toString() == '1';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await ref.read(authApiProvider).securitySettings();
      final payload = Map<String, dynamic>.from(response.data as Map);
      if (mounted)
        setState(() {
          settings = Map<String, dynamic>.from(payload['data'] as Map? ?? {});
          loading = false;
        });
    } catch (e) {
      if (mounted) setState(() => loading = false);
      _showError(e);
    }
  }

  Future<void> _run(Future<Response> Function() action, String success) async {
    try {
      await action();
      await _load();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error is DioException && error.response?.data is Map
        ? ((error.response!.data as Map)['message'] ??
                (error.response!.data as Map)['errors'] ??
                error.message)
            .toString()
        : error.toString();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setBiometric(bool value) async {
    if (biometricBusy) return;
    // Instant touch feedback; rolled back below if verification/API fails.
    setState(() {
      biometricBusy = true;
      settings['biometric_enabled'] = value;
    });
    try {
      if (!value) {
        await ref.read(authProvider.notifier).disableBiometricLogin();
        await _load();
        return;
      }
      if (!await ref.read(authProvider.notifier).canUseBiometrics()) {
        _showError(
            'No biometric (fingerprint/face) enrolled on this device. Add one in Android settings first.');
        setState(() => settings['biometric_enabled'] = false);
        return;
      }
      final enabledNow =
          await ref.read(authProvider.notifier).enableBiometricLogin();
      if (!enabledNow) {
        _showError(
            'Biometric verification failed or was cancelled. Try again.');
        setState(() => settings['biometric_enabled'] = false);
        return;
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric login enabled')));
      }
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => settings['biometric_enabled'] = !value);
    } finally {
      // Always unlock the switch — a thrown error used to leave it disabled forever.
      if (mounted) setState(() => biometricBusy = false);
    }
  }

  /// Instant switch feedback: flip UI immediately, roll back if the API rejects it.
  Future<void> _toggle(String key, bool value,
      Future<Response> Function() action, String success) async {
    final previous = settings[key];
    setState(() => settings[key] = value);
    try {
      await action();
      await _load();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
    } catch (e) {
      if (mounted) setState(() => settings[key] = previous);
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF101918) : const Color(0xFFF4FAF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF136B3E),
        foregroundColor: Colors.white,
        title: const Text('Settings',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.cellfinGreen))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 30),
                children: [
                  _settingCard(context,
                      icon: Icons.password_rounded,
                      title: 'Change PIN',
                      subtitle: settings['has_pin'] == true
                          ? 'PIN is already set'
                          : 'Create your secure PIN',
                      onTap: _changePin),
                  _settingCard(context,
                      icon: Icons.dialpad_rounded,
                      title: 'Update MNP',
                      subtitle: settings['mnp']?.toString() ?? 'Not configured',
                      onTap: _updateMnp),
                  _settingCard(context,
                      icon: Icons.sms_outlined,
                      title: 'Change SMS/OTP channel',
                      subtitle:
                          _channelLabel(settings['otp_channel']?.toString()),
                      onTap: _updateOtpChannel),
                  _settingCard(context,
                      icon: Icons.fingerprint_rounded,
                      title: 'Manage biometric verification',
                      subtitle: _settingBool('biometric_enabled')
                          ? 'Enabled'
                          : 'Disabled',
                      trailing: Switch(
                          value: _settingBool('biometric_enabled'),
                          activeColor: AppColors.cellfinGreen,
                          onChanged: biometricBusy ? null : _setBiometric)),
                  _settingCard(context,
                      icon: Icons.keyboard_alt_outlined,
                      title: 'Randomize PIN keyboard',
                      subtitle: 'Shuffle PIN keys for extra privacy',
                      trailing: Switch(
                          value: _settingBool('randomize_pin_keyboard'),
                          activeColor: AppColors.cellfinGreen,
                          onChanged: (value) => _toggle(
                              'randomize_pin_keyboard',
                              value,
                              () => ref
                                  .read(authApiProvider)
                                  .updateRandomPinKeyboard(value),
                              'PIN keyboard preference updated'))),
                ],
              ),
            ),
    );
  }

  Widget _settingCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      VoidCallback? onTap,
      Widget? trailing}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF172321) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: dark ? const Color(0xFF2A403B) : const Color(0xFFE4E9E5)),
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 4,
                    offset: Offset(0, 2))
              ],
      ),
      child: ListTile(
        minVerticalPadding: 14,
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        leading: Icon(icon,
            color: dark ? const Color(0xFF37C5A7) : const Color(0xFF137044),
            size: 35),
        title: Text(title,
            style: TextStyle(
                color: dark ? Colors.white : const Color(0xFF202124),
                fontWeight: FontWeight.w500,
                fontSize: 20)),
        subtitle: subtitle == ''
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(subtitle,
                    style: TextStyle(
                        color: dark
                            ? const Color(0xFFB0C4BF)
                            : const Color(0xFF65736A),
                        fontSize: 12))),
        trailing: trailing ??
            Icon(Icons.chevron_right_rounded,
                color: dark ? const Color(0xFFB0C4BF) : const Color(0xFF3F4942),
                size: 36),
        onTap: onTap,
      ),
    );
  }

  Future<void> _changePin() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Change PIN'),
                content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (settings['has_pin'] == true)
                    _pinField(current, 'Current PIN'),
                  if (settings['has_pin'] == true) const SizedBox(height: 10),
                  _pinField(next, 'New PIN (4–6 digits)'),
                  const SizedBox(height: 10),
                  _pinField(confirm, 'Confirm new PIN')
                ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () async {
                        if (next.text.length < 4 || next.text != confirm.text)
                          return;
                        try {
                          await ref.read(authApiProvider).changePin({
                            'current_pin': current.text,
                            'new_pin': next.text,
                            'new_pin_confirmation': confirm.text
                          });
                          if (dialogContext.mounted)
                            Navigator.pop(dialogContext);
                          await _load();
                        } catch (e) {
                          _showError(e);
                        }
                      },
                      child: const Text('Save PIN'))
                ]));
    current.dispose();
    next.dispose();
    confirm.dispose();
  }

  Widget _pinField(TextEditingController controller, String label) {
    final randomized = settings['randomize_pin_keyboard'] == true;
    if (!randomized)
      return TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label));
    return _RandomPinField(controller: controller, label: label);
  }

  Future<void> _updateMnp() async {
    final controller = TextEditingController();
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: const Text('Update MNP'),
                content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                        labelText: 'MNP / mobile network provider')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () async {
                        if (controller.text.trim().isEmpty) return;
                        try {
                          await ref
                              .read(authApiProvider)
                              .updateMnp(controller.text.trim());
                          if (dialogContext.mounted)
                            Navigator.pop(dialogContext);
                          await _load();
                        } catch (e) {
                          _showError(e);
                        }
                      },
                      child: const Text('Update'))
                ]));
    controller.dispose();
  }

  Future<void> _updateOtpChannel() async {
    final selected = settings['otp_channel']?.toString() ?? 'sms';
    final value = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
            title: const Text('Choose SMS/OTP channel'),
            children: ['sms', 'email', 'whatsapp']
                .map((channel) => RadioListTile<String>(
                    value: channel,
                    groupValue: selected,
                    title: Text(_channelLabel(channel)),
                    onChanged: (value) => Navigator.pop(dialogContext, value)))
                .toList()));
    if (value != null)
      await _run(() => ref.read(authApiProvider).updateOtpChannel(value),
          'OTP channel updated');
  }

  String _channelLabel(String? value) => switch (value) {
        'email' => 'Email',
        'whatsapp' => 'WhatsApp',
        _ => 'SMS'
      };
}

class _RandomPinField extends StatefulWidget {
  const _RandomPinField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  State<_RandomPinField> createState() => _RandomPinFieldState();
}

class _RandomPinFieldState extends State<_RandomPinField> {
  late List<String> keys;

  @override
  void initState() {
    super.initState();
    keys = List.generate(10, (index) => '$index')..shuffle(math.Random());
  }

  void _add(String value) {
    if (widget.controller.text.length < 6) widget.controller.text += value;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
          controller: widget.controller,
          readOnly: true,
          obscureText: true,
          decoration: InputDecoration(
              labelText: widget.label,
              suffixIcon: IconButton(
                  icon: const Icon(Icons.backspace_outlined),
                  onPressed: () {
                    if (widget.controller.text.isNotEmpty)
                      widget.controller.text = widget.controller.text
                          .substring(0, widget.controller.text.length - 1);
                    setState(() {});
                  }))),
      const SizedBox(height: 6),
      Wrap(
          spacing: 6,
          runSpacing: 6,
          children: keys
              .map((key) => SizedBox(
                  width: 52,
                  height: 38,
                  child: OutlinedButton(
                      onPressed: () => _add(key),
                      child: Text(key,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)))))
              .toList()),
    ]);
  }
}
