import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/widgets/app_dropdown.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/presentation/providers/assignments_provider.dart';
import 'package:field_visit_app/presentation/providers/directory_provider.dart';
import 'package:field_visit_app/presentation/providers/outlets_provider.dart';

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentsProvider);
    // Resolve the ids the API returns into real names for the list.
    final outlets = ref.watch(outletsProvider).valueOrNull ?? const [];
    final users = ref.watch(usersProvider).valueOrNull ?? const [];

    String outletName(Object? id) {
      final match = outlets.where((o) => o.id == id).firstOrNull;
      return match?.name ?? 'Outlet #$id';
    }

    String userName(Object? id) {
      final match =
          users.where((u) => (u['id'] as num?)?.toInt() == id).firstOrNull;
      final name =
          (match?['full_name'] ?? match?['name'] ?? '').toString().trim();
      return name.isEmpty ? 'User #$id' : name;
    }

    return Scaffold(
        appBar: AppBar(title: const Text('Outlet assignments')),
        body: RefreshIndicator(
            onRefresh: ref.read(assignmentsProvider.notifier).fetch,
            child: state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(_message(e))),
                data: (items) => items.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 220),
                        Center(child: Text('No assignments found'))
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
                          final outletId = (item['outlet_id'] as num?)?.toInt();
                          final userId = (item['user_id'] as num?)?.toInt();
                          return Card(
                              child: ListTile(
                                  leading: const Icon(Icons.person_pin),
                                  title: Text(outletName(outletId)),
                                  subtitle: Text(
                                      '${userName(userId)}${item['status'] != null ? '  •  ${item['status']}' : ''}'),
                                  trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => ref
                                          .read(assignmentsProvider.notifier)
                                          .remove(
                                              (item['id'] as num).toInt()))));
                        }))),
        floatingActionButton: FloatingActionButton(
            heroTag: 'assignments_add',
            onPressed: () => _create(context, ref),
            child: const Icon(Icons.add)));
  }
}

Future<void> _create(BuildContext context, WidgetRef ref) async {
  final outlets = ref.read(outletsProvider).valueOrNull ?? const [];
  if (outlets.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Create an outlet first')));
    return;
  }
  final users = ref.read(usersProvider).valueOrNull ?? const [];
  if (users.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users available to assign')));
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  int? outletId = outlets.first.id;
  int? userId;

  String outletLabel() =>
      outlets.where((o) => o.id == outletId).map((o) => o.name).firstOrNull ??
      'not selected';

  String officerLabel() {
    final match =
        users.where((u) => (u['id'] as num?)?.toInt() == userId).firstOrNull;
    final name =
        (match?['full_name'] ?? match?['name'] ?? '').toString().trim();
    return name.isEmpty ? 'not selected' : name;
  }

  Future<void> submit() async {
    if (userId == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Please select a field officer')));
      return;
    }
    try {
      await ref
          .read(assignmentsProvider.notifier)
          .save({'outlet_id': outletId, 'user_id': userId}, null);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_message(e))));
    }
  }

  Future<void> refreshLists() async {
    await Future.wait([
      ref.read(outletsProvider.notifier).fetchOutlets(),
      ref.read(usersProvider.notifier).fetch(),
    ]);
    messenger.showSnackBar(
        const SnackBar(content: Text('Outlets and officers refreshed')));
  }

  void info(String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  await CellfinFormModal.show<void>(
    context: context,
    title: 'Assign Outlet',
    officerName: 'OUTLET ALLOCATION',
    officerInfo: 'Assign a field officer to an outlet',
    cards: const [
      CellfinCardItem(title: 'Outlet', icon: Icons.storefront_outlined),
      CellfinCardItem(title: 'Officer', icon: Icons.badge_outlined),
      CellfinCardItem(title: 'Confirm', icon: Icons.verified_outlined),
      CellfinCardItem(title: 'Sync', icon: Icons.sync_rounded),
    ],
    submitText: 'Assign Outlet',
    // Every card now does its OWN job instead of only highlighting:
    //   0 Outlet  -> reports the outlet currently picked
    //   1 Officer -> reports the officer currently picked
    //   2 Confirm -> validates, and saves only when the form is complete
    //   3 Sync    -> re-fetches outlets + officers so the lists are current
    onCardTap: (index) {
      switch (index) {
        case 0:
          info('Outlet: ${outletLabel()}');
        case 1:
          info('Field officer: ${officerLabel()}');
        case 2:
          if (userId == null) {
            info('Pick a field officer to confirm');
          } else {
            submit();
          }
        case 3:
          refreshLists();
      }
    },
    fields: [
      StatefulBuilder(
        builder: (context, setDropState) => AppDropdownField<int>(
          label: 'Outlet',
          hint: 'Select outlet',
          value: outletId,
          options: outlets
              .map((o) => AppDropdownOption<int>(
                    value: o.id,
                    title: o.name,
                    leadingIcon: Icons.storefront_outlined,
                  ))
              .toList(),
          onChanged: (v) => setDropState(() => outletId = v),
        ),
      ),
      StatefulBuilder(
        builder: (context, setDropState) => AppDropdownField<int>(
          label: 'Field Officer',
          hint: 'Select officer',
          value: userId,
          options: users
              .map((u) {
                final id = (u['id'] as num?)?.toInt();
                final name =
                    (u['full_name'] ?? u['name'] ?? '').toString().trim();
                return AppDropdownOption<int>(
                  value: id ?? 0,
                  title: name.isEmpty ? 'User #$id' : name,
                  subtitle: (u['email'] ?? u['unique_id'])?.toString(),
                  leadingIcon: Icons.person_outline_rounded,
                );
              })
              .where((o) => o.value != 0)
              .toList(),
          onChanged: (v) => setDropState(() => userId = v),
        ),
      ),
    ],
    onSubmit: submit,
  );
}

String _message(Object e) => e is DioException && e.response?.data is Map
    ? ((e.response!.data as Map)['message'] ??
            (e.response!.data as Map)['errors'] ??
            e.message)
        .toString()
    : e.toString();
