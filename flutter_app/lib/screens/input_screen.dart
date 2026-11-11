import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/enclosure.dart';
import '../services/calculation_state.dart';
import '../widgets/result_card.dart';

class InputScreen extends StatelessWidget {
  const InputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CalculationState>();
    final enc = state.enclosure;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader('Afmetingen'),
        _DimensionRow(
          label: 'Hoogte H',
          value: enc.heightMm,
          min: 100,
          max: 4000,
          onChanged: (v) => state.updateEnclosure((e) => e.heightMm = v),
        ),
        _DimensionRow(
          label: 'Breedte W',
          value: enc.widthMm,
          min: 100,
          max: 4000,
          onChanged: (v) => state.updateEnclosure((e) => e.widthMm = v),
        ),
        _DimensionRow(
          label: 'Diepte D',
          value: enc.depthMm,
          min: 50,
          max: 2000,
          onChanged: (v) => state.updateEnclosure((e) => e.depthMm = v),
        ),
        const SectionHeader('Installatietype'),
        DropdownButtonFormField<InstallationType>(
          initialValue: enc.installationType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: InstallationType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (t) {
            if (t != null) state.setInstallationType(t);
          },
        ),
        const SectionHeader('Oppervlakken'),
        _SurfaceToggle(
          label: 'Bovenzijde vrij',
          value: enc.topExposed,
          onChanged: (v) => state.updateEnclosure((e) => e.topExposed = v),
        ),
        _SurfaceToggle(
          label: 'Achterzijde vrij',
          value: enc.rearExposed,
          onChanged: (v) => state.updateEnclosure((e) => e.rearExposed = v),
        ),
        _SurfaceToggle(
          label: 'Linkerzijde vrij',
          value: enc.leftExposed,
          onChanged: (v) => state.updateEnclosure((e) => e.leftExposed = v),
        ),
        _SurfaceToggle(
          label: 'Rechterzijde vrij',
          value: enc.rightExposed,
          onChanged: (v) => state.updateEnclosure((e) => e.rightExposed = v),
        ),
        const SectionHeader('Ventilatie'),
        DropdownButtonFormField<VentilationType>(
          initialValue: enc.ventilationType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: VentilationType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (t) {
            if (t != null) state.updateEnclosure((e) => e.ventilationType = t);
          },
        ),
        if (enc.ventilationType != VentilationType.none) ...[
          const SizedBox(height: 12),
          _DimensionRow(
            label: 'Openingsoppervlak Aeff',
            unit: 'cm²',
            value: enc.ventilationAreaCm2,
            min: 0,
            max: 10000,
            onChanged: (v) =>
                state.updateEnclosure((e) => e.ventilationAreaCm2 = v),
          ),
        ],
        const SectionHeader('Horizontale schotten'),
        _StepperRow(
          label: 'Aantal schotten',
          value: enc.numPartitions,
          min: 0,
          max: 4,
          onChanged: (v) =>
              state.updateEnclosure((e) => e.numPartitions = v),
        ),
        const SectionHeader('Omgevingstemperatuur'),
        _DimensionRow(
          label: 'Ta',
          unit: '°C',
          value: enc.ambientTemperatureC,
          min: -25,
          max: 60,
          decimals: 1,
          onChanged: (v) =>
              state.updateEnclosure((e) => e.ambientTemperatureC = v),
        ),
        const SectionHeader('Zonnestraling (Annex C)'),
        DropdownButtonFormField<SolarRadiation>(
          initialValue: enc.solarRadiation,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: SolarRadiation.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (t) {
            if (t != null) state.updateEnclosure((e) => e.solarRadiation = t);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DimensionRow extends StatefulWidget {
  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final int decimals;
  final void Function(double) onChanged;

  const _DimensionRow({
    required this.label,
    this.unit = 'mm',
    required this.value,
    required this.min,
    required this.max,
    this.decimals = 0,
    required this.onChanged,
  });

  @override
  State<_DimensionRow> createState() => _DimensionRowState();
}

class _DimensionRowState extends State<_DimensionRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.decimals == 0
            ? widget.value.toInt().toString()
            : widget.value.toStringAsFixed(widget.decimals));
  }

  @override
  void didUpdateWidget(_DimensionRow old) {
    super.didUpdateWidget(old);
    final formatted = widget.decimals == 0
        ? widget.value.toInt().toString()
        : widget.value.toStringAsFixed(widget.decimals);
    if (_ctrl.text != formatted) _ctrl.text = formatted;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _ctrl,
              decoration: InputDecoration(
                labelText: '${widget.label} [${widget.unit}]',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
              onChanged: (s) {
                final v = double.tryParse(s);
                if (v != null && v >= widget.min && v <= widget.max) {
                  widget.onChanged(v);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            child: Slider(
              value: widget.value.clamp(widget.min, widget.max),
              min: widget.min,
              max: widget.max,
              onChanged: (v) {
                widget.onChanged(widget.decimals == 0 ? v.roundToDouble() : v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceToggle extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  const _SurfaceToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
        title: Text(label),
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        dense: true,
      );
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
