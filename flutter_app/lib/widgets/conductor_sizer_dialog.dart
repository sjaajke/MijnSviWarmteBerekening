import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/conductor_library.dart';
import '../models/component.dart';

/// Installation condition labels + field selector
enum _InstallMethod {
  freeAir55C,
  freeAir1ph30C,
  freeAir3ph30C,
  touching1ph30C,
  touching3ph30C,
  trunking1ph30C,
  trunking3ph30C,
}

extension _InstallMethodExt on _InstallMethod {
  String get label => switch (this) {
        _InstallMethod.freeAir55C    => 'Vrij in lucht — Ta 55°C (IEC 61439)',
        _InstallMethod.freeAir1ph30C => 'Vrij in lucht — 1-fase, Ta 30°C',
        _InstallMethod.freeAir3ph30C => 'Vrij in lucht — 3-fase, Ta 30°C',
        _InstallMethod.touching1ph30C => 'Naast elkaar — 1-fase, Ta 30°C',
        _InstallMethod.touching3ph30C => 'Naast elkaar — 3-fase, Ta 30°C',
        _InstallMethod.trunking1ph30C => 'In kabelgoot — 1-fase, Ta 30°C',
        _InstallMethod.trunking3ph30C => 'In kabelgoot — 3-fase, Ta 30°C',
      };

  double? ith(ConductorEntry e) => switch (this) {
        _InstallMethod.freeAir55C    => e.ithFreeAir55C,
        _InstallMethod.freeAir1ph30C => e.ithFreeAir1ph30C,
        _InstallMethod.freeAir3ph30C => e.ithFreeAir3ph30C,
        _InstallMethod.touching1ph30C => e.ithTouching1ph30C,
        _InstallMethod.touching3ph30C => e.ithTouching3ph30C,
        _InstallMethod.trunking1ph30C => e.ithTrunking1ph30C,
        _InstallMethod.trunking3ph30C => e.ithTrunking3ph30C,
      };
}

Future<ComponentLoss?> showConductorSizer(BuildContext context) {
  return showModalBottomSheet<ComponentLoss>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _ConductorSizerSheet(),
  );
}

class _ConductorSizerSheet extends StatefulWidget {
  const _ConductorSizerSheet();

  @override
  State<_ConductorSizerSheet> createState() => _ConductorSizerSheetState();
}

class _ConductorSizerSheetState extends State<_ConductorSizerSheet> {
  _InstallMethod _method = _InstallMethod.freeAir55C;
  final _ingCtrl = TextEditingController();
  final _lenCtrl = TextEditingController(text: '1.0');

