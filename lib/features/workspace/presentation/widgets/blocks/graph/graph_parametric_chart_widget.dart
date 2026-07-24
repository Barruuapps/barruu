import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/presentation/services/graph_expression_evaluator.dart';
import 'package:barruu/features/workspace/presentation/services/graph_utilities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A widget that renders a parametric graph from parametric equations
/// 
/// This widget evaluates parametric equations x(t) and y(t) and displays
/// them as a curve with support for zoom, pan, and grid.
/// 
/// Example usage:
/// ```dart
/// GraphParametricChartWidget(
///   expression: 'x(t)=cos(t), y(t)=sin(t)',
///   tMin: 0,
///   tMax: 6.28,
///   zoomLevel: 1.0,
///   panOffset: Offset.zero,
///   showGrid: true,
///   theme: theme,
/// )
/// ```
class GraphParametricChartWidget extends StatelessWidget {
  /// The parametric equations (e.g., "x(t)=cos(t), y(t)=sin(t)")
  final String expression;
  
  /// Minimum parameter value
  final double tMin;
  
  /// Maximum parameter value
  final double tMax;
  
  /// Current zoom level (1.0 = normal, >1.0 = zoomed in)
  final double zoomLevel;
  
  /// Pan offset for navigation
  final Offset panOffset;
  
  /// Whether to show grid lines
  final bool showGrid;
  
  /// App theme for styling
  final ThemeData theme;

  const GraphParametricChartWidget({
    required this.expression,
    required this.tMin,
    required this.tMax,
    required this.zoomLevel,
    required this.panOffset,
    required this.showGrid,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (expression.isEmpty) {
      return _buildEmptyState('No expression provided');
    }

    try {
      // Evaluate the parametric expression
      final result = GraphExpressionEvaluator.evaluateParametricExpression(
        expression,
        tMin,
        tMax,
      );

      if (result.spots.isEmpty) {
        return _buildEmptyState('No valid points to display');
      }

      // Calculate scaled bounds with padding
      final paddingX = (result.maxX - result.minX) * 0.1;
      final paddingY = (result.maxY - result.minY) * 0.1;
      
      final scaledXBounds = GraphUtilities.calculateScaledBounds(
        minValue: result.minX,
        maxValue: result.maxX,
        zoomLevel: zoomLevel,
        panOffset: panOffset.dx,
        padding: paddingX / (result.maxX - result.minX),
      );
      
      final scaledYBounds = GraphUtilities.calculateScaledBounds(
        minValue: result.minY,
        maxValue: result.maxY,
        zoomLevel: zoomLevel,
        panOffset: panOffset.dy,
        padding: paddingY / (result.maxY - result.minY),
      );

      final hInterval = (scaledYBounds.max - scaledYBounds.min) / 10;
      final vInterval = (scaledXBounds.max - scaledXBounds.min) / 10;

      return LineChart(
        LineChartData(
          gridData: showGrid 
              ? GraphUtilities.buildGridData(theme, hInterval, vInterval)
              : const FlGridData(show: false),
          titlesData: GraphUtilities.buildTitlesData(theme),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          minX: scaledXBounds.min,
          maxX: scaledXBounds.max,
          minY: scaledYBounds.min,
          maxY: scaledYBounds.max,
          lineBarsData: [
            LineChartBarData(
              spots: result.spots,
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: GraphUtilities.buildLineTouchTooltip(theme),
          ),
        ),
      );
    } on FormatException catch (e) {
      logger.e('Invalid parametric expression format', error: e);
      return _buildEmptyState('Invalid parametric equation');
    } catch (e, stackTrace) {
      logger.e('Error generating parametric graph', error: e, stackTrace: stackTrace);
      return _buildEmptyState('Error generating graph');
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
