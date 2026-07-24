import 'package:flutter/material.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/presentation/dialogs/graph_type_selector_dialog.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/syncfusion_line_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/syncfusion_bar_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/syncfusion_column_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/syncfusion_pie_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/syncfusion_area_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/syncfusion_spline_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/syncfusion_step_line_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/syncfusion_bubble_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/syncfusion_scatter_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/graphview_diagram_widget.dart';

/// Enhanced graph renderer that supports all graph types
/// including traditional mathematical graphs, Syncfusion charts, and GraphView diagrams
class EnhancedGraphRenderer extends StatelessWidget {
  final Block block;
  final ThemeData theme;

  const EnhancedGraphRenderer({
    required this.block,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final content = JsonStringConverter().convertFromJsonString(block.content);
      final typeString = content['type']?.toString() ?? 'line';
      
      // Check if this is a new enhanced graph type
      final enhancedType = _getEnhancedGraphType(typeString);
      
      if (enhancedType != null) {
        return _renderEnhancedGraph(content, enhancedType);
      }
      
      // Fallback to original graph rendering for backward compatibility
      return _buildLegacyGraphPlaceholder(typeString);
      
    } catch (e) {
      return _buildErrorWidget('Error loading graph: $e');
    }
  }

  EnhancedGraphType? _getEnhancedGraphType(String typeString) {
    try {
      return EnhancedGraphType.values.firstWhere(
        (type) => type.name == typeString,
      );
    } catch (e) {
      return null;
    }
  }

  Widget _renderEnhancedGraph(Map<String, dynamic> content, EnhancedGraphType type) {
    final caption = content['caption']?.toString() ?? '';
    
    Widget chart;
    
    switch (type.category) {
      case GraphCategory.mathematical:
        // Legacy mathematical graphs - will be handled by existing widgets
        chart = _buildLegacyGraphPlaceholder(type.name);
        break;
        
      case GraphCategory.business:
        chart = _renderSyncfusionChart(content, type);
        break;
        
      case GraphCategory.diagram:
        chart = _renderGraphViewDiagram(content, type);
        break;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        // More aggressive height reduction for mobile
        final containerHeight = isWide ? 300.0 : (constraints.maxWidth < 400 ? 220.0 : 250.0);
        final padding = isWide ? 8.0 : 6.0;
        final verticalSpacing = isWide ? 8.0 : 6.0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: containerHeight,
              padding: EdgeInsets.all(padding),
              child: chart,
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(verticalSpacing),
                child: Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: isWide ? 13 : 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _renderSyncfusionChart(Map<String, dynamic> content, EnhancedGraphType type) {
    final data = (content['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final xAxisLabel = content['xAxisLabel']?.toString() ?? 'X Axis';
    final yAxisLabel = content['yAxisLabel']?.toString() ?? 'Y Axis';
    final title = content['title']?.toString() ?? '';
    final showLegend = content['showLegend'] as bool? ?? true;
    final showDataLabels = content['showDataLabels'] as bool? ?? false;
    
    if (data.isEmpty) {
      return _buildDataInputPrompt('Add data points to display the chart');
    }
    
    switch (type) {
      case EnhancedGraphType.sfLine:
        return SyncfusionLineChartWidget(
          data: data,
          xAxisLabel: xAxisLabel,
          yAxisLabel: yAxisLabel,
          title: title,
          showLegend: showLegend,
          showDataLabels: showDataLabels,
          theme: theme,
        );
        
      case EnhancedGraphType.sfSpline:
        return SyncfusionSplineChartWidget(
          data: data,
          xAxisLabel: xAxisLabel,
          yAxisLabel: yAxisLabel,
          title: title,
          showLegend: showLegend,
          showDataLabels: showDataLabels,
          theme: theme,
        );
        
      case EnhancedGraphType.sfStepLine:
        return SyncfusionStepLineChartWidget(
          data: data,
          xAxisLabel: xAxisLabel,
          yAxisLabel: yAxisLabel,
          title: title,
          showLegend: showLegend,
          showDataLabels: showDataLabels,
          theme: theme,
        );
        
      case EnhancedGraphType.sfBar:
        return SyncfusionBarChartWidget(
          data: data,
          xAxisLabel: xAxisLabel,
          yAxisLabel: yAxisLabel,
          title: title,
          showLegend: showLegend,
          showDataLabels: showDataLabels,
          theme: theme,
        );
        
      case EnhancedGraphType.sfColumn:
        return SyncfusionColumnChartWidget(
          data: data,
          xAxisLabel: xAxisLabel,
          yAxisLabel: yAxisLabel,
          title: title,
          showLegend: showLegend,
          showDataLabels: showDataLabels,
          theme: theme,
        );
        
      case EnhancedGraphType.sfArea:
        return SyncfusionAreaChartWidget(
          data: data,
          xAxisLabel: xAxisLabel,
          yAxisLabel: yAxisLabel,
          title: title,
          showLegend: showLegend,
          showDataLabels: showDataLabels,
          theme: theme,
        );
        
      case EnhancedGraphType.sfPie:
        return SyncfusionPieChartWidget(
          data: data,
          title: title,
          showLegend: showLegend,
          showDataLabels: showDataLabels,
          theme: theme,
        );
        
      case EnhancedGraphType.sfDoughnut:
        return SyncfusionPieChartWidget(
          data: data,
          title: title,
          showLegend: showLegend,
          showDataLabels: showDataLabels,
          theme: theme,
          isDoughnut: true,
        );
        
      case EnhancedGraphType.sfBubble:
        return SyncfusionBubbleChartWidget(
          data: data,
          xAxisLabel: xAxisLabel,
          yAxisLabel: yAxisLabel,
          title: title,
          showLegend: showLegend,
          showDataLabels: showDataLabels,
          theme: theme,
        );
        
      case EnhancedGraphType.sfScatter:
        return SyncfusionScatterChartWidget(
          data: data,
          xAxisLabel: xAxisLabel,
          yAxisLabel: yAxisLabel,
          title: title,
          showLegend: showLegend,
          showDataLabels: showDataLabels,
          theme: theme,
        );
        
      default:
        // All chart types are now implemented
        return _buildErrorWidget('Unknown chart type: ${type.displayName}');
    }
  }

  Widget _renderGraphViewDiagram(Map<String, dynamic> content, EnhancedGraphType type) {
    final nodes = (content['nodes'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final edges = (content['edges'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final layoutType = content['layoutType']?.toString() ?? 'hierarchical';
    
    if (nodes.isEmpty) {
      return _buildDataInputPrompt('Add nodes and connections to create your diagram');
    }
    
    return GraphViewDiagramWidget(
      nodes: nodes,
      edges: edges,
      diagramType: type.name,
      layoutType: layoutType,
      theme: theme,
    );
  }

  Widget _buildLegacyGraphPlaceholder(String type) {
    // Return null to indicate that the legacy graph renderer should be used
    // This is just a placeholder - the actual rendering is handled by GraphReaderBlock
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Use the edit mode to configure this mathematical graph',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDataInputPrompt(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_chart,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap edit to add data',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          error,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
