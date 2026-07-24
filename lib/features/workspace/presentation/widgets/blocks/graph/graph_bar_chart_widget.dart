import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/presentation/services/graph_expression_evaluator.dart';
import 'package:barruu/features/workspace/presentation/services/graph_utilities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A widget that renders a bar chart from numeric data
/// 
/// This widget parses comma-separated numeric values and displays
/// them as a bar chart with support for grid and tooltips.
/// 
/// Example usage:
/// ```dart
/// GraphBarChartWidget(
///   data: '10,20,15,30,25',
///   showGrid: true,
///   theme: theme,
/// )
/// ```
class GraphBarChartWidget extends StatelessWidget {
  /// Comma-separated numeric values (e.g., "10,20,15,30,25")
  final String data;
  
  /// Whether to show grid lines
  final bool showGrid;
  
  /// App theme for styling
  final ThemeData theme;

  const GraphBarChartWidget({
    required this.data,
    required this.showGrid,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState('No data provided');
    }

    try {
      // Parse comma-separated values
      final values = GraphExpressionEvaluator.parseNumericValues(data);

      final barGroups = <BarChartGroupData>[];
      final maxValue = values.reduce((a, b) => a > b ? a : b);
      
      for (int i = 0; i < values.length; i++) {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i],
                color: theme.colorScheme.primary,
                width: 20,
                borderRadius: BorderRadius.circular(4),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxValue * 1.1,
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
              ),
            ],
          ),
        );
      }

      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barGroups: barGroups,
          gridData: showGrid 
              ? FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxValue / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    strokeWidth: 1,
                    dashArray: [6, 4],
                  ),
                )
              : const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  GraphUtilities.formatNumber(value),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline),
              left: BorderSide(color: theme.colorScheme.outline),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: GraphUtilities.buildBarTouchTooltip(theme),
          ),
        ),
      );
    } on FormatException catch (e) {
      logger.e('Invalid bar chart data format', error: e);
      return _buildEmptyState('Invalid data format');
    } catch (e, stackTrace) {
      logger.e('Error generating bar chart', error: e, stackTrace: stackTrace);
      return _buildEmptyState('Error generating chart');
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
