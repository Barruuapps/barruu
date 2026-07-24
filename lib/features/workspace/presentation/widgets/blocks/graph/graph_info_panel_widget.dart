import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A widget that displays analysis information about a graphed function.
///
/// This panel shows:
/// - Y-intercept (where x = 0)
/// - X-intercepts (where y = 0)
/// - Critical points (vertices/extrema)
/// - Domain range
/// - Current zoom level
///
/// Example usage:
/// ```dart
/// GraphInfoPanelWidget(
///   yIntercept: FlSpot(0, 5),
///   xIntercepts: [FlSpot(-2, 0), FlSpot(3, 0)],
///   vertex: FlSpot(0.5, 6.25),
///   minX: -10,
///   maxX: 10,
///   zoomLevel: 1.5,
///   formatNumber: (value) => value.toStringAsFixed(2),
/// )
/// ```
class GraphInfoPanelWidget extends StatelessWidget {
  /// The y-intercept point (where x = 0), or null if not found
  final FlSpot? yIntercept;
  
  /// List of x-intercept points (where y = 0)
  final List<FlSpot> xIntercepts;
  
  /// The critical point (vertex/extremum), or null if not found
  final FlSpot? vertex;
  
  /// Minimum x value in the visible domain
  final double minX;
  
  /// Maximum x value in the visible domain
  final double maxX;
  
  /// Current zoom level (1.0 = 100%)
  final double zoomLevel;
  
  /// Function to format numbers for display
  final String Function(double) formatNumber;

  const GraphInfoPanelWidget({
    required this.yIntercept,
    required this.xIntercepts,
    required this.vertex,
    required this.minX,
    required this.maxX,
    required this.zoomLevel,
    required this.formatNumber,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.analytics, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Function Analysis',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Y-intercept
          if (yIntercept != null)
            _buildInfoRow(
              'Y-Intercept:',
              '(0, ${formatNumber(yIntercept!.y)})',
              theme,
              color: Colors.green,
            ),
          
          // X-intercepts
          if (xIntercepts.isNotEmpty)
            ...xIntercepts.asMap().entries.map((entry) {
              final index = entry.key;
              final intercept = entry.value;
              return _buildInfoRow(
                'X-Intercept ${xIntercepts.length > 1 ? '${index + 1}' : ''}:',
                '(${formatNumber(intercept.x)}, 0)',
                theme,
                color: Colors.red,
              );
            }),
          
          // Critical point/vertex
          if (vertex != null)
            _buildInfoRow(
              'Critical Point:',
              '(${formatNumber(vertex!.x)}, ${formatNumber(vertex!.y)})',
              theme,
              color: Colors.blue,
            ),
          
          // Empty state message
          if (yIntercept == null && xIntercepts.isEmpty && vertex == null)
            Text(
              'No key points found in visible range',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          
          const SizedBox(height: 8),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          
          // Domain
          _buildInfoRow(
            'Domain:',
            '[${formatNumber(minX)}, ${formatNumber(maxX)}]',
            theme,
          ),
          
          // Zoom level
          _buildInfoRow(
            'Zoom:',
            '${(zoomLevel * 100).toStringAsFixed(0)}%',
            theme,
          ),
        ],
      ),
    );
  }

  /// Builds a single row of information with optional color indicator.
  Widget _buildInfoRow(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Color indicator for intercepts/vertex
          if (color != null)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          // Label
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          // Value
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontFamily: 'RobotoMono',
            ),
          ),
        ],
      ),
    );
  }
}
