import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/presentation/services/graph_expression_evaluator.dart';
import 'package:barruu/features/workspace/presentation/services/graph_utilities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A widget that renders a scatter plot from numeric data
///
/// This widget parses comma-separated numeric values and displays
/// them as a scatter plot with support for grid and tooltips.
///
/// Example usage:
/// ```dart
/// GraphScatterChartWidget(
///   data: '10,20,15,30,25',
///   showGrid: true,
///   theme: theme,
/// )
/// ```
class GraphScatterChartWidget extends StatelessWidget {
  /// Comma-separated numeric values (e.g., "10,20,15,30,25")
  final String data;

  /// Whether to show grid lines
  final bool showGrid;

  /// App theme for styling
  final ThemeData theme;

  const GraphScatterChartWidget({
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

      // Convert to scatter plot spots
      final spots = <FlSpot>[];
      double minY = double.infinity;
      double maxY = -double.infinity;

      for (int i = 0; i < values.length; i++) {
        spots.add(FlSpot(i.toDouble(), values[i]));
        minY = values[i] < minY ? values[i] : minY;
        maxY = values[i] > maxY ? values[i] : maxY;
      }

      // Calculate bounds with padding
      final paddingY = (maxY - minY) * 0.1;
      final scaledMinY = minY - paddingY;
      final scaledMaxY = maxY + paddingY;
      const scaledMinX = -0.5;
      final scaledMaxX = values.length - 0.5;

      final hInterval = (scaledMaxY - scaledMinY) / 10;
      final vInterval = (scaledMaxX - scaledMinX) / 10;

      return LineChart(
        LineChartData(
          gridData: showGrid
              ? GraphUtilities.buildGridData(theme, hInterval, vInterval)
              : const FlGridData(show: false),
          titlesData: GraphUtilities.buildTitlesData(theme),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline),
              left: BorderSide(color: theme.colorScheme.outline),
            ),
          ),
          minX: scaledMinX,
          maxX: scaledMaxX,
          minY: scaledMinY,
          maxY: scaledMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: Colors.transparent,
              barWidth: 0,
              dotData: FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 6,
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  );
                },
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: GraphUtilities.buildLineTouchTooltip(theme),
          ),
        ),
      );
    } on FormatException catch (e) {
      logger.e('Invalid scatter plot data format', error: e);
      return _buildEmptyState('Invalid data format');
    } catch (e, stackTrace) {
      logger.e(
        'Error generating scatter plot',
        error: e,
        stackTrace: stackTrace,
      );
      return _buildEmptyState('Error generating plot');
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
