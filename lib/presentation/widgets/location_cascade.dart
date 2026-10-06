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
  // Rural branch under upazila. Mutually exclusive with pourashava below:
  // an outlet sits in a village area OR a town, never both.
  _Level('union', 'Union', 'Choose union', Icons.hub_outlined),
  // Urban branch under upazila (towns / municipalities).
  _Level('pourashava', 'Pourashava', 'Choose pourashava',
      Icons.location_city_rounded),
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
  // Urban counterpart of union: the caller owns both controllers and submits
  // whichever branch the officer filled (see _siblingType below).
  final TextEditingController pourashava;
  final TextEditingController ward;
  final TextEditingController village;

  const LocationCascadeField({
    super.key,
    required this.division,
    required this.district,
    required this.upazila,
    required this.union,
    required this.pourashava,
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
        'pourashava' => widget.pourashava,
        'ward' => widget.ward,
        'village' => widget.village,
        _ => widget.division,
      };

  /// The level that has to be picked before this one can be opened.
  ///
  /// Union and pourashava are alternatives hanging off the same upazila, and
  /// ward hangs off whichever of the two the officer picked.
  String? _parentType(String type) {
    if (type == 'pourashava') return 'upazila';
    if (type == 'ward') {
      if (_selectedId['union'] != null) return 'union';
      if (_selectedId['pourashava'] != null) return 'pourashava';
      return 'union';
    }
    final index = _levels.indexWhere((l) => l.type == type);
    return index <= 0 ? null : _levels[index - 1].type;
  }

  /// The mutually exclusive counterpart at the same depth, if any.
  /// Picking one branch clears and locks the other.
  static String? _siblingType(String type) => switch (type) {
        'union' => 'pourashava',
        'pourashava' => 'union',
        _ => null,
      };

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

    // Union <-> pourashava are alternatives: picking one clears and locks
    // the other (plus everything below, which described the old branch).
    final sibling = _siblingType(type);
    if (sibling != null) {
      setState(() => _selectedId[sibling] = null);
      _ctrlFor(sibling).clear();
    }

    // Everything below the changed level describes a place that is no longer
    // the one selected, so those values are dropped. Ward is below BOTH
    // union and pourashava, so it clears on either pick.
    final below = _descendantTypes(type);
    for (final deeper in below) {
      setState(() => _selectedId[deeper] = null);
      _ctrlFor(deeper).clear();
    }

    final childType = _childType(type);
    if (picked != null && childType != null) {
      await ref
          .read(locationChildrenProvider.notifier)
          .ensureLoaded(childType, picked.id);
    }
  }

  /// Levels that sit below [type] and must reset when it changes.
  /// Ward follows whichever branch (union or pourashava) is active.
  List<String> _descendantTypes(String type) {
    switch (type) {
      case 'division':
        return const ['district', 'upazila', 'union', 'pourashava', 'ward', 'village'];
      case 'district':
        return const ['upazila', 'union', 'pourashava', 'ward', 'village'];
      case 'upazila':
        return const ['union', 'pourashava', 'ward', 'village'];
      case 'union':
      case 'pourashava':
        return const ['ward', 'village'];
      case 'ward':
        return const ['village'];
      default:
        return const [];
    }
  }

  /// The level that opens next after [type] is picked.
  String? _childType(String type) => switch (type) {
        'division' => 'district',
        'district' => 'upazila',
        'upazila' => 'union',
        // After either branch the next step is ward (under that branch).
        'union' => 'ward',
        'pourashava' => 'ward',
        'ward' => 'village',
        _ => null,
      };

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

    // Union and pourashava exclude each other: once one branch has a value,
    // the other locks with an explanation instead of a second picker.
    final sibling = _siblingType(level.type);
    if (sibling != null &&
        (_selectedId[sibling] != null ||
            _ctrlFor(sibling).text.trim().isNotEmpty)) {
      return AppDropdownField<int>(
        label: trOf(context, level.type),
        hint: trOf(context, 'siblingLocked')
            .replaceAll('{sibling}', trOf(context, sibling)),
        icon: level.icon,
        enabled: false,
        searchable: false,
        options: const [],
        onChanged: (_) {},
      );
    }

    // Nothing deeper can be chosen until its parent exists. Ward's parent is
    // dynamic (union OR pourashava), so its label comes from _parentType.
    if (parentType != null && _selectedId[parentType] == null) {
      final parentLabel = trOf(context, parentType).toLowerCase();
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
        'union' => 'chooseUnion',
        'pourashava' => 'choosePourashava',
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
            subtitle: (row.nameBn != null && row.nameBn!.isNotEmpty)
                ? row.nameBn
                : null,
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
