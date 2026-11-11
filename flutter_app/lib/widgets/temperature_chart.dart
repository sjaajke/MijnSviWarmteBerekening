import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/iec60890.dart';

class TemperatureChart extends StatelessWidget {
  final CalculationResult result;
  final double heightMm;

  const TemperatureChart({
    super.key,
    required this.result,
    required this.heightMm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = result.temperatureProfile(steps: 51);

    // Convert to FlSpot: x = temperature, y = height in mm
    final spots = profile
        .map((p) => FlSpot(p.$2, p.$1 * heightMm))
        .toList();

    final minX = result.tAmbient - 2;
    final maxX = result.tIntTop + 5;

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: heightMm,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant,
            strokeWidth: 0.8,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant,
            strokeWidth: 0.8,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: theme.colorScheme.outline, width: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Hoogte [mm]', style: TextStyle(fontSize: 11)),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Temperatuur [°C]', style: TextStyle(fontSize: 11)),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt()}°',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          // Temperature profile
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: theme.colorScheme.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
        ],
        extraLinesData: ExtraLinesData(
          verticalLines: [
            // Ambient temperature reference line
            VerticalLine(
              x: result.tAmbient,
              color: theme.colorScheme.outline,
              strokeWidth: 1,
              dashArray: [4, 4],
              label: VerticalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                labelResolver: (_) => 'Ta=${result.tAmbient.toStringAsFixed(0)}°C',
              ),
            ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.x.toStringAsFixed(1)}°C\n${s.y.toStringAsFixed(0)} mm',
                      const TextStyle(fontSize: 11, color: Colors.white),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
