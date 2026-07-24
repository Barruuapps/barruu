import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Width (in logical pixels) of each plotted curve.  Slightly thinner than a
/// typical single-curve width of 3 to keep multi-curve charts readable.
const double kMultiEquationLineWidth = 2.5;

/// Ordered list of distinct colors used to differentiate multiple equation
/// lines on the same graph.  Index 0 is intentionally unset here – the
/// caller should substitute the theme's primary colour for the first curve.
const List<Color> kEquationColors = [
  Color(0xFF2196F3), // blue  – used as fallback for index 0
  Color(0xFFF44336), // red
  Color(0xFF4CAF50), // green
  Color(0xFFFF9800), // orange
  Color(0xFF9C27B0), // purple
  Color(0xFF00BCD4), // cyan
];

/// Returns the display colour for the equation at [index].
/// The first equation always uses the theme's primary colour.
Color getEquationColor(int index, ThemeData theme) {
  if (index == 0) return theme.colorScheme.primary;
  return kEquationColors[index % kEquationColors.length];
}

/// Utility functions for graph rendering
/// 
/// This service provides common utilities for creating graph components
/// such as grid lines, axis titles, intercept markers, and number formatting.
class GraphUtilities {
  /// Formats a number for display on graph axes
  /// 
  /// Applies different formatting based on magnitude:
  /// - Large numbers (>= 1M): Shows as "1.5M"
  /// - Medium numbers (>= 1k): Shows as "2.3k"
  /// - Small numbers (< 0.01): Shows with 3 decimal places
  /// - Regular numbers: Shows with 2 decimal places
  /// - Zero: Shows as "0"
  static String formatNumber(double value) {
    if (value == 0) return '0';
    final absValue = value.abs();
    if (absValue >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(1)}M';
    } else if (absValue >= 1e3) {
      return '${(value / 1e3).toStringAsFixed(1)}k';
    } else if (absValue < 0.01) {
      return value.toStringAsFixed(3);
    } else {
      return value.toStringAsFixed(2);
    }
  }

  /// Builds grid data for a chart with customizable intervals
  /// 
  /// Parameters:
  /// - [theme]: The app theme for color selection
  /// - [horizontalInterval]: Spacing between horizontal grid lines
  /// - [verticalInterval]: Spacing between vertical grid lines
  /// 
  /// Returns configured [FlGridData] with styled grid lines and axes
  static FlGridData buildGridData(
    ThemeData theme,
    double horizontalInterval,
    double verticalInterval,
  ) {
    final gridColor = theme.colorScheme.primary.withValues(alpha: 0.5);
    final axisColor = theme.colorScheme.onSurface.withValues(alpha: 0.9);

    return FlGridData(
      horizontalInterval: horizontalInterval,
      verticalInterval: verticalInterval,
      getDrawingHorizontalLine: (value) {
        final isAxis = (value - 0).abs() < 1e-10;
        return FlLine(
          color: isAxis ? axisColor : gridColor,
          strokeWidth: isAxis ? 2.0 : 1.0,
          dashArray: isAxis ? null : [6, 4],
        );
      },
      getDrawingVerticalLine: (value) {
        final isAxis = (value - 0).abs() < 1e-10;
        return FlLine(
          color: isAxis ? axisColor : gridColor,
          strokeWidth: isAxis ? 2.0 : 1.0,
          dashArray: isAxis ? null : [6, 4],
        );
      },
    );
  }

  /// Builds axis titles configuration for a chart
  /// 
  /// Parameters:
  /// - [theme]: The app theme for styling
  /// - [formatNumber]: Optional custom number formatting function
  /// 
  /// Returns configured [FlTitlesData] for all four axes
  static FlTitlesData buildTitlesData(
    ThemeData theme, {
    String Function(double)? formatNumber,
  }) {
    final formatter = formatNumber ?? GraphUtilities.formatNumber;
    
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              formatter(value),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 10,
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                formatter(value),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 10,
                ),
              ),
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(),
      topTitles: const AxisTitles(),
    );
  }

  /// Builds visual markers for intercepts and critical points
  /// 
  /// Parameters:
  /// - [theme]: The app theme for color selection
  /// - [yIntercept]: Y-intercept point (where x = 0)
  /// - [xIntercepts]: List of x-intercept points (where y = 0)
  /// - [vertex]: Vertex or critical point
  /// - [formatNumber]: Optional custom number formatting function
  /// 
  /// Returns [ExtraLinesData] with colored markers for key points
  static ExtraLinesData buildInterceptLines(
    ThemeData theme, {
    FlSpot? yIntercept,
    List<FlSpot>? xIntercepts,
    FlSpot? vertex,
    String Function(double)? formatNumber,
  }) {
    final formatter = formatNumber ?? GraphUtilities.formatNumber;
    final horizontalLines = <HorizontalLine>[];
    final verticalLines = <VerticalLine>[];
    
    // Mark y-intercept
    if (yIntercept != null) {
      verticalLines.add(
        VerticalLine(
          x: 0,
          color: Colors.green.withValues(alpha: 0.3),
          dashArray: [8, 4],
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            labelResolver: (line) => 'y=${formatter(yIntercept.y)}',
          ),
        ),
      );
    }
    
    // Mark x-intercepts
    if (xIntercepts != null) {
      for (final intercept in xIntercepts) {
        verticalLines.add(
          VerticalLine(
            x: intercept.x,
            color: Colors.red.withValues(alpha: 0.3),
            dashArray: [8, 4],
            label: VerticalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              labelResolver: (line) => 'x=${formatter(intercept.x)}',
            ),
          ),
        );
      }
    }
    
    // Mark vertex/critical point
    if (vertex != null) {
      horizontalLines.add(
        HorizontalLine(
          y: vertex.y,
          color: Colors.blue.withValues(alpha: 0.3),
          dashArray: [8, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.blue,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            labelResolver: (line) => 'Critical',
          ),
        ),
      );
    }
    
    return ExtraLinesData(
      horizontalLines: horizontalLines,
      verticalLines: verticalLines,
    );
  }

  /// Calculates scaled bounds for zoom and pan functionality
  /// 
  /// Parameters:
  /// - [minValue]: Minimum value of the range
  /// - [maxValue]: Maximum value of the range
  /// - [zoomLevel]: Current zoom level (1.0 = normal, >1.0 = zoomed in)
  /// - [panOffset]: Pan offset in the direction
  /// - [padding]: Additional padding as a fraction of range (default: 0.1)
  /// 
  /// Returns a [ScaledBounds] object with calculated min and max
  static ScaledBounds calculateScaledBounds({
    required double minValue,
    required double maxValue,
    required double zoomLevel,
    required double panOffset,
    double padding = 0.1,
  }) {
    final center = (minValue + maxValue) / 2;
    final range = (maxValue - minValue).abs() + 2 * ((maxValue - minValue) * padding);
    final scaledMin = center + panOffset - (range / (2 * zoomLevel));
    final scaledMax = center + panOffset + (range / (2 * zoomLevel));
    
    return ScaledBounds(min: scaledMin, max: scaledMax);
  }

  /// Creates a standard touch tooltip configuration for line charts
  /// 
  /// Parameters:
  /// - [theme]: The app theme for styling
  /// - [formatNumber]: Optional custom number formatting function
  /// 
  /// Returns configured [LineTouchTooltipData]
  static LineTouchTooltipData buildLineTouchTooltip(
    ThemeData theme, {
    String Function(double)? formatNumber,
  }) {
    final formatter = formatNumber ?? GraphUtilities.formatNumber;
    
    return LineTouchTooltipData(
      getTooltipColor: (_) => theme.colorScheme.surface.withValues(alpha: 0.9),
      tooltipBorderRadius: BorderRadius.circular(8),
      getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
        return LineTooltipItem(
          '(${formatter(spot.x)}, ${formatter(spot.y)})',
          theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurface),
        );
      }).toList(),
    );
  }

  /// Creates a standard touch tooltip configuration for bar charts
  /// 
  /// Parameters:
  /// - [theme]: The app theme for styling
  /// - [formatNumber]: Optional custom number formatting function
  /// 
  /// Returns configured [BarTouchTooltipData]
  static BarTouchTooltipData buildBarTouchTooltip(
    ThemeData theme, {
    String Function(double)? formatNumber,
  }) {
    final formatter = formatNumber ?? GraphUtilities.formatNumber;
    
    return BarTouchTooltipData(
      getTooltipColor: (_) => theme.colorScheme.surface.withValues(alpha: 0.9),
      tooltipBorderRadius: BorderRadius.circular(8),
      getTooltipItem: (group, groupIndex, rod, rodIndex) {
        return BarTooltipItem(
          'Value: ${formatter(rod.toY)}',
          theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurface),
        );
      },
    );
  }
}

/// Represents calculated bounds after scaling for zoom/pan
class ScaledBounds {
  /// Minimum value after scaling
  final double min;
  
  /// Maximum value after scaling
  final double max;

  const ScaledBounds({required this.min, required this.max});
}
