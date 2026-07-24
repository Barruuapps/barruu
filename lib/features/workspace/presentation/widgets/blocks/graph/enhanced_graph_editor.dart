import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/features/workspace/presentation/dialogs/graph_type_selector_dialog.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/inline_chart_data_editor.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/diagram_bulk_editor.dart';

/// Editor widget for enhanced graph types (Syncfusion charts and GraphView diagrams)
class EnhancedGraphEditor extends StatelessWidget {
  final Map<String, dynamic> content;
  final ThemeData theme;
  final Function(Map<String, dynamic>) onContentChanged;

  const EnhancedGraphEditor({
    required this.content,
    required this.theme,
    required this.onContentChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final typeString = content['type']?.toString() ?? '';
    final enhancedType = _getEnhancedGraphType(typeString);
    
    if (enhancedType == null) {
      return _buildErrorWidget('Unknown graph type');
    }

    // Mobile-friendly spacing
    final isWide = MediaQuery.of(context).size.width > 600;
    final containerPadding = isWide ? 16.0 : 12.0;
    final borderRadius = isWide ? 12.0 : 8.0;
    
    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type indicator
          _buildTypeHeader(context, enhancedType, isWide),
          SizedBox(height: isWide ? 16 : 12),
          
          // Editor based on category
          if (enhancedType.category == GraphCategory.business)
            _buildBusinessChartEditor(context, enhancedType, isWide)
          else if (enhancedType.category == GraphCategory.diagram)
            _buildDiagramEditor(context, enhancedType)
          else
            _buildLegacyEditor(),
        ],
      ),
    );
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

  Widget _buildTypeHeader(BuildContext context, EnhancedGraphType type, bool isWide) {
    final categoryColor = type.category.getColor(context);
    final iconSize = isWide ? 24.0 : 20.0;
    final horizontalPadding = isWide ? 8.0 : 6.0;
    
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(horizontalPadding),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            type.icon,
            color: categoryColor,
            size: iconSize,
          ),
        ),
        SizedBox(width: isWide ? 12 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isWide ? null : 14,
                ),
              ),
              Text(
                type.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: isWide ? null : 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessChartEditor(BuildContext context, EnhancedGraphType type, bool isWide) {
    final data = (content['data'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final title = content['title']?.toString() ?? '';
    final xAxisLabel = content['xAxisLabel']?.toString() ?? 'X Axis';
    final yAxisLabel = content['yAxisLabel']?.toString() ?? 'Y Axis';
    final showLegend = content['showLegend'] as bool? ?? true;
    final showDataLabels = content['showDataLabels'] as bool? ?? false;

    // Mobile-friendly spacing
    final verticalSpacing = isWide ? 12.0 : 8.0;
    final borderRadius = isWide ? 8.0 : 6.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title input
        TextFormField(
          initialValue: title,
          decoration: InputDecoration(
            labelText: 'Chart Title',
            hintText: 'Enter chart title',
            prefixIcon: const Icon(IconsaxPlusLinear.text),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isWide ? 12 : 8,
              vertical: isWide ? 12 : 10,
            ),
          ),
          style: TextStyle(fontSize: isWide ? 14 : 13),
          onChanged: (value) {
            content['title'] = value;
            onContentChanged(content);
          },
        ),
        SizedBox(height: verticalSpacing),
        
        // Axis labels - stacked on mobile for better space usage
        if (isWide)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: xAxisLabel,
                  decoration: InputDecoration(
                    labelText: 'X Axis Label',
                    hintText: 'X Axis',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (value) {
                    content['xAxisLabel'] = value;
                    onContentChanged(content);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: yAxisLabel,
                  decoration: InputDecoration(
                    labelText: 'Y Axis Label',
                    hintText: 'Y Axis',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (value) {
                    content['yAxisLabel'] = value;
                    onContentChanged(content);
                  },
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              TextFormField(
                initialValue: xAxisLabel,
                decoration: InputDecoration(
                  labelText: 'X Axis Label',
                  hintText: 'X Axis',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (value) {
                  content['xAxisLabel'] = value;
                  onContentChanged(content);
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: yAxisLabel,
                decoration: InputDecoration(
                  labelText: 'Y Axis Label',
                  hintText: 'Y Axis',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (value) {
                  content['yAxisLabel'] = value;
                  onContentChanged(content);
                },
              ),
            ],
          ),
        SizedBox(height: verticalSpacing),
        
        // Options - more compact on mobile
        if (isWide)
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Show Legend'),
                  value: showLegend,
                  onChanged: (value) {
                    content['showLegend'] = value ?? true;
                    onContentChanged(content);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Show Labels'),
                  value: showDataLabels,
                  onChanged: (value) {
                    content['showDataLabels'] = value ?? false;
                    onContentChanged(content);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              CheckboxListTile(
                title: const Text('Show Legend', style: TextStyle(fontSize: 13)),
                value: showLegend,
                onChanged: (value) {
                  content['showLegend'] = value ?? true;
                  onContentChanged(content);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              CheckboxListTile(
                title: const Text('Show Labels', style: TextStyle(fontSize: 13)),
                value: showDataLabels,
                onChanged: (value) {
                  content['showDataLabels'] = value ?? false;
                  onContentChanged(content);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
        SizedBox(height: verticalSpacing),
        
        // Sample data button for empty charts - compact
        if (data.isEmpty)
          ElevatedButton.icon(
            onPressed: () {
              _addSampleChartData(type);
              onContentChanged(content);
            },
            icon: Icon(IconsaxPlusLinear.chart, size: isWide ? 18 : 16),
            label: Text('Sample', style: TextStyle(fontSize: isWide ? 14 : 13)),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 16 : 12,
                vertical: isWide ? 8 : 6,
              ),
            ),
          ),
        SizedBox(height: isWide ? 12 : 8),
        
        // Inline data editor
        InlineChartDataEditor(
          initialData: data,
          onDataChanged: (newData) {
            content['data'] = newData;
            onContentChanged(content);
          },
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildDiagramEditor(BuildContext context, EnhancedGraphType type) {
    // Use a stateful wrapper to handle bulk edit toggle
    return _DiagramEditorWithBulkImport(
      content: content,
      type: type,
      theme: theme,
      onContentChanged: onContentChanged,
    );
  }

  void _addSampleChartData(EnhancedGraphType type) {
    // Create appropriate sample data based on chart type
    switch (type) {
      case EnhancedGraphType.sfPie:
      case EnhancedGraphType.sfDoughnut:
        // Pie/Doughnut charts show proportional data
        content['data'] = [
          {'x': 'Product A', 'y': 35.0},
          {'x': 'Product B', 'y': 25.0},
          {'x': 'Product C', 'y': 20.0},
          {'x': 'Product D', 'y': 15.0},
          {'x': 'Others', 'y': 5.0},
        ];
        break;
      case EnhancedGraphType.sfBubble:
        // Bubble charts need x, y, and size values
        // Using numeric x-values for consistency and to avoid parsing issues
        content['data'] = [
          {'x': '10', 'y': 20.0, 'size': 15.0},
          {'x': '20', 'y': 35.0, 'size': 25.0},
          {'x': '30', 'y': 25.0, 'size': 20.0},
          {'x': '40', 'y': 45.0, 'size': 30.0},
          {'x': '50', 'y': 30.0, 'size': 18.0},
        ];
        break;
      case EnhancedGraphType.sfScatter:
        // Scatter plots use numeric x values for correlation analysis
        // String format maintained for consistency with chart data model
        content['data'] = [
          {'x': '5', 'y': 10.0},
          {'x': '15', 'y': 25.0},
          {'x': '25', 'y': 15.0},
          {'x': '35', 'y': 40.0},
          {'x': '45', 'y': 30.0},
        ];
        break;
      default:
        // Line, Bar, Column, Area, Spline, Step Line charts
        content['data'] = [
          {'x': 'Jan', 'y': 20.0},
          {'x': 'Feb', 'y': 35.0},
          {'x': 'Mar', 'y': 25.0},
          {'x': 'Apr', 'y': 45.0},
          {'x': 'May', 'y': 40.0},
          {'x': 'Jun', 'y': 50.0},
        ];
    }
  }

  Widget _buildLegacyEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'This graph type uses the traditional editor',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// Stateful wrapper for diagram editor to support bulk import
class _DiagramEditorWithBulkImport extends StatefulWidget {
  final Map<String, dynamic> content;
  final EnhancedGraphType type;
  final ThemeData theme;
  final Function(Map<String, dynamic>) onContentChanged;

  const _DiagramEditorWithBulkImport({
    required this.content,
    required this.type,
    required this.theme,
    required this.onContentChanged,
  });

  @override
  State<_DiagramEditorWithBulkImport> createState() => _DiagramEditorWithBulkImportState();
}

class _DiagramEditorWithBulkImportState extends State<_DiagramEditorWithBulkImport> {
  bool _showBulkEdit = false;

  @override
  Widget build(BuildContext context) {
    final nodes = (widget.content['nodes'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final edges = (widget.content['edges'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final title = widget.content['title']?.toString() ?? '';
    final layoutType = widget.content['layoutType']?.toString() ?? 'hierarchical';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title input
        TextFormField(
          initialValue: title,
          decoration: InputDecoration(
            labelText: 'Diagram Title',
            hintText: 'Enter diagram title',
            prefixIcon: const Icon(IconsaxPlusLinear.text),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            widget.content['title'] = value;
            widget.onContentChanged(widget.content);
          },
        ),
        const SizedBox(height: 16),
        
        // Layout type selector
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(IconsaxPlusLinear.layer, color: widget.theme.colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Layout:',
                style: widget.theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: layoutType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'hierarchical',
                      child: Text('Hierarchical'),
                    ),
                    DropdownMenuItem(
                      value: 'circular',
                      child: Text('Circular / Force-Directed'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      widget.content['layoutType'] = value;
                      widget.onContentChanged(widget.content);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Diagram stats
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(IconsaxPlusLinear.box, 'Nodes', nodes.length.toString()),
              _buildStatItem(IconsaxPlusLinear.link, 'Connections', edges.length.toString()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Bulk Edit toggle
        if (!_showBulkEdit)
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showBulkEdit = true;
              });
            },
            icon: const Icon(IconsaxPlusLinear.document_upload),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        
        if (!_showBulkEdit) const SizedBox(height: 10),
        
        // Quick add sample (only when not in bulk edit mode)
        if (!_showBulkEdit)
          ElevatedButton.icon(
            onPressed: () {
              _addSampleDiagramData(widget.type);
              widget.onContentChanged(widget.content);
            },
            icon: const Icon(IconsaxPlusLinear.add_circle),
            label: const Text('Sample'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        
        // Bulk editor
        if (_showBulkEdit) ...[
          DiagramBulkEditor(
            nodes: nodes,
            edges: edges,
            theme: widget.theme,
            onDataChanged: (newNodes, newEdges) {
              setState(() {
                widget.content['nodes'] = newNodes;
                widget.content['edges'] = newEdges;
                widget.onContentChanged(widget.content);
              });
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showBulkEdit = false;
              });
            },
            icon: const Icon(IconsaxPlusLinear.close_circle),
            label: const Text('Exit Bulk Edit'),
          ),
        ],
      ],
    );
  }
  
  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: widget.theme.colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: widget.theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: widget.theme.textTheme.bodySmall?.copyWith(
            color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
  
  String _getDiagramHint(EnhancedGraphType type) {
    switch (type) {
      case EnhancedGraphType.mindMap:
        return 'Mind maps show ideas branching from a central concept. Click "Bulk Edit" to add your own nodes.';
      case EnhancedGraphType.network:
        return 'Network diagrams show interconnected systems. Click "Bulk Edit" to customize connections.';
      case EnhancedGraphType.flowchart:
        return 'Flowcharts show process steps. Click "Bulk Edit" to create your process flow.';
      case EnhancedGraphType.orgChart:
        return 'Organization charts show reporting structures. Click "Bulk Edit" to add people and roles.';
      case EnhancedGraphType.tree:
        return 'Tree graphs show hierarchical relationships. Click "Bulk Edit" to build your tree.';
      default:
        return 'Add nodes and connections to visualize your diagram. Click "Bulk Edit" for text-based editing.';
    }
  }
  
  void _addSampleDiagramData(EnhancedGraphType type) {
    switch (type) {
      case EnhancedGraphType.flowchart:
        widget.content['nodes'] = [
          {'id': '1', 'label': 'Start', 'type': 'start'},
          {'id': '2', 'label': 'Process', 'type': 'process'},
          {'id': '3', 'label': 'Decision', 'type': 'decision'},
          {'id': '4', 'label': 'End', 'type': 'end'},
        ];
        widget.content['edges'] = [
          {'from': '1', 'to': '2'},
          {'from': '2', 'to': '3'},
          {'from': '3', 'to': '4'},
        ];
        break;
      case EnhancedGraphType.orgChart:
        widget.content['nodes'] = [
          {'id': '1', 'label': 'CEO', 'type': 'default'},
          {'id': '2', 'label': 'CTO', 'type': 'default'},
          {'id': '3', 'label': 'CFO', 'type': 'default'},
        ];
        widget.content['edges'] = [
          {'from': '1', 'to': '2'},
          {'from': '1', 'to': '3'},
        ];
        break;
      case EnhancedGraphType.mindMap:
        widget.content['nodes'] = [
          {'id': '1', 'label': 'Main Idea', 'type': 'default'},
          {'id': '2', 'label': 'Concept A', 'type': 'data'},
          {'id': '3', 'label': 'Concept B', 'type': 'data'},
          {'id': '4', 'label': 'Detail A1', 'type': 'process'},
          {'id': '5', 'label': 'Detail A2', 'type': 'process'},
          {'id': '6', 'label': 'Detail B1', 'type': 'process'},
        ];
        widget.content['edges'] = [
          {'from': '1', 'to': '2'},
          {'from': '1', 'to': '3'},
          {'from': '2', 'to': '4'},
          {'from': '2', 'to': '5'},
          {'from': '3', 'to': '6'},
        ];
        widget.content['layoutType'] = 'hierarchical';
        break;
      case EnhancedGraphType.network:
        widget.content['nodes'] = [
          {'id': '1', 'label': 'Server', 'type': 'data'},
          {'id': '2', 'label': 'Client A', 'type': 'default'},
          {'id': '3', 'label': 'Client B', 'type': 'default'},
          {'id': '4', 'label': 'Client C', 'type': 'default'},
          {'id': '5', 'label': 'Database', 'type': 'process'},
        ];
        widget.content['edges'] = [
          {'from': '1', 'to': '2'},
          {'from': '1', 'to': '3'},
          {'from': '1', 'to': '4'},
          {'from': '1', 'to': '5'},
          {'from': '2', 'to': '5'},
          {'from': '3', 'to': '5'},
        ];
        widget.content['layoutType'] = 'circular';
        break;
      case EnhancedGraphType.tree:
        widget.content['nodes'] = [
          {'id': '1', 'label': 'Root', 'type': 'default'},
          {'id': '2', 'label': 'Branch A', 'type': 'default'},
          {'id': '3', 'label': 'Branch B', 'type': 'default'},
          {'id': '4', 'label': 'Leaf A1', 'type': 'process'},
          {'id': '5', 'label': 'Leaf B1', 'type': 'process'},
        ];
        widget.content['edges'] = [
          {'from': '1', 'to': '2'},
          {'from': '1', 'to': '3'},
          {'from': '2', 'to': '4'},
          {'from': '3', 'to': '5'},
        ];
        break;
      default:
        widget.content['nodes'] = [
          {'id': '1', 'label': 'Node 1', 'type': 'default'},
          {'id': '2', 'label': 'Node 2', 'type': 'default'},
        ];
        widget.content['edges'] = [
          {'from': '1', 'to': '2'},
        ];
    }
  }
}

