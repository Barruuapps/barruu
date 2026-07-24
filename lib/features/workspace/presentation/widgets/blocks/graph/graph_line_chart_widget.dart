import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/presentation/services/graph_expression_evaluator.dart';
import 'package:barruu/features/workspace/presentation/services/graph_utilities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A widget that renders one or more line graphs from mathematical expressions.
///
/// Expressions may be separated by `;` to plot multiple curves on the same
/// chart, each with a distinct colour.  The first curve uses the theme's
/// primary colour; subsequent curves use [kEquationColors].
///
/// Example usage:
/// ```dart
/// GraphLineChartWidget(
///   expression: 'x^2 + 2*x + 1; sin(x)',
///   minX: -10,
///   maxX: 10,
///   zoomLevel: 1.0,
///   panOffset: Offset.zero,
///   showGrid: true,
///   showIntercepts: true,
///   theme: theme,
///   onKeyPointsCalculated: (keyPoints) { /* handle key points */ },
/// )
/// ```
class GraphLineChartWidget extends StatelessWidget {
  /// One or more mathematical expressions, separated by `;`.
  /// e.g. `"x^2"` or `"x^2; sin(x); x + 1"`.
  final String expression;

  /// Minimum x value for the domain
  final double minX;

  /// Maximum x value for the domain
  final double maxX;

  /// Current zoom level (1.0 = normal, >1.0 = zoomed in)
  final double zoomLevel;

  /// Pan offset for navigation
  final Offset panOffset;

  /// Whether to show grid lines
  final bool showGrid;

  /// Whether to show intercept markers
  final bool showIntercepts;

  /// App theme for styling
  final ThemeData theme;

  /// Callback when key points are calculated (called with first expression's points)
  final void Function(GraphKeyPoints)? onKeyPointsCalculated;

  const GraphLineChartWidget({
    required this.expression,
    required this.minX,
    required this.maxX,
    required this.zoomLevel,
    required this.panOffset,
    required this.showGrid,
    required this.showIntercepts,
    required this.theme,
    this.onKeyPointsCalculated,
    super.key,
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Splits [expression] on `;` and returns each non-empty trimmed sub-string.
  List<String> get _expressions => expression
      .split(';')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    if (expression.isEmpty) {
      return _buildEmptyState('No expression provided');
    }

    try {
      // Scaled x-bounds for current zoom/pan
      final initialCenterX = (minX + maxX) / 2;
      final initialRangeX = (maxX - minX).abs();
      final scaledMinX =
          initialCenterX + panOffset.dx - (initialRangeX / (2 * zoomLevel));
      final scaledMaxX =
          initialCenterX + panOffset.dx + (initialRangeX / (2 * zoomLevel));

      final expressions = _expressions;
      if (expressions.isEmpty) {
        return _buildEmptyState('No expression provided');
      }

      // Evaluate every expression; skip those that fail to parse.
      final results = <_EvaluatedExpression>[];
      for (int i = 0; i < expressions.length; i++) {
        try {
          final r = GraphExpressionEvaluator.evaluateLineExpression(
            expressions[i],
            scaledMinX,
            scaledMaxX,
          );
          if (r.spots.isNotEmpty) {
            results.add(_EvaluatedExpression(
              expression: expressions[i],
              result: r,
              color: getEquationColor(i, theme),
            ));
          }
        } catch (e) {
          // Invalid expression – silently skip so other curves still render.
          logger.w('Skipping invalid expression "${expressions[i]}": $e');
        }
      }

      if (results.isEmpty) {
        return _buildEmptyState('No valid points to display');
      }

      // Deliver key-points from the first valid expression.
      final keyPoints =
          GraphExpressionEvaluator.calculateKeyPoints(results.first.result.spots);
      if (onKeyPointsCalculated != null) {
        onKeyPointsCalculated!(keyPoints);
      }

      // Global Y bounds across all expressions.
      double globalMinY = results.first.result.minY;
      double globalMaxY = results.first.result.maxY;
      for (final r in results) {
        if (r.result.minY < globalMinY) globalMinY = r.result.minY;
        if (r.result.maxY > globalMaxY) globalMaxY = r.result.maxY;
      }

      // Guard against flat functions (minY == maxY).
      if (globalMinY == globalMaxY) {
        globalMinY -= 1;
        globalMaxY += 1;
      }

      final paddingY = (globalMaxY - globalMinY) * 0.1;
      final scaledYBounds = GraphUtilities.calculateScaledBounds(
        minValue: globalMinY,
        maxValue: globalMaxY,
        zoomLevel: zoomLevel,
        panOffset: panOffset.dy,
        padding: paddingY / (globalMaxY - globalMinY),
      );

      final hInterval = (scaledYBounds.max - scaledYBounds.min) / 10;
      final vInterval = (scaledMaxX - scaledMinX) / 10;

      final barsData = results
          .map(
            (r) => LineChartBarData(
              spots: r.result.spots,
              isCurved: true,
              color: r.color,
              barWidth: kMultiEquationLineWidth,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          )
          .toList();

      final chart = LineChart(
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
          minY: scaledYBounds.min,
          maxY: scaledYBounds.max,
          lineBarsData: barsData,
          extraLinesData: showIntercepts
              ? GraphUtilities.buildInterceptLines(
                  theme,
                  yIntercept: keyPoints.yIntercept,
                  xIntercepts: keyPoints.xIntercepts,
                  vertex: keyPoints.vertex,
                )
              : null,
          lineTouchData: LineTouchData(
            touchTooltipData: GraphUtilities.buildLineTouchTooltip(theme),
          ),
        ),
      );

      // Show a compact legend only when plotting multiple equations.
      if (results.length <= 1) return chart;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: chart),
          const SizedBox(height: 6),
          _buildLegend(results),
        ],
      );
    } catch (e, stackTrace) {
      logger.e('Error generating line graph', error: e, stackTrace: stackTrace);
      return _buildEmptyState('Error generating graph');
    }
  }

  /// Compact horizontal legend row listing each expression with its colour.
  Widget _buildLegend(List<_EvaluatedExpression> results) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: results.asMap().entries.map((entry) {
          final idx = entry.key;
          final r = entry.value;
          return Padding(
            padding: EdgeInsets.only(left: idx == 0 ? 0 : 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 3,
                  decoration: BoxDecoration(
                    color: r.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  r.expression,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                    fontFamily: 'RobotoMono',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
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

// ---------------------------------------------------------------------------
// Internal data holder
// ---------------------------------------------------------------------------

class _EvaluatedExpression {
  final String expression;
  final GraphEvaluationResult result;
  final Color color;

  const _EvaluatedExpression({
    required this.expression,
    required this.result,
    required this.color,
  });
}
