import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../services/calculation_state.dart';
import '../data/user_library.dart';
import '../widgets/device_library_dialog.dart';
import '../widgets/conductor_sizer_dialog.dart';

class ComponentsScreen extends StatelessWidget {
  const ComponentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CalculationState>();
    final components = state.components;
    final theme = Theme.of(context);

    final pNominal = state.totalPowerNominal;
    final pEffective = state.totalPower;
    final rdf = state.overallSimultaneityFactor;
    final hasSimultaneity = (pNominal - pEffective).abs() > 0.01;

    return Column(
      children: [
        // ── Action buttons ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addFromLibrary(context, state),
                  icon: const Icon(Icons.library_books, size: 16),
                  label: const Text('Bibliotheek',
                      overflow: TextOverflow.ellipsis),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sizeConductor(context, state),
                  icon: const Icon(Icons.cable, size: 16),
                  label: const Text('Geleider',
                      overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addComponent(context, state),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Handmatig',
                      overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Power summary bar ──────────────────────────────────────────────
        Container(
          width: double.infinity,
          color: theme.colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.bolt, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Effective power (main)
                    Text(
                      'P effectief = ${pEffective.toStringAsFixed(2)} W',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasSimultaneity) ...[
                      const SizedBox(height: 2),
                      Text(
                        'P nominaal = ${pNominal.toStringAsFixed(2)} W  ·  '
                        'RDF = ${(rdf * 100).toStringAsFixed(1)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha:0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // RDF badge
              if (hasSimultaneity)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'RDF ${(rdf * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Component list ──────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: components.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ComponentTile(
              component: components[i],
              index: i,
              state: state,
            ),
          ),
        ),
      ],
    );
  }

  void _addComponent(BuildContext context, CalculationState state) {
    state.addComponent(
        ComponentLoss(description: 'Nieuw component', powerLossW: 0));
  }

  Future<void> _addFromLibrary(
      BuildContext context, CalculationState state) async {
    final comp = await showDeviceLibrary(context);
    if (comp != null) state.addComponent(comp);
  }

  Future<void> _sizeConductor(
      BuildContext context, CalculationState state) async {
    final comp = await showConductorSizer(context);
    if (comp != null) state.addComponent(comp);
  }
}

// ---------------------------------------------------------------------------
// Component tile with simultaneity slider
// ---------------------------------------------------------------------------
class _ComponentTile extends StatefulWidget {
  final ComponentLoss component;
  final int index;
  final CalculationState state;

  const _ComponentTile({
    required this.component,
    required this.index,
    required this.state,
  });

  @override
  State<_ComponentTile> createState() => _ComponentTileState();
}

