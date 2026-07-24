import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/chart_data_model.dart';

/// A wrapper widget for Syncfusion Scatter Chart
/// Provides professional scatter plots for data analysis and correlation visualization
class SyncfusionScatterChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String xAxisLabel;
  final String yAxisLabel;
  final String title;
  final bool showLegend;
  final bool showDataLabels;
  final ThemeData theme;

  const SyncfusionScatterChartWidget({
    required this.data,
    required this.xAxisLabel,
    required this.yAxisLabel,
    required this.title,
    required this.showLegend,
    required this.showDataLabels,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('No data available');
    }

    // Convert data to chart data points
    final chartData = _parseChartData();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final titleFontSize = isWide ? 16.0 : 13.0;
        final axisFontSize = isWide ? 13.0 : 11.0;
        final labelFontSize = isWide ? 12.0 : 10.0;
        final legendFontSize = isWide ? 12.0 : 10.0;

        return SfCartesianChart(
          title: title.isNotEmpty
              ? ChartTitle(
                  text: title,
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                  ),
                )
              : const ChartTitle(),
          legend: Legend(
            isVisible: showLegend,
            position: LegendPosition.bottom,
            textStyle: theme.textTheme.bodySmall?.copyWith(
              fontSize: legendFontSize,
            ),
            overflowMode: LegendItemOverflowMode.wrap,
          ),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            format: 'point.x: point.y',
            textStyle: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: labelFontSize,
            ),
          ),
          primaryXAxis: NumericAxis(
            title: AxisTitle(
              text: xAxisLabel,
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                fontSize: axisFontSize,
              ),
            ),
            labelStyle: TextStyle(fontSize: labelFontSize),
            majorGridLines: const MajorGridLines(width: 0),
          ),
          primaryYAxis: NumericAxis(
            title: AxisTitle(
              text: yAxisLabel,
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                fontSize: axisFontSize,
              ),
            ),
            labelStyle: TextStyle(fontSize: labelFontSize),
            axisLine: const AxisLine(width: 0),
          ),
          series: <ScatterSeries<ChartData, double>>[
            ScatterSeries<ChartData, double>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) =>
                  double.tryParse(data.x) ?? 0.0,
              yValueMapper: (ChartData data, _) => data.y,
              name: 'Data',
              color: theme.colorScheme.primary,
              markerSettings: MarkerSettings(
                height: isWide ? 10 : 8,
                width: isWide ? 10 : 8,
                color: theme.colorScheme.primary,
                borderColor: theme.colorScheme.surface,
              ),
              dataLabelSettings: DataLabelSettings(
                isVisible: showDataLabels,
                textStyle: theme.textTheme.bodySmall?.copyWith(
                  fontSize: labelFontSize,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<ChartData> _parseChartData() {
    // Note: Although scatter plots typically use numeric X-axis values,
    // we maintain string storage for consistency with other chart types
    // and to allow categorical labels if needed. The string is converted
    // to numeric for plotting.
    return data.map((item) {
      final x = item['x']?.toString() ?? '';
      final y = (item['y'] is num) ? (item['y'] as num).toDouble() : 0.0;
      return ChartData(x, y);
    }).toList();
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
