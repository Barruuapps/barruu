import 'package:flutter/material.dart';

/// A bulk editor for diagram nodes and edges
/// Allows users to paste node/edge data in a simple text format
class DiagramBulkEditor extends StatefulWidget {
  final List<Map<String, dynamic>> nodes;
  final List<Map<String, dynamic>> edges;
  final ThemeData theme;
  final Function(List<Map<String, dynamic>> nodes, List<Map<String, dynamic>> edges) onDataChanged;

  const DiagramBulkEditor({
    required this.nodes,
    required this.edges,
    required this.theme,
    required this.onDataChanged,
    super.key,
  });

  @override
  State<DiagramBulkEditor> createState() => _DiagramBulkEditorState();
}

class _DiagramBulkEditorState extends State<DiagramBulkEditor> {
  final TextEditingController _dataController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data
    _initializeController();
  }

  void _initializeController() {
    // Convert nodes and edges to compact format
    // Format: nodeId connections label
    // Example: 1 2 3 Main Idea (node 1 connects to 2,3 and has label "Main Idea")
    final Map<String, List<String>> nodeConnections = {};
    final Map<String, String> nodeLabels = {};
    
    // Build connections map
    for (var edge in widget.edges) {
      final from = edge['from']?.toString() ?? '';
      final to = edge['to']?.toString() ?? '';
      if (from.isNotEmpty && to.isNotEmpty) {
        nodeConnections.putIfAbsent(from, () => []).add(to);
      }
    }
    
    // Build labels map
    for (var node in widget.nodes) {
      final id = node['id']?.toString() ?? '';
      final label = node['label']?.toString() ?? '';
      if (id.isNotEmpty) {
        nodeLabels[id] = label;
      }
    }
    
    // Generate compact format - include all nodes
    final lines = <String>[];
    final allNodeIds = {...nodeLabels.keys, ...nodeConnections.keys};
    
    for (var nodeId in allNodeIds) {
      final connections = nodeConnections[nodeId] ?? [];
      final label = nodeLabels[nodeId] ?? '';
      
      // Always add the node, even if it has no connections
      if (connections.isNotEmpty && label.isNotEmpty) {
        lines.add('$nodeId ${connections.join(' ')} $label');
      } else if (connections.isNotEmpty) {
        lines.add('$nodeId ${connections.join(' ')}');
      } else if (label.isNotEmpty && label != 'Node $nodeId') {
        // Isolated node with custom label
        lines.add('$nodeId $label');
      } else {
        // Isolated node without connections or custom label
        lines.add(nodeId);
      }
    }
    
    _dataController.text = lines.join('\n');
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  void _parseAndUpdate() {
    final result = _parseCompactFormat(_dataController.text);
    widget.onDataChanged(result['nodes'], result['edges']);
  }

  Map<String, dynamic> _parseCompactFormat(String text) {
    final nodes = <Map<String, dynamic>>[];
    final edges = <Map<String, dynamic>>[];
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final seenNodes = <String>{};

    for (var line in lines) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty) continue;

      final nodeId = parts[0];
      
      // Find where the label starts (parts that don't look like node IDs after the first part)
      var labelStartIndex = 1;
      final connections = <String>[];
      
      // Parse connections (parts after node ID that look like valid node IDs)
      // Valid node IDs can be numeric or alphanumeric
      for (var i = 1; i < parts.length; i++) {
        // Check if this could be a connection (simple alphanumeric or number)
        if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(parts[i]) && 
            parts[i].length <= 10) { // reasonable ID length limit
          // Could be a connection, but also check if next parts suggest this is the start of label
          if (i < parts.length - 1) {
            connections.add(parts[i]);
            labelStartIndex = i + 1;
          } else {
            // Last part - could be connection or label
            // Short alphanumeric (≤4 chars) or pure numeric likely to be ID
            const maxIdLength = 4;
            if (parts[i].length <= maxIdLength || RegExp(r'^[0-9]+$').hasMatch(parts[i])) {
              connections.add(parts[i]);
              labelStartIndex = i + 1;
            } else {
              // Longer text likely a label
              break;
            }
          }
        } else {
          break;
        }
      }
      
      // Remaining parts form the label
      final label = labelStartIndex < parts.length 
          ? parts.sublist(labelStartIndex).join(' ')
          : '';
      
      // Use a meaningful default label if none provided
      final finalLabel = label.isEmpty ? 'Node $nodeId' : label;
      
      // Add node if not seen
      if (!seenNodes.contains(nodeId)) {
        nodes.add({
          'id': nodeId,
          'label': finalLabel,
          'type': 'default',
        });
        seenNodes.add(nodeId);
      }
      
      // Add edges
      for (var targetId in connections) {
        edges.add({
          'from': nodeId,
          'to': targetId,
        });
        
        // Add target node if not seen (with default label)
        if (!seenNodes.contains(targetId)) {
          nodes.add({
            'id': targetId,
            'label': 'Node $targetId',
            'type': 'default',
          });
          seenNodes.add(targetId);
        }
      }
    }

    return {'nodes': nodes, 'edges': edges};
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final containerPadding = isWide ? 12.0 : 8.0;
    final borderRadius = isWide ? 8.0 : 6.0;
    
    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: widget.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: widget.theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _dataController,
            maxLines: isWide ? 10 : 8,
            style: widget.theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: isWide ? 13 : 12,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isWide ? 8 : 6),
              ),
              hintText: '1 2 3 Main\nA B C Team',
              hintStyle: TextStyle(fontSize: isWide ? 13 : 12),
              contentPadding: EdgeInsets.all(isWide ? 10 : 8),
            ),
            onChanged: (_) => _parseAndUpdate(),
          ),
        ],
      ),
    );
  }
}
