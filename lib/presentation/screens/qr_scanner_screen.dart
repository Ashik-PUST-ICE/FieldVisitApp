import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});
  @override ConsumerState<QrScannerScreen> createState() => _QrScannerState();
}

class _QrScannerState extends ConsumerState<QrScannerScreen> {
  bool processing = false;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Scan outlet QR')), body: MobileScanner(onDetect: (capture) async { if (processing || capture.barcodes.isEmpty) return; final value = capture.barcodes.first.rawValue; if (value == null || value.isEmpty) return; setState(() => processing = true); try { final response = await ref.read(businessApiProvider).verifyQr(value); final payload = Map<String, dynamic>.from(response.data as Map); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(payload['message']?.toString() ?? 'QR verified successfully'))); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } finally { if (mounted) setState(() => processing = false); } }), floatingActionButton: processing ? const FloatingActionButton(onPressed: null, child: CircularProgressIndicator()) : null);
}
