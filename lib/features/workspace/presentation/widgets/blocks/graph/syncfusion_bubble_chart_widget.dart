import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Data model for bubble charts with size parameter
class BubbleChartData {
  final String x;
  final double y;
  final double size;

  BubbleChartData(this.x, this.y, this.size);
}

/// A wrapper widget for Syncfusion Bubble Chart
/// Provides 3D data visualization with bubble size representing a third dimension
class SyncfusionBubbleChartWidget extends StatelessWidget {
  static const double _defaultBubbleSize = 10.0;
  static const double _minBubbleSize = 5.0;
  static const double _mobileScaleFactor = 0.8;
  static const double _desktopScaleFactor = 1.0;
  
  final List<Map<String, dynamic>> data;
  final String xAxisLabel;
  final String yAxisLabel;
  final String title;
  final bool showLegend;
  final bool showDataLabels;
  final ThemeData theme;

  const SyncfusionBubbleChartWidget({
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
            format: 'point.x: point.y (Size: point.size)',
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
          series: <BubbleSeries<BubbleChartData, double>>[
            BubbleSeries<BubbleChartData, double>(
              dataSource: chartData,
              xValueMapper: (BubbleChartData data, _) => double.tryParse(data.x) ?? 0.0,
              yValueMapper: (BubbleChartData data, _) => data.y,
              sizeValueMapper: (BubbleChartData data, _) => data.size * (isWide ? _desktopScaleFactor : _mobileScaleFactor),
              name: 'Data',
              color: theme.colorScheme.primary.withOpacity(0.7),
              borderColor: theme.colorScheme.primary,
              borderWidth: 1,
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

  List<BubbleChartData> _parseChartData() {
    return data.map((item) {
      final x = item['x']?.toString() ?? '';
      final y = (item['y'] is num) ? (item['y'] as num).toDouble() : 0.0;
      // Use 'size' field if available, otherwise use a consistent default
      // Ensure minimum size for visibility
      final rawSize = (item['size'] is num) 
          ? (item['size'] as num).toDouble() 
          : _defaultBubbleSize;
      final size = rawSize < _minBubbleSize ? _minBubbleSize : rawSize;
      return BubbleChartData(x, y, size);
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
