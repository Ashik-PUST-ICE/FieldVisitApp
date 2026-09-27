import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/presentation/providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reports'), actions: [IconButton(onPressed: () => ref.invalidate(reportsProvider), icon: const Icon(Icons.refresh))]),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load reports\n$e', textAlign: TextAlign.center)),
        data: (data) => ListView(padding: const EdgeInsets.all(16), children: [
          _section('Visit report', data['visits'] as Map<String, dynamic>),
          _section('Order report', data['orders'] as Map<String, dynamic>),
          _officers(data['officers'] as Map<String, dynamic>),
        ],),
      ),
    );
  }

  Widget _section(String title, Map<String, dynamic> values) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...values.entries.map((entry) => ListTile(dense: true, title: Text(entry.key.replaceAll('_', ' ')), trailing: Text('${entry.value}'))),
          ]),
        ),
      );

  Widget _officers(Map<String, dynamic> values) {
    final rows = values['rows'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Officer performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (rows is List)
            ...rows.map((row) => ListTile(title: Text('Officer #${row['user_id']}'), trailing: Text('${row['total_visits']} visits')))
          else
            const Text('No officer data'),
        ]),
      ),
    );
  }
}
