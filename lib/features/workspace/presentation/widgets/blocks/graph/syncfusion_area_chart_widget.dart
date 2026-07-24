import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/chart_data_model.dart';

/// A wrapper widget for Syncfusion Area Chart
/// Creates filled area charts that emphasize the magnitude of values over time,
/// useful for showing cumulative data or volume
class SyncfusionAreaChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String xAxisLabel;
  final String yAxisLabel;
  final String title;
  final bool showLegend;
  final bool showDataLabels;
  final ThemeData theme;

  const SyncfusionAreaChartWidget({
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
          primaryXAxis: CategoryAxis(
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
          series: <AreaSeries<ChartData, String>>[
            AreaSeries<ChartData, String>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              name: 'Data',
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
              borderColor: theme.colorScheme.primary,
              borderWidth: isWide ? 2 : 1.5,
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
