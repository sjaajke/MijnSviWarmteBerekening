import 'package:flutter/material.dart';

class ExplanationScreen extends StatelessWidget {
  const ExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Stap-voor-stap uitleg',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Volledige rekenmethode IEC TR 60890:2022',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _OverviewCard(),
        const SizedBox(height: 12),
        _StepCard(
          step: 1,
          title: 'Effectief koeloppervlak Ae',
          formula: 'Ae = Σ (Ao × b)  [m²]',
          description:
              'Elk buitenoppervlak van de kast krijgt een b-factor op basis van '
              'oriëntatie en of het vrij is of grenst aan een wand.',
          details: const _BFactorTable(),
          note: 'De bovenzijde koelt het best (b = 1.4 vrij). '
              'De onderkant draagt nooit bij (b = 0).',
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 2,
          title: 'Basisoppervlak Ab en factor f',
          formula: 'Ab = W × D\nf = H¹·³⁵ / Ab',
          description:
              'De hoogte/basis-factor f beschrijft de verhouding tussen hoogte '
              'en doorsnede. Een slanke hoge kast heeft een groot schoorsteen-effect.',
          note: 'Voorbeeld (H=0.95 m, W=1.05 m, D=0.225 m):\n'
              'Ab = 0.236 m²  →  f = 0.929 / 0.236 = 3.95',
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 3,
          title: 'Omhullingscoëfficiënt k',
          formula: 'k = 0.58 × Ae⁻⁰·⁷⁹⁵',
          description:
              'k geeft aan hoeveel temperatuurstijging 1 W veroorzaakt. '
              'De formule verschilt per situatie:',
          details: const _KTable(),
          note: 'Voorbeeld: k = 0.58 × 2.112⁻⁰·⁷⁹⁵ ≈ 0.320',
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 4,
          title: 'Exponent x',
          formula: 'x = 0.804  of  x = 0.715',
          description:
              'De temperatuurstijging is niet lineair met het vermogensverlies. '
              'Bij ventilatie (x = 0.715) neemt het koeleffect relatief toe bij '
              'hogere vermogens.',
          details: const _XTable(),
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 5,
          title: 'Temperatuurverdelingscoëfficiënt c',
          formula: 'c = −0.0017 · f² + 0.055 · f + 1.146',
          description:
              'c is de verhouding Δt₁.₀ / Δt₀.₅. Een hogere c betekent een '
              'sterkere temperatuurgradiënt van onder naar boven.',
          note: 'Voorbeeld (f = 3.95):\n'
              'c = −0.0017 × 15.60 + 0.055 × 3.95 + 1.146 ≈ 1.337',
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 6,
          title: 'Scheidingsplaatfactor d',
          formula: 'd = 1.0 / 1.3 / 1.5 / 1.7 / 2.0',
          description:
              'Horizontale schotten belemmeren de convectieve luchtstroom omhoog. '
              'Elk schot verhoogt de temperatuurstijging significant.',
          details: const _DTable(),
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 7,
          title: 'Temperatuurstijging op halve hoogte Δt₀.₅',
          formula: 'Δt₀.₅ = k × d × Pˣ  [K]',
          description:
              'Het referentiepunt van de norm: temperatuurstijging op halve hoogte '
              'van de kast.',
          note: 'Voorbeeld (k=0.320, d=1.0, P=136.25 W, x=0.804):\n'
              'Δt₀.₅ = 0.320 × 1.0 × 136.25⁰·⁸⁰⁴ ≈ 16.65 K',
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 8,
          title: 'Temperatuurstijging bovenin Δt₁.₀',
          formula: 'Δt₁.₀ = c × Δt₀.₅  [K]\nΔt₀.₇₅ = Δt₀.₅ + (Δt₁.₀ − Δt₀.₅) / 2',
          description:
              'De temperatuurstijging bovenin de kast is altijd groter dan op '
              'halve hoogte. Op 75% hoogte wordt lineair geïnterpoleerd.',
          note: 'Voorbeeld: Δt₁.₀ = 1.337 × 16.65 ≈ 22.25 K',
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 9,
          title: 'Absolute interne temperatuur',
          formula: 'T_int,top = Ta + Δt₁.₀  [°C]',
          description:
              'De werkelijke interne luchttemperatuur. Voor elk component wordt '
              'gecontroleerd of T_int,top ≤ Tmax,component.',
          note: 'Voorbeeld (Ta = 25°C):\nT_int,top = 25 + 22.25 = 47.25°C',
        ),
        const SizedBox(height: 12),
        _StepCard(
          step: 10,
          title: 'Zonnestraling — Annex C (optioneel)',
          formula: 'T_int = Ta + Δt₁.₀ + Δt_zon',
          description:
              'Bij buitenapplicaties voegt directe zonnestraling extra warmte toe, '
              'afhankelijk van de kleur van de kast.',
          details: const _SolarTable(),
        ),
        const SizedBox(height: 12),
        _ReferenceExampleCard(),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Overview card
// ---------------------------------------------------------------------------

class _OverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card.filled(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overzicht rekenstappen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 8),
            ...[
              ('1', 'Ae', 'Effectief koeloppervlak [m²]'),
              ('2', 'Ab, f', 'Basisoppervlak en hoogte/basis-factor'),
              ('3', 'k', 'Omhullingscoëfficiënt [K/Wˣ]'),
              ('4', 'x', 'Exponent vermogensverlies'),
              ('5', 'c', 'Temperatuurverdelingscoëfficiënt'),
              ('6', 'd', 'Scheidingsplaatfactor'),
              ('7', 'Δt₀.₅', 'Temperatuurstijging halve hoogte [K]'),
              ('8', 'Δt₁.₀', 'Temperatuurstijging bovenin [K]'),
              ('9', 'T_int', 'Absolute interne temperatuur [°C]'),
              ('10', 'Zon', 'Zonnestralingcorrectie Annex C'),
            ].map((row) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          row.$1,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          row.$2,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.$3,
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step card
// ---------------------------------------------------------------------------

class _StepCard extends StatefulWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.formula,
    required this.description,
    this.details,
    this.note,
  });

  final int step;
  final String title;
  final String formula;
  final String description;
  final Widget? details;
  final String? note;

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: (widget.details != null || widget.note != null)
            ? () => setState(() => _expanded = !_expanded)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      '${widget.step}',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (widget.details != null || widget.note != null)
                    Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Formula box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.formula,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(widget.description, style: textTheme.bodyMedium),
              // Expandable section
              if (_expanded) ...[
                if (widget.details != null) ...[
                  const SizedBox(height: 12),
                  widget.details!,
                ],
                if (widget.note != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16,
                            color: colorScheme.tertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.note!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail tables
// ---------------------------------------------------------------------------

class _BFactorTable extends StatelessWidget {
  const _BFactorTable();

  @override
  Widget build(BuildContext context) {
    return _SimpleTable(
      headers: const ['Oppervlak', 'b'],
      rows: const [
        ['Bovenzijde — vrij', '1.4'],
        ['Bovenzijde — afgedekt', '0.7'],
        ['Zijkant/voor/achter — vrij', '0.9'],
        ['Zijkant/voor/achter — afgedekt', '0.5'],
        ['Onderzijde (vloer)', '0.0'],
      ],
    );
  }
}

class _KTable extends StatelessWidget {
  const _KTable();

  @override
  Widget build(BuildContext context) {
    return _SimpleTable(
      headers: const ['Situatie', 'Formule'],
      rows: const [
        ['Ae > 1.25 m², geen ventilatie', 'k = 0.58 × Ae⁻⁰·⁷⁹⁵'],
        ['Ae > 1.25 m², ventilatie', 'k = k_nv × η_v'],
        ['Ae ≤ 1.25 m², Ae ≥ 0.08', 'k = 0.626 × Ae⁻⁰·⁷³⁷'],
        ['Ae < 0.08 m²', 'k = 4.0'],
      ],
    );
  }
}

class _XTable extends StatelessWidget {
  const _XTable();

  @override
  Widget build(BuildContext context) {
    return _SimpleTable(
      headers: const ['Situatie', 'x'],
      rows: const [
        ['Ae > 1.25 m², geen ventilatie', '0.804'],
        ['Ae > 1.25 m², ventilatie', '0.715'],
        ['Ae ≤ 1.25 m²', '0.804'],
      ],
    );
  }
}

class _DTable extends StatelessWidget {
  const _DTable();

  @override
  Widget build(BuildContext context) {
    return _SimpleTable(
      headers: const ['Aantal schotten', 'd'],
      rows: const [
        ['0', '1.0'],
        ['1', '1.3'],
        ['2', '1.5'],
        ['3', '1.7'],
        ['≥ 4', '2.0'],
      ],
    );
  }
}

class _SolarTable extends StatelessWidget {
  const _SolarTable();

  @override
  Widget build(BuildContext context) {
    return _SimpleTable(
      headers: const ['Oppervlakkleur', 'Δt_zon'],
      rows: const [
        ['Geen zonnestraling', '+0 K'],
        ['Licht oppervlak', '+10 K'],
        ['Donker oppervlak', '+25 K'],
      ],
    );
  }
}

class _SimpleTable extends StatelessWidget {
  const _SimpleTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        border: TableBorder.all(
          color: colorScheme.outlineVariant,
          width: 0.5,
          borderRadius: BorderRadius.circular(8),
        ),
        columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
            ),
            children: headers
                .map((h) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Text(
                        h,
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
          // Data rows
          ...rows.map(
            (row) => TableRow(
              children: row
                  .map((cell) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Text(cell, style: textTheme.bodySmall),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reference example card
// ---------------------------------------------------------------------------

class _ReferenceExampleCard extends StatefulWidget {
  @override
  State<_ReferenceExampleCard> createState() => _ReferenceExampleCardState();
}

class _ReferenceExampleCardState extends State<_ReferenceExampleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calculate_outlined,
                      color: colorScheme.onSecondaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Volledig rekenvoorbeeld — EWK-G46/31',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                ...[
                  ('Afmetingen', 'H=950mm, W=1050mm, D=225mm'),
                  ('Ab', '1.050 × 0.225 = 0.2363 m²'),
                  ('Ae', '0.165 + 0.898 + 0.499 + 0.192 + 0.192 + 0.166 = 2.112 m²'),
                  ('f', '0.950¹·³⁵ / 0.2363 = 3.950'),
                  ('k', '0.58 × 2.112⁻⁰·⁷⁹⁵ = 0.320'),
                  ('c', '−0.0017×15.60 + 0.055×3.95 + 1.146 = 1.337'),
                  ('x', '0.804  (geen ventilatie)'),
                  ('d', '1.0  (geen schotten)'),
                  ('Δt₀.₅', '0.320 × 1.0 × 136.25⁰·⁸⁰⁴ = 16.65 K'),
                  ('Δt₁.₀', '1.337 × 16.65 = 22.25 K'),
                  ('T_int,top', '25 + 22.25 = 47.25°C'),
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            item.$1,
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondaryContainer,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'T_int,top = 47.25°C — overeenkomst met Excel-referentie '
                          'binnen 0.01% (ref: 47.2505°C)',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
