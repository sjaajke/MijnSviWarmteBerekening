import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/device_library.dart';
import '../data/conductor_library.dart';
import '../data/user_library.dart';
import '../models/component.dart';

/// Shows a searchable library sheet with tabs for Devices and Conductors.
/// Returns the selected [ComponentLoss], or null if cancelled.
Future<ComponentLoss?> showDeviceLibrary(BuildContext context) {
  return showModalBottomSheet<ComponentLoss>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const DeviceLibrarySheet(),
  );
}

class DeviceLibrarySheet extends StatefulWidget {
  const DeviceLibrarySheet({super.key});

  @override
  State<DeviceLibrarySheet> createState() => _DeviceLibrarySheetState();
}

class _DeviceLibrarySheetState extends State<DeviceLibrarySheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text('Componentenbibliotheek',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabCtrl,
            tabs: const [
              Tab(icon: Icon(Icons.electrical_services), text: 'Apparaten'),
              Tab(icon: Icon(Icons.cable), text: 'Geleiders'),
              Tab(icon: Icon(Icons.bookmark), text: 'Eigen'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _DevicesTab(scrollController: scrollController),
                _ConductorsTab(scrollController: scrollController),
                _UserTab(scrollController: scrollController),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Devices tab
// ---------------------------------------------------------------------------
class _DevicesTab extends StatefulWidget {
  final ScrollController scrollController;
  const _DevicesTab({required this.scrollController});

  @override
  State<_DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends State<_DevicesTab>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();
  String? _selectedCategory;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DeviceLibraryEntry> get _filtered {
    if (_query.length >= 2) return DeviceLibrary.search(_query);
    if (_selectedCategory != null) {
      return DeviceLibrary.byCategory(_selectedCategory!);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final categories = DeviceLibrary.categories;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Zoek op type of artikelnummer…',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        // Category chips
        if (_query.isEmpty)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final selected = _selectedCategory == cat;
                return FilterChip(
                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _selectedCategory = selected ? null : cat;
                  }),
                );
              },
            ),
          ),
        const SizedBox(height: 4),
        // Results
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    _query.length >= 2
                        ? 'Geen resultaten voor "$_query"'
                        : 'Selecteer een categorie of zoek op typenummer',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final entry = _filtered[i];
                    return _DeviceTile(
                      entry: entry,
                      onTap: () =>
                          Navigator.pop(context, entry.toComponent()),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final DeviceLibraryEntry entry;
  final VoidCallback onTap;
  const _DeviceTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      title: Text(entry.typeDescription,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        [
          entry.articleCode,
          if (entry.nominalCurrentA != null)
            '${entry.nominalCurrentA!.toInt()} A',
          if (entry.poles != null) '${entry.poles}P',
        ].join(' · '),
        style:
            TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${entry.pvDeviceW} W',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 13)),
          if (entry.tmaxC != null)
            Text('Tmax ${entry.tmaxC!.toInt()}°C',
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conductors tab
// ---------------------------------------------------------------------------
class _ConductorsTab extends StatefulWidget {
  final ScrollController scrollController;
  const _ConductorsTab({required this.scrollController});

  @override
  State<_ConductorsTab> createState() => _ConductorsTabState();
}

class _ConductorsTabState extends State<_ConductorsTab>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();
  String? _selectedCategory;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ConductorEntry> get _filtered {
    if (_query.isNotEmpty) return ConductorLibrary.search(_query);
    if (_selectedCategory != null) {
      return ConductorLibrary.byCategory(_selectedCategory!);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final categories = ConductorLibrary.categories;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Zoek op code bijv. "2.5CW70"…',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        // Category chips
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = categories[i];
              final selected = _selectedCategory == cat;
              return FilterChip(
                label: Text(cat, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (_) => setState(() {
                  _selectedCategory = selected ? null : cat;
                  if (!selected) _searchCtrl.clear();
                  _query = '';
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        // Results
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(
                    'Selecteer een categorie of zoek op code',
                    style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final entry = _filtered[i];
                    return _ConductorTile(entry: entry);
                  },
                ),
        ),
      ],
    );
  }
}

class _ConductorTile extends StatelessWidget {
  final ConductorEntry entry;
  const _ConductorTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(entry.code,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        [
          '${entry.crossSectionMm2} mm²',
          'Tmax ${entry.tmaxC}°C',
          if (entry.ithFreeAir1ph30C != null)
            'Ith vrij ${entry.ithFreeAir1ph30C!.toInt()} A',
        ].join(' · '),
        style:
            TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Icon(Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant),
      onTap: () => _showConductorDialog(context, entry),
    );
  }

  Future<void> _showConductorDialog(
      BuildContext context, ConductorEntry entry) async {
    final comp = await showDialog<ComponentLoss>(
      context: context,
      builder: (_) => _ConductorInputDialog(entry: entry),
    );
    if (comp != null && context.mounted) {
      Navigator.pop(context, comp);
    }
  }
}

// ---------------------------------------------------------------------------
// Dialog to enter current and length for a conductor
// ---------------------------------------------------------------------------
class _ConductorInputDialog extends StatefulWidget {
  final ConductorEntry entry;
  const _ConductorInputDialog({required this.entry});

  @override
  State<_ConductorInputDialog> createState() => _ConductorInputDialogState();
}

class _ConductorInputDialogState extends State<_ConductorInputDialog> {
  final _currentCtrl = TextEditingController(text: '16');
  final _lengthCtrl = TextEditingController(text: '1.0');

  double get _current => double.tryParse(_currentCtrl.text) ?? 0;
  double get _length => double.tryParse(_lengthCtrl.text) ?? 0;
  double get _pv => widget.entry.powerLoss(_current, _length);

  @override
  void dispose() {
    _currentCtrl.dispose();
    _lengthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;

    // Build current capacity table rows
    final ithRows = <(String, String)>[
      if (entry.ithFreeAir55C != null)
        ('Vrije lucht @55°C', '${entry.ithFreeAir55C!.toInt()} A'),
      if (entry.ithFreeAir1ph30C != null)
        ('Vrije lucht 1-fase @30°C', '${entry.ithFreeAir1ph30C!.toInt()} A'),
      if (entry.ithFreeAir3ph30C != null)
        ('Vrije lucht 3-fase @30°C', '${entry.ithFreeAir3ph30C!.toInt()} A'),
      if (entry.ithTouching1ph30C != null)
        ('Aanliggend 1-fase @30°C', '${entry.ithTouching1ph30C!.toInt()} A'),
      if (entry.ithTouching3ph30C != null)
        ('Aanliggend 3-fase @30°C', '${entry.ithTouching3ph30C!.toInt()} A'),
      if (entry.ithTrunking1ph30C != null)
        ('Kabelgoot 1-fase @30°C', '${entry.ithTrunking1ph30C!.toInt()} A'),
      if (entry.ithTrunking3ph30C != null)
        ('Kabelgoot 3-fase @30°C', '${entry.ithTrunking3ph30C!.toInt()} A'),
    ];

    return AlertDialog(
      title: Text(entry.code),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Properties
            Text('${entry.crossSectionMm2} mm²  ·  Tmax ${entry.tmaxC}°C  ·  '
                'R = ${(entry.resistancePerMeter * 1000).toStringAsFixed(2)} mΩ/m',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),

            // Current capacity table
            if (ithRows.isNotEmpty) ...[
              Text('Stroombelastbaarheid (IEC 61439)',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...ithRows.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(r.$1,
                            style: theme.textTheme.bodySmall),
                        Text(r.$2,
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
              const Divider(height: 20),
            ],

            // Input fields
            Text('Vermogensverlies berekenen',
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _currentCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Stroom I [A]',
                      border: OutlineInputBorder(),
                      isDense: true,
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
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lengthCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lengte L [m]',
                      border: OutlineInputBorder(),
                      isDense: true,
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
              ],
            ),
            const SizedBox(height: 12),
            // Formula display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pv = I² × R × L = '
                    '${_current.toStringAsFixed(1)}² × '
                    '${(entry.resistancePerMeter * 1000).toStringAsFixed(2)} mΩ/m × '
                    '${_length.toStringAsFixed(1)} m',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pv = ${_pv.toStringAsFixed(3)} W',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuleren'),
        ),
        FilledButton(
          onPressed: _pv > 0
              ? () => Navigator.pop(
                    context,
                    entry.toComponent(_current, _length),
                  )
              : null,
          child: const Text('Toevoegen'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// User (eigen) library tab
// ---------------------------------------------------------------------------
class _UserTab extends StatefulWidget {
  final ScrollController scrollController;
  const _UserTab({required this.scrollController});

  @override
  State<_UserTab> createState() => _UserTabState();
}

class _UserTabState extends State<_UserTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final service = context.watch<UserLibraryService>();
    final entries = service.entries;

    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Eigen bibliotheek',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nieuw'),
                onPressed: () => _showAddDialog(context, service),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // List or empty state
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_border,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text(
                        'Nog geen eigen componenten.\nVoeg ze toe via de knop hierboven\nof via de componentenlijst.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final entry = entries[i];
                    return ListTile(
                      title: Text(entry.description,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        [
                          entry.category,
                          if (entry.nominalCurrentA != null)
                            '${entry.nominalCurrentA!.toStringAsFixed(0)} A',
                        ].join(' · '),
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${entry.powerLossW} W',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  fontSize: 13)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: theme.colorScheme.error,
                            visualDensity: VisualDensity.compact,
                            onPressed: () => service.remove(i),
                          ),
                        ],
                      ),
                      onTap: () =>
                          Navigator.pop(context, entry.toComponent()),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showAddDialog(
      BuildContext context, UserLibraryService service) async {
    final descCtrl = TextEditingController();
    final pvCtrl = TextEditingController();
    final inCtrl = TextEditingController();
    final tmaxCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Eigen');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nieuw eigen component'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Omschrijving',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(
                  labelText: 'Categorie',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pvCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pv nominaal [W]',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: inCtrl,
                decoration: const InputDecoration(
                  labelText: 'In [A] (optioneel)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tmaxCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tmax [°C] (optioneel)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              final pv = double.tryParse(pvCtrl.text);
              final desc = descCtrl.text.trim();
              if (desc.isEmpty || pv == null) return;
              service.add(UserLibraryEntry(
                category: catCtrl.text.trim().isEmpty
                    ? 'Eigen'
                    : catCtrl.text.trim(),
                description: desc,
                powerLossW: pv,
                nominalCurrentA: double.tryParse(inCtrl.text),
                maxTemperatureC: double.tryParse(tmaxCtrl.text),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );

    descCtrl.dispose();
    pvCtrl.dispose();
    inCtrl.dispose();
    tmaxCtrl.dispose();
    catCtrl.dispose();
  }
}
