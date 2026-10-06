import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_visit_app/core/widgets/app_dropdown.dart';
import 'package:field_visit_app/core/widgets/cellfin_form_modal.dart';
import 'package:field_visit_app/data/models/location.dart';
import 'package:field_visit_app/presentation/providers/location_provider.dart';
import 'package:field_visit_app/core/l10n/locale_provider.dart';

class _Level {
  final String type;
  final String label;
  final String hint;
  final IconData icon;

  const _Level(this.type, this.label, this.hint, this.icon);
}

const _levels = <_Level>[
  _Level('division', 'Division', 'Choose division', Icons.public_rounded),
  _Level('district', 'District', 'Choose district', Icons.map_rounded),
  _Level('upazila', 'Upazila', 'Choose upazila', Icons.account_tree_rounded),
  _Level('union', 'Union', 'Union / Pourashava', Icons.hub_outlined),
  _Level('ward', 'Ward', 'Ward number', Icons.grid_view_rounded),
  _Level(
      'village', 'Village / Para', 'Village or para', Icons.home_work_outlined),
];

/// Cascading picker for division -> district -> upazila -> union -> ward ->
/// village.
///
/// Division, district and upazila come from seeded reference data and are
/// chosen from a searchable list. Union, ward and village are not published in
/// that dataset, so those stay typable; once they are added server side they
/// switch to pickers on their own.
///
/// Each choice is written into the controllers the caller owns, so the
/// existing submit handler and its payload are unchanged. Nothing here writes
/// to a provider during build, which Riverpod forbids.
class LocationCascadeField extends ConsumerStatefulWidget {
  final TextEditingController division;
  final TextEditingController district;
  final TextEditingController upazila;
  final TextEditingController union;
  final TextEditingController ward;
  final TextEditingController village;

  const LocationCascadeField({
    super.key,
    required this.division,
    required this.district,
    required this.upazila,
    required this.union,
    required this.ward,
    required this.village,
  });

  @override
  ConsumerState<LocationCascadeField> createState() =>
      _LocationCascadeFieldState();
}

class _LocationCascadeFieldState extends ConsumerState<LocationCascadeField> {
  /// Row id picked at each level; null means nothing chosen there yet.
  final Map<String, int?> _selectedId = {
    for (final l in _levels) l.type: null,
  };

  TextEditingController _ctrlFor(String type) => switch (type) {
        'division' => widget.division,
        'district' => widget.district,
        'upazila' => widget.upazila,
        'union' => widget.union,
        'ward' => widget.ward,
        'village' => widget.village,
        _ => widget.division,
      };

  /// The level that has to be picked before this one can be opened.
  String? _parentType(String type) {
    final index = _levels.indexWhere((l) => l.type == type);
    return index <= 0 ? null : _levels[index - 1].type;
  }

  /// Cached children of the currently selected parent for this level.
  List<Location> _rowsFor(String levelType) {
    final cache = ref.watch(locationChildrenProvider).valueOrNull ?? const {};
    return cache[LocationChildrenNotifier.keyFor(
          levelType,
          _selectedId[_parentType(levelType)],
        )] ??
        const <Location>[];
  }

  @override
  void initState() {
    super.initState();
    // The reference data arrives after the first frame, so pre-selecting an
    // existing outlet has to wait for it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreExisting());
  }

  /// Ticks the dropdowns matching values already stored on the outlet.
  Future<void> _restoreExisting() async {
    if (ref.read(locationChildrenProvider).valueOrNull == null) return;

    await _preSelect('division', widget.division.text);
    await _preSelect('district', widget.district.text);
    await _preSelect('upazila', widget.upazila.text);

    if (mounted) setState(() {});
  }

  Future<void> _preSelect(String type, String current) async {
    final trimmed = current.trim();
    if (trimmed.isEmpty) return;

    final rows = _rowsFor(type);
    final match =
        rows.where((r) => r.name.toLowerCase() == trimmed.toLowerCase());

    if (match.isNotEmpty) {
      setState(() => _selectedId[type] = match.first.id);
    }
  }

  Future<void> _onPick(int index, Location? picked) async {
    final type = _levels[index].type;

    setState(() => _selectedId[type] = picked?.id);
    _ctrlFor(type).text = picked?.name ?? '';

    // Everything below the changed level describes a place that is no longer
    // the one selected, so those values are dropped.
    for (var i = index + 1; i < _levels.length; i++) {
      final deeper = _levels[i].type;
      setState(() => _selectedId[deeper] = null);
      _ctrlFor(deeper).clear();
    }

    if (picked != null && index + 1 < _levels.length) {
      await ref
          .read(locationChildrenProvider.notifier)
          .ensureLoaded(_levels[index + 1].type, picked.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _levels.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildLevel(_levels[i], i),
        ],
      ],
    );
  }

  Widget _buildLevel(_Level level, int index) {
    final parentType = _parentType(level.type);

    // Nothing deeper can be chosen until its parent exists.
    if (parentType != null && _selectedId[parentType] == null) {
      final parentLabel = trOf(context, _levels[index - 1].type).toLowerCase();
      return AppDropdownField<int>(
        label: trOf(context, level.type),
        hint: trOf(context, 'chooseParentFirst')
            .replaceAll('{parent}', parentLabel),
        icon: level.icon,
        enabled: false,
        searchable: false,
        options: const [],
        onChanged: (_) {},
      );
    }

    final rows = _rowsFor(level.type);

    // No reference data at this depth yet. Staying typable keeps the field
    // usable instead of presenting a picker with nothing in it.
    if (rows.isEmpty) {
      return CellfinInputField(
        controller: _ctrlFor(level.type),
        hint: trOf(context, 'typeManually')
            .replaceAll('{level}', trOf(context, level.type)),
        prefixIcon: Icon(level.icon, color: const Color(0xFF6B7280)),
      );
    }

    return AppDropdownField<int>(
      label: trOf(context, level.type),
      hint: trOf(context, switch (level.type) {
        'division' => 'chooseDivision',
        'district' => 'chooseDistrict',
        'upazila' => 'chooseUpazila',
        'union' => 'unionPourashava',
        'ward' => 'wardNumber',
        _ => 'villageOrPara',
      }),
      icon: level.icon,
      value: _selectedId[level.type],
      options: [
        for (final row in rows)
          AppDropdownOption<int>(
            value: row.id,
            title: row.name,
            // Reference data is bilingual; the Bangla name helps an officer
            // who reads it faster than the transliterated one.
            subtitle: row.nameBn,
          ),
      ],
      onChanged: (id) {
        if (id == null) return;
        final match = rows.where((r) => r.id == id);
        _onPick(index, match.isEmpty ? null : match.first);
      },
    );
  }
}
