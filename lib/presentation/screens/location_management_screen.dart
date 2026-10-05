import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/theme/app_colors.dart';
import 'package:field_visit_app/core/widgets/app_dropdown.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/data/business_api.dart';
import 'package:field_visit_app/data/models/location.dart';
import 'package:field_visit_app/presentation/providers/business_api_provider.dart';

class _Level {
  final String type;
  final String label;
  final IconData icon;

  const _Level(this.type, this.label, this.icon);
}

const _levels = <_Level>[
  _Level('division', 'Division', Icons.public_rounded),
  _Level('district', 'District', Icons.map_rounded),
  _Level('upazila', 'Upazila', Icons.account_tree_rounded),
  _Level('union', 'Union', Icons.hub_outlined),
  _Level('ward', 'Ward', Icons.grid_view_rounded),
  _Level('village', 'Village', Icons.home_work_outlined),
];

/// Lets an administrator maintain the location tree from the device.
///
/// Villages have no open national dataset, so they are entered here by hand
/// under the ward they belong to. The same screen fills gaps anywhere else in
/// the chain too - a missing upazila or an extra ward both go through here.
class LocationManagementScreen extends ConsumerStatefulWidget {
  const LocationManagementScreen({super.key});

  @override
  ConsumerState<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState
    extends ConsumerState<LocationManagementScreen> {
  /// Id chosen at each level; null means nothing chosen there yet.
  final Map<String, int?> _selected = {
    for (final l in _levels) l.type: null,
  };

  final Map<String, List<Location>> _children = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  BusinessApi get _api => ref.read(businessApiProvider);

  /// The level whose children are listed, i.e. one past the deepest choice.
  int get _browseIndex {
    for (var i = 0; i < _levels.length; i++) {
      if (_selected[_levels[i].type] == null) return i;
    }
    return _levels.length - 1;
  }

  _Level get _browseLevel => _levels[_browseIndex];

  /// Parent under which a new [_browseLevel] row must be created.
  /// Null for division (top level), otherwise the id chosen one step above.
  int? get _parentId {
    if (_browseIndex == 0) return null;
    return _selected[_levels[_browseIndex - 1].type];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLevel());
  }

  Future<void> _loadLevel() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final divisions = await _api.locations(type: 'division');
      _children['division'] = divisions;

      // Preselect the first division so the screen is never blank on open.
      if (_selected['division'] == null && divisions.isNotEmpty) {
        _selected['division'] = divisions.first.id;
      }

      await _loadChildren();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadChildren({bool silent = false}) async {
    final index = _browseIndex;
    final level = _levels[index];
    final parentType = index == 0 ? null : _levels[index - 1].type;
    final parentId = parentType == null ? null : _selected[parentType];

    if (parentType != null && parentId == null) {
      if (mounted) {
        setState(() {
          _children[level.type] = const [];
          if (!silent) _loading = false;
        });
      } else {
        _children[level.type] = const [];
      }
      return;
    }

    final rows = await _api.locations(type: level.type, parentId: parentId);

    if (!mounted) {
      _children[level.type] = rows;
      return;
    }

    setState(() {
      _children[level.type] = rows;
      if (!silent) _loading = false;
    });
  }

  Future<void> _onPick(int index, Location picked) async {
    setState(() {
      _loading = true;
      _error = null;
      _selected[_levels[index].type] = picked.id;

      // Anything deeper now describes a different place.
      for (var i = index + 1; i < _levels.length; i++) {
        _selected[_levels[i].type] = null;
        _children[_levels[i].type] = const [];
      }
    });

    try {
      await _loadChildren();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
      return;
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      await _loadChildren();
    } catch (e) {
      // Keep the old contents; the next refresh retries.
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
      return;
    }
  }