  // All unique categories in the library
  late final List<String> _categories;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _categories = ConductorLibrary.conductors
        .map((e) => e.category)
        .toSet()
        .toList();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _ingCtrl.dispose();
    _lenCtrl.dispose();
    super.dispose();
  }

  double? get _ing => double.tryParse(_ingCtrl.text);
  double get _length => double.tryParse(_lenCtrl.text) ?? 1.0;

  List<ConductorEntry> get _filtered => ConductorLibrary.conductors
      .where((e) => _selectedCategory == null || e.category == _selectedCategory)
      .toList();

  /// Minimum conductor that satisfies Ith ≥ Ing, or null if none
  ConductorEntry? get _recommended {
    final ing = _ing;
    if (ing == null || ing <= 0) return null;
    for (final e in _filtered) {
      final ith = _method.ith(e);
      if (ith != null && ith >= ing) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ing = _ing;
    final recommended = _recommended;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.cable, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Geleider bepalen',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Input section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Installatiemethode
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Installatiemethode',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<_InstallMethod>(
                      value: _method,
                      isExpanded: true,
                      isDense: true,
                      items: _InstallMethod.values
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m.label,
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _method = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Ontwerpstroom Ing
                    Expanded(
                      child: TextField(
                        controller: _ingCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ontwerpstroom Ing [A]',
                          isDense: true,
                          border: OutlineInputBorder(),
                          hintText: 'bijv. 16',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Kabellengte
                    Expanded(
                      child: TextField(
                        controller: _lenCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kabellengte [m]',
                          isDense: true,
                          border: OutlineInputBorder(),
                          hintText: 'voor Pv',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Categorie filter
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            isDense: true,
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c,
                                          style:
                                              const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCategory = v),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Aanbevolen geleider banner
          if (ing != null && ing > 0) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: recommended != null
                  ? _RecommendedBanner(
                      entry: recommended,
                      method: _method,
                      length: _length,
                      ing: ing,
                      onAdd: () => Navigator.pop(
                        context,
                        recommended.toComponent(ing, _length),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: colorScheme.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Geen geleider gevonden voor Ing = ${ing.toStringAsFixed(1)} A '
                              'met methode "${_method.label}".',
                              style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],

          const Divider(height: 1),

          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _Th('Geleider', flex: 3),
                _Th('Ith [A]', flex: 2),
                _Th('Pv [W]', flex: 2),
                _Th('', flex: 2),
              ],
            ),
          ),
          const Divider(height: 1),

          // Conductor rows
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final entry = _filtered[i];
                final ith = _method.ith(entry);
                final pv = ing != null
                    ? entry.powerLoss(ing, _length)
                    : null;
                final ok = ith != null && ing != null && ith >= ing;
                final isRecommended = entry == recommended;

                return _ConductorRow(
                  entry: entry,
                  ith: ith,
                  pv: pv,
                  ing: ing,
                  ok: ok,
                  isRecommended: isRecommended,
                  onAdd: () => Navigator.pop(
                    context,
                    entry.toComponent(ing ?? 0, _length),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recommended banner
// ---------------------------------------------------------------------------
class _RecommendedBanner extends StatelessWidget {
  final ConductorEntry entry;
  final _InstallMethod method;
  final double length;
  final double ing;
  final VoidCallback onAdd;

  const _RecommendedBanner({
    required this.entry,
    required this.method,
    required this.length,
    required this.ing,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ith = method.ith(entry);
    final pv = entry.powerLoss(ing, length);
    final margin = ith != null ? ith - ing : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aanbevolen: ${entry.code}  —  ${entry.crossSectionMm2.toStringAsFixed(0)} mm²',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Ith = ${ith?.toStringAsFixed(1)} A  ·  '
                  'Marge = ${margin?.toStringAsFixed(1)} A  ·  '
                  'Pv = ${pv.toStringAsFixed(3)} W  ·  '
                  'Tmax = ${entry.tmaxC}°C',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Toevoegen'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Table row
// ---------------------------------------------------------------------------
class _ConductorRow extends StatelessWidget {
  final ConductorEntry entry;
  final double? ith;
  final double? pv;
  final double? ing;
  final bool ok;
  final bool isRecommended;
  final VoidCallback onAdd;

  const _ConductorRow({
    required this.entry,
    required this.ith,
    required this.pv,
    required this.ing,
    required this.ok,
    required this.isRecommended,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isRecommended
        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
        : ok
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.25)
            : null;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Geleider naam + doorsnede
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.code,
                  style: TextStyle(
                    fontWeight: isRecommended
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${entry.crossSectionMm2.toStringAsFixed(entry.crossSectionMm2 < 10 ? 1 : 0)} mm²  ·  ${entry.tmaxC}°C',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Ith
          Expanded(
            flex: 2,
            child: Text(
              ith != null ? '${ith!.toStringAsFixed(1)} A' : '—',
              style: TextStyle(
                fontSize: 13,
                fontWeight: ok ? FontWeight.bold : FontWeight.normal,
                color: ok
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Pv
          Expanded(
            flex: 2,
            child: Text(
              pv != null ? '${pv!.toStringAsFixed(3)} W' : '—',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          // Toevoegen
          Expanded(
            flex: 2,
            child: ing != null
                ? (ok
                    ? OutlinedButton(
                        onPressed: onAdd,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Toevoegen'),
                      )
                    : Text(
                        'Te klein',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.error,
                        ),
                      ))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------
class _Th extends StatelessWidget {
  final String text;
  final int flex;
  const _Th(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}
