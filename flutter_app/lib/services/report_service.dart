import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/enclosure.dart';
import 'calculation_state.dart';

class ReportService {
  // ── JSON export ────────────────────────────────────────────────────────────

  static Map<String, dynamic> _buildJsonData(CalculationState state) {
    final enc = state.enclosure;
    final result = state.result!;
    return {
      'meta': {
        'standard': 'IEC TR 60890:2022',
        'generated_at': DateTime.now().toIso8601String(),
      },
      'input': {
        'height_mm': enc.heightMm,
        'width_mm': enc.widthMm,
        'depth_mm': enc.depthMm,
        'installation_type': enc.installationType.name,
        'ventilation_type': enc.ventilationType.name,
        'ventilation_area_cm2': enc.ventilationAreaCm2,
        'num_partitions': enc.numPartitions,
        'ambient_temperature_C': enc.ambientTemperatureC,
        'solar_radiation': enc.solarRadiation.name,
        'total_power_nominal_W': state.totalPowerNominal,
        'total_power_effective_W': state.totalPower,
        'overall_rdf': state.overallSimultaneityFactor,
      },
      'results': {
        'Ae_m2': result.ae,
        'Ab_m2': result.ab,
        'k': result.k,
        'f': result.f,
        'c': result.c,
        'x': result.x,
        'd': result.d,
        'delta_t_05_K': result.deltaT05,
        'delta_t_075_K': result.deltaT075,
        'delta_t_10_K': result.deltaT10,
        'delta_t_solar_K': result.deltaTSolar,
        'T_ambient_C': result.tAmbient,
        'T_int_mid_C': result.tIntMid,
        'T_int_top_C': result.tIntTop,
      },
      'components': state.components
          .map((c) => {
                'description': c.description,
                'count': c.count,
                'power_loss_nominal_W': c.powerLossW,
                'nominal_current_A': c.nominalCurrentA,
                'design_current_A': c.designCurrentA,
                'loading_factor': c.loadingFactor,
                'cross_section_mm2': c.crossSectionMm2,
                'ith_max_A': c.ithMaxA,
                'power_effective_W': c.effectivePowerW,
                'rdf': c.simultaneityFactor,
                'max_temperature_C': c.maxTemperatureC,
                'verification': c.maxTemperatureC != null
                    ? (result.tIntTop <= c.maxTemperatureC! ? 'PASS' : 'FAIL')
                    : 'N/A',
              })
          .toList(),
    };
  }