  /// The chosen path, shown so it is obvious which ward is being edited.
  /// Falls back to "Division 3" style text when the cached list for a level
  /// was cleared, so the trail never flips to a raw "selected area".
  String get _path {
    final parts = <String>[];
    for (var i = 0; i < _browseIndex; i++) {
      final id = _selected[_levels[i].type];
      if (id == null) continue;
      final match = (_children[_levels[i].type] ?? const <Location>[])
          .where((r) => r.id == id);
      parts.add(match.isNotEmpty
          ? '${match.first.name} (${_levels[i].label})'
          : '${_levels[i].label} #$id');
    }
    return parts.isEmpty ? 'selected area' : parts.join('  >  ');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.cellfinGreen,
    ));
  }

  /// Pulls the readable message out of the API's error payload.
  String _friendly(Object error) {
    final text = error.toString();
    final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);

    if (match != null) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(match.group(0)!));
        final message = map['message'];
        if (message is String && message.isNotEmpty) return message;
      } catch (_) {
        // Not JSON; fall through to the raw text.
      }
    }

    return text.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final rows = _children[_browseLevel.type] ?? const <Location>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Master',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: (_browseIndex > 0 && _parentId == null) || _saving
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.cellfinGreen,
              foregroundColor: Colors.white,
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: Text('Add ${_browseLevel.label}'),
            ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFF7F9F8),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Text(
              _path == 'selected area' ? 'Select a location' : _path,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _errorView()
                    : rows.isEmpty
                        ? _emptyView()
                        : _list(rows),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 46, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Could not load locations',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              _friendly(_error ?? ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: _loadLevel, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    final needParent = _browseIndex > 0 && _parentId == null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              needParent
                  ? Icons.travel_explore_rounded
                  : Icons.location_off_rounded,
              size: 52,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 14),
            Text(
              needParent
                  ? 'Pick a ${_levels[_browseIndex - 1].label.toLowerCase()} above to continue'
                  : 'No ${_browseLevel.label.toLowerCase()} under this place yet',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              needParent
                  ? 'Every level has to be chosen in order.'
                  : 'Use the button below to add the first one.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<Location> rows) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: _levels.length + rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        // The first entries are the cascade pickers themselves.
        if (i < _levels.length) return _picker(_levels[i], i);

        final row = rows[i - _levels.length];

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.place_outlined,
                color: AppColors.cellfinGreen, size: 20),
            title: Text(row.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: row.nameBn != null && row.nameBn!.isNotEmpty
                ? Text(row.nameBn!,
                    style: const TextStyle(fontSize: 12.5, color: Colors.grey))
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  onPressed: () => _showEditSheet(context, row),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 19, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(row),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _picker(_Level level, int index) {
    final parentType = index == 0 ? null : _levels[index - 1].type;
    final parentChosen = parentType == null || _selected[parentType] != null;

    if (!parentChosen) {
      final parentLabel = _levels[index - 1].label.toLowerCase();
      return AppDropdownField<int>(
        label: level.label,
        hint: 'Choose $parentLabel first',
        icon: level.icon,
        enabled: false,
        searchable: false,
        options: const [],
        onChanged: (_) {},
      );
    }

    final cache = _children[level.type] ?? const <Location>[];

    return AppDropdownField<int>(
      label: level.label,
      hint: 'Choose ${level.label.toLowerCase()}',
      icon: level.icon,
      searchable: true,
      value: _selected[level.type],
      options: [
        for (final row in cache)
          AppDropdownOption<int>(
            value: row.id,
            title: row.name,
            subtitle: row.nameBn,
          ),
      ],
      onChanged: (id) {
        if (id == null) return;
        final match = cache.where((r) => r.id == id);
        if (match.isNotEmpty) _onPick(index, match.first);
      },
    );
  }

  /// Add sheet: one entry, or a pasted list when filling a whole ward.
  Future<void> _showAddSheet(BuildContext context) async {
    final level = _browseLevel;
    final parentId = _parentId;
    // Divisions sit at the top, so a null parent is only a dead end below them.
    if (_browseIndex > 0 && parentId == null) return;

    final name = TextEditingController();
    final nameBn = TextEditingController();
    final bulk = TextEditingController();

    var asBulk = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => StatefulBuilder(
        builder: (inner, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(inner).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: Theme.of(inner).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add ${level.label}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Under $_path',
                      style:
                          const TextStyle(fontSize: 12.5, color: Colors.grey)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('One'),
                          selected: !asBulk,
                          onSelected: (_) => setSheet(() => asBulk = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Paste list'),
                          selected: asBulk,
                          onSelected: (_) => setSheet(() => asBulk = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (asBulk) ...[
                    CellfinInputField(
                      controller: bulk,
                      hint: 'One name per line',
                      maxLines: 6,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Blank lines and names that already exist are skipped.',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey),
                    ),
                  ] else ...[
                    CellfinInputField(
                      controller: name,
                      hint: '${level.label} name (English) *',
                    ),
                    const SizedBox(height: 10),
                    CellfinInputField(
                      controller: nameBn,
                      hint: '${level.label} name (Bangla)',
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _saving ? null : () => Navigator.of(inner).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.cellfinGreen),
                          onPressed: _saving
                              ? null
                              : () async {
                                  final message = await _submitAdd(
                                    parentId: parentId,
                                    type: level.type,
                                    singleName: name.text,
                                    singleNameBn: nameBn.text,
                                    bulkText: bulk.text,
                                    asBulk: asBulk,
                                  );
                                  if (!context.mounted) return;
                                  if (message == null) {
                                    Navigator.of(inner).pop();
                                  } else {
                                    setSheet(() => error = message);
                                  }
                                },
                          child: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(asBulk ? 'Add all' : 'Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    name.dispose();
    nameBn.dispose();
    bulk.dispose();

    await _refresh();
  }

  /// Returns an error message, or null when everything saved.
  /// [parentId] is null for a top-level division.
  Future<String?> _submitAdd({
    required int? parentId,
    required String type,
    required String singleName,
    required String singleNameBn,
    required String bulkText,
    required bool asBulk,
  }) async {
    setState(() => _saving = true);

    try {
      if (asBulk) {
        final names = bulkText
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (names.isEmpty) return 'Enter at least one name.';

        final created = parentId == null
            ? 0
            : await _api.bulkCreateLocations(
                parentId: parentId, type: type, names: names);

        if (!mounted) return null;
        // The bulk endpoint needs a parent, so a pasted list of divisions
        // goes in one by one instead.
        if (parentId == null) {
          var added = 0;
          for (final n in names) {
            try {
              await _api.createLocation({'name': n, 'type': type});
              added++;
            } catch (_) {
              // One bad row (e.g. a duplicate name) skips; the rest continue.
            }
          }
          if (!mounted) return null;
          _toast(added == 0
              ? 'Nothing new - those all already exist'
              : 'Added $added $type(s)');
        } else {
          _toast(created == 0
              ? 'Nothing new - those all already exist'
              : 'Added $created $type(s)');
        }
      } else {
        if (singleName.trim().isEmpty) return 'Name is required.';

        await _api.createLocation({
          'name': singleName.trim(),
          if (singleNameBn.trim().isNotEmpty) 'name_bn': singleNameBn.trim(),
          'type': type,
          if (parentId != null) 'parent_id': parentId,
        });

        if (!mounted) return null;
        _toast('$type added');
      }

      return null;
    } catch (e) {
      return _friendly(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Renames an existing place, keeping its level and parent.
  Future<void> _showEditSheet(BuildContext context, Location row) async {
    final name = TextEditingController(text: row.name);
    final nameBn = TextEditingController(text: row.nameBn ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheet) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheet).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: Theme.of(sheet).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit ${row.type}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 14),
              CellfinInputField(
                  controller: name, hint: '${row.type} name (English) *'),
              const SizedBox(height: 10),
              CellfinInputField(
                  controller: nameBn, hint: '${row.type} name (Bangla)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(sheet).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.cellfinGreen),
                      onPressed: _saving
                          ? null
                          : () async {
                              final trimmed = name.text.trim();
                              if (trimmed.isEmpty) return;
                              setState(() => _saving = true);
                              try {
                                await _api.updateLocation(row.id, {
                                  'name': trimmed,
                                  'name_bn': nameBn.text.trim().isEmpty
                                      ? null
                                      : nameBn.text.trim(),
                                  'type': row.type,
                                });
                                if (!sheet.mounted) return;
                                Navigator.of(sheet).pop();
                                _toast('Updated');
                              } catch (e) {
                                if (!sheet.mounted) return;
                                ScaffoldMessenger.of(sheet).showSnackBar(
                                    SnackBar(content: Text(_friendly(e))));
                              } finally {
                                if (mounted) {
                                  setState(() => _saving = false);
                                }
                              }
                            },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    name.dispose();
    nameBn.dispose();

    await _refresh();
  }

  /// The server refuses to delete a place that still has children; this asks
  /// first so the user is not left wondering why nothing happened.
  Future<void> _confirmDelete(Location row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('Delete ${row.name}?'),
        content: Text(
          'This ${row.type} will be removed. If it still has places under it, '
          'the server will refuse and ask you to clear them first.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);

    try {
      await _api.deleteLocation(row.id);
      if (mounted) _toast('Deleted');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_friendly(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
      await _refresh();
    }
  }
}
