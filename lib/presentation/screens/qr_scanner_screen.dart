import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});
  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerState();
}

class _QrScannerState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _manualCtrl = TextEditingController();

  bool processing = false;
  bool torchOn = false;

  static const _green = Color(0xFF136B3E);

  @override
  void dispose() {
    _controller.dispose();
    _manualCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify(String value) async {
    if (processing || value.trim().isEmpty) return;
    setState(() => processing = true);
    try {
      final response =
          await ref.read(businessApiProvider).verifyQr(value.trim());
      final payload = Map<String, dynamic>.from(response.data as Map);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(payload['message']?.toString() ??
              tr(ref, 'qrVerified')),
          backgroundColor: _green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  void _toggleTorch() {
    setState(() => torchOn = !torchOn);
    _controller.toggleTorch();
  }

  Future<void> _openManualEntry() async {
    final entered = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(trOf(dialogContext, 'enterQrCode')),
        content: TextField(
          controller: _manualCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: trOf(dialogContext, 'qrCodeToken'),
            hintText: trOf(dialogContext, 'pasteOrTypeCode'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(trOf(dialogContext, 'cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, _manualCtrl.text.trim()),
            child: Text(trOf(dialogContext, 'verify')),
          ),
        ],
      ),
    );
    _manualCtrl.clear();
    if (entered != null && entered.isNotEmpty) _verify(entered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(tr(ref, 'scanOutletQr'),
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final value = capture.barcodes.firstOrNull?.rawValue;
              if (value != null && value.isNotEmpty) _verify(value);
            },
          ),

          // Dimmed surround with a clear scan window.
          Container(color: Colors.black.withOpacity(0.45)),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: _green, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 150,
            child: Text(
              tr(ref, 'alignQrFrame'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13.5),
            ),
          ),

          // All controls in one row, each with a label.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 26),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.72),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  _ActionButton(
                    icon: torchOn
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    label: torchOn ? tr(ref, 'torchOff') : tr(ref, 'torch'),
                    active: torchOn,
                    onTap: _toggleTorch,
                  ),
                  const SizedBox(width: 10),
                  _ActionButton(
                    icon: Icons.keyboard_rounded,
                    label: tr(ref, 'typeCode'),
                    onTap: _openManualEntry,
                  ),
                  const SizedBox(width: 10),
                  _ActionButton(
                    icon: processing
                        ? Icons.hourglass_top_rounded
                        : Icons.refresh_rounded,
                    label: tr(ref, 'rescan'),
                    onTap: processing
                        ? null
                        : () {
                            setState(() => processing = false);
                            _controller.start();
                          },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One labelled control in the QR screen action row.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF136B3E);
    final enabled = onTap != null;
    final color = enabled ? Colors.white : Colors.white24;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: active
                ? green
                : (enabled
                    ? Colors.white.withOpacity(0.12)
                    : Colors.white.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? green : Colors.white24,
              width: active ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
