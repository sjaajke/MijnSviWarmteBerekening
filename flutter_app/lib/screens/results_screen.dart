import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/calculation_state.dart';
import '../services/report_service.dart';
import '../widgets/result_card.dart';
import '../widgets/temperature_chart.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CalculationState>();
    final result = state.result;
    if (result == null) return const Center(child: CircularProgressIndicator());

    final enc = state.enclosure;
    final isWide = MediaQuery.of(context).size.width > 700;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Project opslaan / laden ──────────────────────────────────────────
        const SectionHeader('Project'),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _saveProject(context, state),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Opslaan'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _loadProject(context, state),
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Laden'),
              ),
            ),
          ],
        ),

        // ── Rekenfactoren ────────────────────────────────────────────────────
        const SectionHeader('Rekenfactoren'),
        _GridRow(children: [
          ResultCard(label: 'Ae', value: result.ae.toStringAsFixed(4), unit: 'm²'),
          ResultCard(label: 'Ab', value: result.ab.toStringAsFixed(4), unit: 'm²'),
          ResultCard(label: 'k', value: result.k.toStringAsFixed(5)),
        ]),
        const SizedBox(height: 8),
        _GridRow(children: [
          ResultCard(label: 'f', value: result.f.toStringAsFixed(4)),
          ResultCard(label: 'c', value: result.c.toStringAsFixed(5)),
          ResultCard(label: 'x / d', value: '${result.x} / ${result.d}'),
        ]),

        // ── Temperatuurstijgingen ────────────────────────────────────────────
        const SectionHeader('Temperatuurstijgingen'),
        _GridRow(children: [
          ResultCard(
            label: 'Δt₀.₅ (halve hoogte)',
            value: result.deltaT05.toStringAsFixed(2),
            unit: 'K',
            valueColor: Colors.orange.shade700,
          ),
          ResultCard(
            label: 'Δt₀.₇₅',
            value: result.deltaT075.toStringAsFixed(2),
            unit: 'K',
            valueColor: Colors.orange.shade800,
          ),
          ResultCard(
            label: 'Δt₁.₀ (top)',
            value: result.deltaT10.toStringAsFixed(2),
            unit: 'K',
            valueColor: Colors.red.shade700,
          ),
        ]),
        const SizedBox(height: 8),
        _GridRow(children: [
          ResultCard(
            label: 'Tint (midden)',
            value: result.tIntMid.toStringAsFixed(2),
            unit: '°C',
          ),
          ResultCard(
            label: 'Tint (top)',
            value: result.tIntTop.toStringAsFixed(2),
            unit: '°C',
            valueColor: Colors.red.shade700,
          ),
          if (result.deltaTSolar > 0)
            ResultCard(
              label: 'Zonnestraling',
              value: '+${result.deltaTSolar.toStringAsFixed(0)}',
              unit: 'K',
            ),
        ]),

        // ── Temperatuurprofiel ───────────────────────────────────────────────
        const SectionHeader('Temperatuurprofiel'),
        SizedBox(
          height: isWide ? 350 : 260,
          child: TemperatureChart(
            result: result,
            heightMm: enc.heightMm,
          ),
        ),

        // ── Vermogensverdeling ───────────────────────────────────────────────
        const SectionHeader('Vermogensverdeling'),
        _PowerBreakdownTable(state: state),

        // ── Componentverificatie ─────────────────────────────────────────────
        const SectionHeader('Componentverificatie (Tmax)'),
        _VerificationTable(state: state),

        // ── Export ───────────────────────────────────────────────────────────
        const SectionHeader('Export'),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => ReportService.exportJson(context, state),
                icon: const Icon(Icons.download),
                label: const Text('JSON'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => ReportService.exportPdf(context, state),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _saveProject(
      BuildContext context, CalculationState state) async {
    await state.saveProject();
  }

  Future<void> _loadProject(
      BuildContext context, CalculationState state) async {
    final error = await state.loadProject();
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project geladen')),
      );
    }
  }
}

// ── Vermogensverdeling tabel ─────────────────────────────────────────────────
class _PowerBreakdownTable extends StatelessWidget {
  final CalculationState state;
  const _PowerBreakdownTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = state.result!;
    final totalEff = state.totalPower;

