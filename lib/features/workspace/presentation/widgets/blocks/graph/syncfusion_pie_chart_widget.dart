import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/chart_data_model.dart';

/// A wrapper widget for Syncfusion Pie Chart
/// Circular chart for showing proportional data
/// Supports both pie and doughnut variants
class SyncfusionPieChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final bool showLegend;
  final bool showDataLabels;
  final ThemeData theme;
  final bool isDoughnut;

  const SyncfusionPieChartWidget({
    required this.data,
    required this.title,
    required this.showLegend,
    required this.showDataLabels,
    required this.theme,
    this.isDoughnut = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('No data available');
    }

    final chartData = _parseChartData();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final titleFontSize = isWide ? 16.0 : 13.0;
        final labelFontSize = isWide ? 12.0 : 10.0;
        final legendFontSize = isWide ? 12.0 : 10.0;
        final explodeOffset = isWide ? '5%' : '3%';
        
        return SfCircularChart(
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
          series: isDoughnut 
              ? <DoughnutSeries<ChartData, String>>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelMapper: (ChartData data, _) => '${data.x}: ${data.y}',
                    explode: true,
                    explodeIndex: 0,
                    explodeOffset: explodeOffset,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: showDataLabels,
                      textStyle: theme.textTheme.bodySmall?.copyWith(
                        fontSize: labelFontSize,
                      ),
                      labelPosition: ChartDataLabelPosition.outside,
                    ),
                  ),
                ]
              : <PieSeries<ChartData, String>>[
                  PieSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    dataLabelMapper: (ChartData data, _) => '${data.x}: ${data.y}',
                    explode: true,
                    explodeIndex: 0,
                    explodeOffset: explodeOffset,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: showDataLabels,
                      textStyle: theme.textTheme.bodySmall?.copyWith(
                        fontSize: labelFontSize,
                      ),
                      labelPosition: ChartDataLabelPosition.outside,
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