  static Future<void> exportJson(
      BuildContext context, CalculationState state) async {
    final data = _buildJsonData(state);
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/iec60890_resultaat.json');
    await file.writeAsString(json);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'IEC TR 60890 Warmteberekening',
    );
  }

  // ── PDF export ────────────────────────────────────────────────────────────

  static Future<void> exportPdf(
      BuildContext context, CalculationState state) async {
    final enc = state.enclosure;
    final result = state.result!;
    final pdf = pw.Document();

    const blue = PdfColor.fromInt(0xFF1A5276);
    const lightBlue = PdfColor.fromInt(0xFFD6EAF8);
    const green = PdfColor.fromInt(0xFF1E8449);
    const red = PdfColor.fromInt(0xFFC0392B);

    pw.Widget th(String text) => pw.Container(
          color: blue,
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: pw.Text(text,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 8)),
        );

    pw.Widget td(String text,
            {bool bold = false, PdfColor? color, bool right = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: pw.Text(
            text,
            textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight:
                  bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        );

    pw.TableRow headerRow(List<String> cols) =>
        pw.TableRow(children: cols.map(th).toList());

    pw.TableRow dataRow(List<pw.Widget> cells, {PdfColor? bg}) =>
        pw.TableRow(
          decoration:
              bg != null ? pw.BoxDecoration(color: bg) : null,
          children: cells,
        );

    bool alt = false;
    PdfColor? altBg() {
      alt = !alt;
      return alt ? null : lightBlue;
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) {
        final chartFont = PdfFont.helvetica(ctx.document);
        return [
        // ── Koptekst ──
        pw.Text('IEC TR 60890:2022 - Warmteberekening',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text(
            'Gegenereerd: ${DateTime.now().toString().substring(0, 16)}',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey600)),
        pw.Divider(color: blue, thickness: 1.5),
        pw.SizedBox(height: 8),

        // ── Invoergegevens ──
        pw.Text('Invoergegevens',
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: blue)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            headerRow(
                ['Parameter', 'Waarde', 'Parameter', 'Waarde']),
            dataRow([
              td('H x B x D'),
              td('${enc.heightMm.toInt()} x ${enc.widthMm.toInt()} x ${enc.depthMm.toInt()} mm'),
              td('Installatietype'),
              td(enc.installationType.label),
            ]),
            dataRow([
              td('Ventilatie'),
              td(enc.ventilationType.label),
              td('Schotten'),
              td('${enc.numPartitions}'),
            ]),
            dataRow([
              td('Ta omgeving'),
              td('${enc.ambientTemperatureC.toStringAsFixed(1)} °C'),
              td('Zonnestraling'),
              td(enc.solarRadiation.label),
            ]),
          ],
        ),
        pw.SizedBox(height: 10),

        // ── Vermogensverdeling ──
        pw.Text('Vermogensverdeling',
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: blue)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
          },
          children: [
            headerRow(['Parameter', 'Waarde']),
            dataRow([
              td('P nominaal (bij In, zonder RDF)'),
              td('${state.totalPowerNominal.toStringAsFixed(2)} W',
                  right: true),
            ]),
            dataRow([
              td('P effectief (belastingsfactor + RDF)'),
              td('${state.totalPower.toStringAsFixed(2)} W',
                  bold: true, right: true),
            ]),
            dataRow([
              td('Totale gelijktijdigheidsfactor'),
              td('${(state.overallSimultaneityFactor * 100).toStringAsFixed(1)} %',
                  right: true),
            ]),
          ],
        ),
        pw.SizedBox(height: 10),

        // ── Rekenfactoren ──
        pw.Text('Berekeningsresultaten',
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: blue)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(2),
            5: const pw.FlexColumnWidth(1),
          },
          children: [
            headerRow([
              'Parameter', 'Waarde', 'Eenheid',
              'Parameter', 'Waarde', 'Eenheid'
            ]),
            dataRow([
              td('Ae'), td(result.ae.toStringAsFixed(4)), td('m²'),
              td('Ab'), td(result.ab.toStringAsFixed(4)), td('m²'),
            ]),
            dataRow([
              td('k'),  td(result.k.toStringAsFixed(6)),  td('K/W^x'),
              td('f'), td(result.f.toStringAsFixed(4)), td('-'),
            ]),
            dataRow([
              td('c'), td(result.c.toStringAsFixed(5)), td('-'),
              td('x'), td(result.x.toString()), td('-'),
            ]),
            dataRow([
              td('d'), td(result.d.toString()), td('-'),
              td(''), td(''), td(''),
            ]),
            dataRow([
              td('dt0.5'), td(result.deltaT05.toStringAsFixed(3), bold: true), td('K'),
              td('dt0.75'), td(result.deltaT075.toStringAsFixed(3), bold: true), td('K'),
            ]),
            dataRow([
              td('dt1.0'), td(result.deltaT10.toStringAsFixed(3), bold: true), td('K'),
              if (result.deltaTSolar > 0) ...[
                td('Zonnecorrectie'),
                td('+${result.deltaTSolar.toStringAsFixed(0)}', bold: true),
                td('K'),
              ] else ...[
                td(''), td(''), td(''),
              ],
            ]),
            dataRow([
              td('Tint midden'), td(result.tIntMid.toStringAsFixed(2), bold: true), td('°C'),
              td('Tint top'),
              td(result.tIntTop.toStringAsFixed(2),
                  bold: true,
                  color: result.tIntTop > 70 ? red : green),
              td('°C'),
            ]),
          ],
        ),
        pw.SizedBox(height: 10),

        // ── Temperatuurprofiel ──
        pw.Text('Temperatuurprofiel',
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: blue)),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 180,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.CustomPaint(
            size: const PdfPoint(520, 180),
            painter: (canvas, size) {
              // PDF origin = bottom-left. Y increases upward.
              const leftMargin = 42.0;
              const bottomMargin = 26.0; // space for temp labels + title
              const topMargin = 8.0;
              final chartW = size.x - leftMargin - 10;
              final chartH = size.y - bottomMargin - topMargin;

              final ta = result.tAmbient;
              final tMin = ta;
              final tMax = result.tIntTop + (result.tIntTop - ta) * 0.12;
              final tRange = tMax - tMin;

              // h=0 → bottom (y=bottomMargin), h=1 → top (y=bottomMargin+chartH)
              double tx(double temp) =>
                  leftMargin + (temp - tMin) / tRange * chartW;
              double ty(double hRatio) =>
                  bottomMargin + hRatio * chartH;

              const steps = 5;

              // Grid lines (temperature, vertical)
              canvas.setStrokeColor(PdfColors.grey200);
              canvas.setLineWidth(0.4);
              for (var i = 0; i <= steps; i++) {
                final t = tMin + i / steps * tRange;
                canvas.moveTo(tx(t), bottomMargin);
                canvas.lineTo(tx(t), bottomMargin + chartH);
                canvas.strokePath();
              }
              // Grid lines (height, horizontal)
              for (final h in [0.0, 0.25, 0.5, 0.75, 1.0]) {
                canvas.moveTo(leftMargin, ty(h));
                canvas.lineTo(leftMargin + chartW, ty(h));
                canvas.strokePath();
              }

              // Ambient temperature vertical dashed line
              canvas.setStrokeColor(PdfColors.grey400);
              canvas.setLineWidth(0.6);
              canvas.setLineDashPattern([3, 2]);
              canvas.moveTo(tx(ta), bottomMargin);
              canvas.lineTo(tx(ta), bottomMargin + chartH);
              canvas.strokePath();
              canvas.setLineDashPattern([]);

              // Axes
              canvas.setStrokeColor(PdfColors.grey700);
              canvas.setLineWidth(0.8);
              // Y axis (left, vertical)
              canvas.moveTo(leftMargin, bottomMargin);
              canvas.lineTo(leftMargin, bottomMargin + chartH);
              canvas.strokePath();
              // X axis (bottom, horizontal)
              canvas.moveTo(leftMargin, bottomMargin);
              canvas.lineTo(leftMargin + chartW, bottomMargin);
              canvas.strokePath();

              // Temperature profile line
              final profilePoints = [
                (ta, 0.0),
                (ta + result.deltaT05, 0.5),
                (ta + result.deltaT075, 0.75),
                (ta + result.deltaT10, 1.0),
              ];
              canvas.setStrokeColor(const PdfColor(0.1, 0.32, 0.64));
              canvas.setLineWidth(1.8);
              canvas.moveTo(tx(profilePoints[0].$1), ty(profilePoints[0].$2));
              for (final pt in profilePoints.skip(1)) {
                canvas.lineTo(tx(pt.$1), ty(pt.$2));
              }
              canvas.strokePath();

              // Key point dots
              canvas.setFillColor(const PdfColor(0.75, 0.15, 0.17));
              for (final pt in profilePoints) {
                canvas.drawEllipse(tx(pt.$1), ty(pt.$2), 2.5, 2.5);
                canvas.fillPath();
              }

              // Temperature axis labels (below X axis)
              for (var i = 0; i <= steps; i++) {
                final t = tMin + i / steps * tRange;
                canvas.drawString(
                    chartFont, 6.5, '${t.toStringAsFixed(0)}°',
                    tx(t) - 6, bottomMargin - 10);
              }
              // Height axis labels (left of Y axis)
              for (final h in [0.0, 0.25, 0.5, 0.75, 1.0]) {
                canvas.drawString(
                    chartFont, 6.5, '${(h * 100).toInt()}%',
                    2, ty(h) - 2.5);
              }
              // Point temperature labels (next to dots)
              canvas.setFillColor(PdfColors.black);
              for (final pt in profilePoints) {
                canvas.drawString(
                    chartFont, 6, '${pt.$1.toStringAsFixed(1)}°C',
                    tx(pt.$1) + 3, ty(pt.$2) + 2);
              }
              // X axis title
              canvas.setFillColor(PdfColors.grey600);
              canvas.drawString(chartFont, 7, 'Temperatuur [°C]',
                  leftMargin + chartW / 2 - 28, 2);
            },
          ),
        ),
        pw.SizedBox(height: 10),

        // ── Componentenlijst ──
        pw.Text('Componentenlijst',
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: blue)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3.5),
            1: const pw.FlexColumnWidth(0.6),
            2: const pw.FlexColumnWidth(1.3),
            3: const pw.FlexColumnWidth(1.1),
            4: const pw.FlexColumnWidth(1.1),
            5: const pw.FlexColumnWidth(1.0),
            6: const pw.FlexColumnWidth(1.5),
            7: const pw.FlexColumnWidth(1.1),
            8: const pw.FlexColumnWidth(1.4),
            9: const pw.FlexColumnWidth(0.9),
          },
          children: [
            headerRow([
              'Omschrijving', 'St.', 'Pv/st [W]',
              'In [A]', 'Ing [A]', '(I/In)²',
              'Doorsnede', 'Ith [A]',
              'Pv eff. [W]', 'RDF',
            ]),
            for (final c in state.components) ...[
              () {
                final bg = altBg();
                final hasLoading = c.loadingFactor < 0.9999;
                return dataRow([
                  td(c.description),
                  td('${c.count}', right: true),
                  td(c.powerLossW.toStringAsFixed(2), right: true),
                  td(c.nominalCurrentA != null
                      ? c.nominalCurrentA!.toStringAsFixed(1)
                      : '', right: true),
                  td(c.designCurrentA != null
                      ? c.designCurrentA!.toStringAsFixed(1)
                      : '', right: true),
                  td(hasLoading
                      ? '${(c.loadingFactor * 100).toStringAsFixed(0)}%'
                      : '', right: true),
                  td(c.crossSectionMm2 != null
                      ? '${c.crossSectionMm2} mm²'
                      : ''),
                  td(c.ithMaxA != null
                      ? '${c.ithMaxA!.toInt()}'
                      : '', right: true),
                  td(c.effectivePowerW.toStringAsFixed(2),
                      bold: true, right: true),
                  td('${(c.simultaneityFactor * 100).toStringAsFixed(0)}%',
                      right: true),
                ], bg: bg);
              }(),
            ],
            // Totaalrij
            dataRow([
              td('Totaal', bold: true),
              td(''),
              td(state.totalPowerNominal.toStringAsFixed(2),
                  bold: true, right: true),
              td(''), td(''), td(''), td(''), td(''),
              td(state.totalPower.toStringAsFixed(2),
                  bold: true, right: true),
              td('${(state.overallSimultaneityFactor * 100).toStringAsFixed(0)}%',
                  bold: true, right: true),
            ], bg: lightBlue),
          ],
        ),
        pw.SizedBox(height: 10),

        // ── Componentverificatie ──
        if (state.components.any((c) => c.maxTemperatureC != null)) ...[
          pw.Text('Componentverificatie (Tmax)',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: blue)),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
            },
            children: [
              headerRow([
                'Component', 'Pv eff. [W]',
                'Tmax [°C]', 'Tint [°C]', 'Marge [K]', 'Status',
              ]),
              for (final c
                  in state.components.where((c) => c.maxTemperatureC != null))
                () {
                  final bg = altBg();
                  final pass = result.tIntTop <= c.maxTemperatureC!;
                  final marge = c.maxTemperatureC! - result.tIntTop;
                  return dataRow([
                    td(c.description),
                    td(c.effectivePowerW.toStringAsFixed(2), right: true),
                    td(c.maxTemperatureC!.toStringAsFixed(0), right: true),
                    td(result.tIntTop.toStringAsFixed(1), right: true),
                    td(marge.toStringAsFixed(1),
                        color: pass ? green : red, bold: true, right: true),
                    td(pass ? 'OK' : 'FAIL',
                        color: pass ? green : red, bold: true),
                  ], bg: bg);
                }(),
            ],
          ),
        ],
      ]; }
    ));

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/iec60890_rapport.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'IEC TR 60890 Warmteberekening rapport',
    );
  }
}