class _ComponentTileState extends State<_ComponentTile> {
  late TextEditingController _descCtrl;
  late TextEditingController _pvCtrl;
  late TextEditingController _tmaxCtrl;
  late TextEditingController _inCtrl;
  late TextEditingController _ingCtrl;
  late int _count;
  late double _rdf; // local copy for slider

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.component.description);
    _pvCtrl = TextEditingController(
        text: widget.component.powerLossW.toStringAsFixed(2));
    _tmaxCtrl = TextEditingController(
        text: widget.component.maxTemperatureC?.toStringAsFixed(0) ?? '');
    _inCtrl = TextEditingController(
        text: widget.component.nominalCurrentA?.toStringAsFixed(1) ?? '');
    _ingCtrl = TextEditingController(
        text: widget.component.designCurrentA?.toStringAsFixed(1) ?? '');
    _count = widget.component.count;
    _rdf = widget.component.simultaneityFactor;
  }

  @override
  void didUpdateWidget(_ComponentTile old) {
    super.didUpdateWidget(old);
    if (old.component.simultaneityFactor != widget.component.simultaneityFactor) {
      _rdf = widget.component.simultaneityFactor;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _pvCtrl.dispose();
    _tmaxCtrl.dispose();
    _inCtrl.dispose();
    _ingCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.state.updateComponent(
      widget.index,
      ComponentLoss(
        description: _descCtrl.text,
        count: _count,
        powerLossW: double.tryParse(_pvCtrl.text) ?? 0,
        nominalCurrentA: double.tryParse(_inCtrl.text),
        designCurrentA: double.tryParse(_ingCtrl.text),
        maxTemperatureC: double.tryParse(_tmaxCtrl.text),
        simultaneityFactor: _rdf,
        crossSectionMm2: widget.component.crossSectionMm2,
        ithMaxA: widget.component.ithMaxA,
      ),
    );
  }

  Future<void> _saveToLibrary(BuildContext context) async {
    final service = context.read<UserLibraryService>();
    final catCtrl = TextEditingController(text: 'Eigen');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bewaar in bibliotheek'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _descCtrl.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Pv = ${_pvCtrl.text} W'
                '${_inCtrl.text.isNotEmpty ? '  ·  In = ${_inCtrl.text} A' : ''}'),
            const SizedBox(height: 12),
            TextField(
              controller: catCtrl,
              decoration: const InputDecoration(
                labelText: 'Categorie',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              final pv = double.tryParse(_pvCtrl.text);
              if (pv == null) return;
              service.add(UserLibraryEntry(
                category: catCtrl.text.trim().isEmpty
                    ? 'Eigen'
                    : catCtrl.text.trim(),
                description: _descCtrl.text,
                powerLossW: pv,
                nominalCurrentA: double.tryParse(_inCtrl.text),
                maxTemperatureC: double.tryParse(_tmaxCtrl.text),
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opgeslagen in eigen bibliotheek'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Opslaan'),
          ),
        ],
      ),
    );
    catCtrl.dispose();
  }

  String _buildEffectiveLabel(
      double pvNominal, double loadingFactor, double pvEffective) {
    final parts = <String>[];
    if (loadingFactor < 0.9999) {
      parts.add('(Ing/In)²=${loadingFactor.toStringAsFixed(2)}');
    }
    if (_count > 1) parts.add('×$_count st.');
    if (_rdf < 1.0) parts.add('RDF=${(_rdf * 100).toStringAsFixed(0)}%');
    final suffix = parts.isEmpty ? '' : '  [${parts.join(', ')}]';
    return 'Pv effectief = ${pvEffective.toStringAsFixed(2)} W$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pv = double.tryParse(_pvCtrl.text) ?? widget.component.powerLossW;
    final inn = double.tryParse(_inCtrl.text);
    final ing = double.tryParse(_ingCtrl.text);
    final loadingFactor = (inn != null && ing != null && inn > 0)
        ? (ing / inn) * (ing / inn)
        : 1.0;
    final pvEffective = pv * loadingFactor * _count * _rdf;
    final showRdf = _rdf < 1.0;
    final showLoading = loadingFactor < 0.9999;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: showRdf
              ? theme.colorScheme.primary.withValues(alpha:0.4)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Description
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Omschrijving',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _save(),
                  ),

                  // Conductor info row (only shown for conductors)
                  if (widget.component.crossSectionMm2 != null) ...[
                    const SizedBox(height: 6),
                    _ConductorInfoRow(component: widget.component),
                  ],
                  const SizedBox(height: 8),

                  // Row 2: Aantal + In + Ing
                  Row(
                    children: [
                      // Aantal stepper
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Aantal',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(width: 4),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: _count > 1
                                ? () {
                                    setState(() => _count--);
                                    _save();
                                  }
                                : null,
                          ),
                          SizedBox(
                            width: 28,
                            child: Text(
                              '$_count',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () {
                              setState(() => _count++);
                              _save();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _inCtrl,
                          decoration: const InputDecoration(
                            labelText: 'In [A]',
                            isDense: true,
                            border: OutlineInputBorder(),
                            hintText: 'opt.',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          onChanged: (_) {
                            setState(() {});
                            _save();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _ingCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Ing [A]',
                            isDense: true,
                            border: OutlineInputBorder(),
                            hintText: 'opt.',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          onChanged: (_) {
                            setState(() {});
                            _save();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Row 3: Pv + Tmax
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pvCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Pv nominaal [W]',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          onChanged: (_) {
                            setState(() {});
                            _save();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _tmaxCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Tmax [°C]',
                            isDense: true,
                            border: OutlineInputBorder(),
                            hintText: 'optioneel',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          onChanged: (_) => _save(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Row 4: Simultaneity slider
                  Row(
                    children: [
                      Text(
                        'Gelijktijdigheid',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      Expanded(
                        child: Slider(
                          value: _rdf,
                          min: 0.1,
                          max: 1.0,
                          divisions: 18, // steps of 5%
                          onChanged: (v) {
                            setState(() => _rdf = v);
                            _save();
                          },
                        ),
                      ),
                      // RDF % badge
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${(_rdf * 100).toStringAsFixed(0)}%',
                          textAlign: TextAlign.right,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: showRdf
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Effective Pv summary
                  if (showRdf || showLoading || _count > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 2),
                      child: Text(
                        _buildEffectiveLabel(pv, loadingFactor, pvEffective),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons column (save + delete)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  color: theme.colorScheme.primary,
                  tooltip: 'Bewaar in bibliotheek',
                  onPressed: () => _saveToLibrary(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: theme.colorScheme.error,
                  onPressed: () => widget.state.removeComponent(widget.index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Read-only conductor metadata strip (doorsnede, Ith max, Pv, Ing)
// ---------------------------------------------------------------------------
class _ConductorInfoRow extends StatelessWidget {
  final ComponentLoss component;
  const _ConductorInfoRow({required this.component});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = theme.colorScheme.secondaryContainer;
    final textColor = theme.colorScheme.onSecondaryContainer;

    Widget chip(String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
        );

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        chip('${component.crossSectionMm2} mm²'),
        if (component.ithMaxA != null)
          chip('Ith ${component.ithMaxA!.toInt()} A'),
        chip('Pv ${component.powerLossW.toStringAsFixed(3)} W'),
        if (component.designCurrentA != null)
          chip('Ing ${component.designCurrentA!.toStringAsFixed(1)} A'),
      ],
    );
  }
}
