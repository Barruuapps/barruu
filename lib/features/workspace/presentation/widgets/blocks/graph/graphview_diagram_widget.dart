import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

/// A widget for creating interactive node-based diagrams
/// Supports flowcharts, mind maps, organization charts, and more
class GraphViewDiagramWidget extends StatefulWidget {
  final List<Map<String, dynamic>> nodes;
  final List<Map<String, dynamic>> edges;
  final String diagramType;
  final String layoutType;
  final ThemeData theme;

  const GraphViewDiagramWidget({
    required this.nodes,
    required this.edges,
    required this.diagramType,
    required this.layoutType,
    required this.theme,
    super.key,
  });

  @override
  State<GraphViewDiagramWidget> createState() => _GraphViewDiagramWidgetState();
}

class _GraphViewDiagramWidgetState extends State<GraphViewDiagramWidget> {
  static const double _mobileSpacingMultiplier = 0.5;
  static const double _desktopSpacingMultiplier = 1.0;

  final Graph graph = Graph();
  late BuchheimWalkerConfiguration builder;

  @override
  void initState() {
    super.initState();
    _initializeGraph();
    // Initialize with default (desktop) spacing, will be reconfigured in first build
    _configureLayout(false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reconfigure with actual screen size once dependencies are available
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    _configureLayout(isMobile);
  }

  void _initializeGraph() {
    // Clear existing nodes and edges (graphview doesn't have clear method)
    // We'll recreate the graph if needed

    // Add nodes
    final nodeMap = <String, Node>{};
    for (var nodeData in widget.nodes) {
      final id = nodeData['id']?.toString() ?? '';
      final node = Node.Id(id);
      nodeMap[id] = node;
      graph.addNode(node);
    }

    // Add edges
    for (var edgeData in widget.edges) {
      final from = edgeData['from']?.toString() ?? '';
      final to = edgeData['to']?.toString() ?? '';

      if (nodeMap.containsKey(from) && nodeMap.containsKey(to)) {
        graph.addEdge(nodeMap[from]!, nodeMap[to]!);
      }
    }
  }

  void _configureLayout(bool isMobile) {
    final orientation = _getOrientation(isMobile);
    builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = orientation.siblingSeparation
      ..levelSeparation = orientation.levelSeparation
      ..subtreeSeparation = orientation.subtreeSeparation
      ..orientation = orientation.orientation;
  }

  BuchheimWalkerConfiguration _getOrientation(bool isMobile) {
    // Responsive layout adjustments based on screen size
    // Mobile uses 0.5x multiplier = 50% of original spacing (half the distance)
    final spacingMultiplier = isMobile
        ? _mobileSpacingMultiplier
        : _desktopSpacingMultiplier;

    switch (widget.diagramType) {
      case 'orgChart':
        return BuchheimWalkerConfiguration()
          ..siblingSeparation = (80 * spacingMultiplier).toInt()
          ..levelSeparation = (80 * spacingMultiplier).toInt()
          ..subtreeSeparation = (80 * spacingMultiplier).toInt()
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
      case 'tree':
        return BuchheimWalkerConfiguration()
          ..siblingSeparation = (60 * spacingMultiplier).toInt()
          ..levelSeparation = (60 * spacingMultiplier).toInt()
          ..subtreeSeparation = (60 * spacingMultiplier).toInt()
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
      case 'mindMap':
        // Mind maps use hierarchical layout with increased spacing for better readability
        // The top-bottom orientation helps show the main idea branching into concepts
        return BuchheimWalkerConfiguration()
          ..siblingSeparation = (100 * spacingMultiplier).toInt()
          ..levelSeparation = (100 * spacingMultiplier).toInt()
          ..subtreeSeparation = (100 * spacingMultiplier).toInt()
          ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
      case 'network':
        // Network diagrams need more space for interconnected nodes
        return BuchheimWalkerConfiguration()
          ..siblingSeparation = (120 * spacingMultiplier).toInt()
          ..levelSeparation = (80 * spacingMultiplier).toInt()
          ..subtreeSeparation = (120 * spacingMultiplier).toInt()
          ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;
      case 'flowchart':
        // Flowcharts work well with left-to-right or top-to-bottom
        return BuchheimWalkerConfiguration()
          ..siblingSeparation = (70 * spacingMultiplier).toInt()
          ..levelSeparation = (70 * spacingMultiplier).toInt()
          ..subtreeSeparation = (70 * spacingMultiplier).toInt()
          ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;
      default:
        return BuchheimWalkerConfiguration()
          ..siblingSeparation = (50 * spacingMultiplier).toInt()
          ..levelSeparation = (50 * spacingMultiplier).toInt()
          ..subtreeSeparation = (50 * spacingMultiplier).toInt()
          ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.nodes.isEmpty) {
      return _buildEmptyState(
        'No nodes to display. Add nodes to create your diagram.',
      );
    }

    final algorithm = _getLayoutAlgorithm();

    // Responsive boundary margins
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    final boundaryMargin = isMobile ? 50.0 : 100.0;
    final minScale = isMobile ? 0.2 : 0.1;
    final maxScale = isMobile ? 3.0 : 2.0;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: EdgeInsets.all(boundaryMargin),
      minScale: minScale,
      maxScale: maxScale,
      child: GraphView(
        graph: graph,
        algorithm: algorithm,
        paint: Paint()
          ..color = widget.theme.colorScheme.primary
          ..strokeWidth = isMobile ? 1.5 : 2
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          return _buildNodeWidget(node);
        },
      ),
    );
  }

  Algorithm _getLayoutAlgorithm() {
    // Mind maps and network diagrams benefit from circular/force-directed layouts
    if (widget.diagramType == 'mindMap' || widget.diagramType == 'network') {
      // Use circular layout type for better visualization
      if (widget.layoutType == 'hierarchical') {
        // For hierarchical mindmaps, still use tree layout but with appropriate spacing
        return BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder));
      } else {
        // Default to force-directed layout for better node distribution
        return FruchtermanReingoldAlgorithm(FruchtermanReingoldConfiguration());
      }
    }

    // For other diagram types, respect the layoutType setting
    switch (widget.layoutType) {
      case 'hierarchical':
        return BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder));
      case 'circular':
        return FruchtermanReingoldAlgorithm(FruchtermanReingoldConfiguration());
      default:
        return BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder));
    }
  }

  Widget _buildNodeWidget(Node node) {
    final nodeId = node.key?.value?.toString() ?? '';
    final nodeData = widget.nodes.firstWhere(
      (n) => n['id']?.toString() == nodeId,
      orElse: () => {'label': nodeId},
    );

    final label = nodeData['label']?.toString() ?? nodeId;
    final color = _getNodeColor(nodeData['type']?.toString() ?? 'default');

    // Responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 600;
    final horizontalPadding = isMobile ? 12.0 : 16.0;
    final verticalPadding = isMobile ? 8.0 : 12.0;
    final fontSize = isMobile ? 12.0 : 14.0;
    final borderRadius = isMobile ? 8.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.6)],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: color, width: isMobile ? 1.5 : 2),
      ),
      child: Text(
        label,
        style: widget.theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getNodeColor(String type) {
    switch (type) {
      case 'start':
        return Colors.green;
      case 'end':
        return Colors.red;
      case 'decision':
        return Colors.orange;
      case 'process':
        return Colors.blue;
      case 'data':
        return Colors.purple;
      default:
        return widget.theme.colorScheme.primary;
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: widget.theme.textTheme.bodyMedium?.copyWith(
            color: widget.theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