    return Column(
      children: [
        // Samenvattingsbalk
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _PowerStat(
                  label: 'P nominaal',
                  value: '${state.totalPowerNominal.toStringAsFixed(2)} W',
                  theme: theme,
                ),
              ),
              Expanded(
                child: _PowerStat(
                  label: 'P effectief',
                  value: '${state.totalPower.toStringAsFixed(2)} W',
                  theme: theme,
                  bold: true,
                ),
              ),
              Expanded(
                child: _PowerStat(
                  label: 'Totale RDF',
                  value:
                      '${(state.overallSimultaneityFactor * 100).toStringAsFixed(1)} %',
                  theme: theme,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          columnWidths: const {
            0: FlexColumnWidth(3.5),
            1: FlexColumnWidth(0.7),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(0.8),
            5: FlexColumnWidth(1.0),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration:
                  BoxDecoration(color: theme.colorScheme.primaryContainer),
              children: const [
                _TH('Omschrijving'),
                _TH('St.'),
                _TH('Pv nom. [W]'),
                _TH('Pv eff. [W]'),
                _TH('RDF'),
                _TH('% totaal'),
              ],
            ),
            for (final comp in state.components)
              TableRow(
                children: [
                  _TD(comp.description),
                  _TD('${comp.count}'),
                  _TD(comp.nominalTotalW.toStringAsFixed(2)),
                  _TD(comp.effectivePowerW.toStringAsFixed(2), bold: true),
                  _TD('${(comp.simultaneityFactor * 100).toStringAsFixed(0)}%'),
                  _TD(
                    totalEff > 0
                        ? '${(comp.effectivePowerW / totalEff * 100).toStringAsFixed(1)}%'
                        : '—',
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            TableRow(
              decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest),
              children: [
                _TD('Tint (top) = ${result.tIntTop.toStringAsFixed(2)} °C',
                    bold: true),
                _TD(''),
                _TD(state.totalPowerNominal.toStringAsFixed(2), bold: true),
                _TD(state.totalPower.toStringAsFixed(2), bold: true),
                _TD(
                    '${(state.overallSimultaneityFactor * 100).toStringAsFixed(0)}%',
                    bold: true),
                _TD('100%'),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _PowerStat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool bold;
  const _PowerStat({
    required this.label,
    required this.value,
    required this.theme,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
          Text(value,
              style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      );
}

// ── Component verificatie tabel ───────────────────────────────────────────────
class _VerificationTable extends StatelessWidget {
  final CalculationState state;
  const _VerificationTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final result = state.result!;
    final components =
        state.components.where((c) => c.maxTemperatureC != null).toList();

    if (components.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Voeg Tmax toe aan componenten voor verificatie.',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Table(
      border: TableBorder.all(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.2),
        4: FlexColumnWidth(1.5),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          children: const [
            _TH('Component'),
            _TH('Tmax [°C]'),
            _TH('Tint [°C]'),
            _TH('Marge [K]'),
            _TH('Status'),
          ],
        ),
        for (final comp in components)
          TableRow(
            children: [
              _TD(comp.description),
              _TD(comp.maxTemperatureC!.toStringAsFixed(0)),
              _TD(result.tIntTop.toStringAsFixed(1)),
              _TD((comp.maxTemperatureC! - result.tIntTop).toStringAsFixed(1),
                  color: comp.maxTemperatureC! >= result.tIntTop
                      ? Colors.green.shade700
                      : Colors.red.shade700),
              _TD(
                comp.maxTemperatureC! >= result.tIntTop
                    ? '✓ OK'
                    : '✗ Overschrijding',
                color: comp.maxTemperatureC! >= result.tIntTop
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                bold: true,
              ),
            ],
          ),
      ],
    );
  }
}

// ── Gedeelde widgets ──────────────────────────────────────────────────────────
class _GridRow extends StatelessWidget {
  final List<Widget> children;
  const _GridRow({required this.children});

  @override
  Widget build(BuildContext context) => Row(
        children: children
            .expand((w) => [Expanded(child: w), const SizedBox(width: 8)])
            .toList()
          ..removeLast(),
      );
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      );
}

class _TD extends StatelessWidget {
  final String text;
  final Color? color;
  final bool bold;
  const _TD(this.text, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: bold ? FontWeight.bold : null,
          ),
        ),
      );
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      );
}
