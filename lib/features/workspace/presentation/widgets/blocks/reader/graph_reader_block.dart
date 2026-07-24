import 'package:barruu/core/utils/app_logger.dart';

import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/utils/latex_expression_formatter.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/graph_controls_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/graph_info_panel_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/graph_line_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/graph_parametric_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/graph_polar_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/graph_bar_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/graph_scatter_chart_widget.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/graph/enhanced_graph_renderer.dart';
import 'package:barruu/features/workspace/presentation/services/graph_expression_evaluator.dart';
import 'package:barruu/features/workspace/presentation/services/graph_utilities.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';

enum GraphType { line, parametric, polar, bar, scatter }

/// Legacy graph type names that use the original mathematical graph renderer
const Set<String> kLegacyGraphTypes = {
  'line',
  'parametric',
  'polar',
  'bar',
  'scatter',
};

class GraphReaderBlock extends ConsumerStatefulWidget {
  final Block block;

  const GraphReaderBlock({super.key, required this.block});

  @override
  ConsumerState<GraphReaderBlock> createState() => _GraphReaderBlockState();
}

class _GraphReaderBlockState extends ConsumerState<GraphReaderBlock>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> content = {
    'type': 'line',
    'expression': '',
    'caption': '',
    'min_x': '-10',
    'max_x': '10',
    'color_scheme': 'default',
  };

  GraphType _graphType = GraphType.line;
  bool _isLoading = true;
  String _errorMessage = '';
  double _zoomLevel = 1.0;
  double _minX = -10;
  double _maxX = 10;
  Offset _panOffset = Offset.zero;
  late AnimationController _animationController;

  // Feature toggles
  bool _showIntercepts = true;
  bool _showGrid = true;
  bool _showInfoPanel = false;

  // Calculated values
  final List<FlSpot> _xIntercepts = [];
  FlSpot? _yIntercept;
  FlSpot? _vertex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeContent();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeContent() async {
    try {
      if (widget.block.content.isNotEmpty) {
        content = JsonStringConverter().convertFromJsonString(
          widget.block.content,
        );
        _graphType = _getGraphTypeFromString(content['type'] ?? 'line');
        _minX = double.tryParse(content['min_x']?.trim() ?? '-10') ?? -10;
        _maxX = double.tryParse(content['max_x']?.trim() ?? '10') ?? 10;
        if (_minX >= _maxX) {
          throw Exception('Invalid range: minX must be less than maxX');
        }
        _panOffset = Offset.zero;
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse graph content',
        error: e,
        stackTrace: stackTrace,
      );
      _errorMessage = 'Failed to load graph. Please check your inputs.';
    }
    setState(() => _isLoading = false);
  }

  GraphType _getGraphTypeFromString(String type) {
    return GraphType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => GraphType.line,
    );
  }

  /// Updates key points from calculated graph key points
  void _updateKeyPoints(GraphKeyPoints keyPoints) {
    _xIntercepts.clear();
    _xIntercepts.addAll(keyPoints.xIntercepts);
    _yIntercept = keyPoints.yIntercept;
    _vertex = keyPoints.vertex;
  }

  /// Check if the graph type is an enhanced type (Syncfusion or GraphView)
  bool _isEnhancedGraphType(String typeString) {
    // Use the constant set to check if it's a legacy type
    return !kLegacyGraphTypes.contains(typeString);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final styleUtils = ref.watch(styleUtilsProvider);

    // Check if this is an enhanced graph type (new Syncfusion or GraphView charts)
    final typeString = content['type']?.toString() ?? 'line';
    final isEnhancedGraph = _isEnhancedGraphType(typeString);

    if (isEnhancedGraph) {
      // Use the enhanced graph renderer for new chart types
      return EnhancedGraphRenderer(block: widget.block, theme: theme);
    }

    // Continue with legacy graph rendering for backward compatibility
    final color =
        styleUtils.parseHex(widget.block.style.color) ??
        theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLatexHeader(typeString, color, styleUtils, theme),
          const SizedBox(height: 6),
          _buildGraphContainer(theme, styleUtils),
          if (content['caption']?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Center(
                child: Text(
                  content['caption'],
                  style: styleUtils
                      .applyStyle(widget.block.style)
                      .copyWith(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                  semanticsLabel: 'Graph caption: ${content['caption']}',
                ),
              ),
            ),
          GraphControlsWidget(
            zoomLevel: _zoomLevel,
            showGrid: _showGrid,
            showIntercepts: _showIntercepts,
            showInfoPanel: _showInfoPanel,
            onZoomIn: () =>
                setState(() => _zoomLevel = (_zoomLevel + 0.5).clamp(0.5, 4.0)),
            onZoomOut: () =>
                setState(() => _zoomLevel = (_zoomLevel - 0.5).clamp(0.5, 4.0)),
            onResetView: () {
              _animationController.forward().then((_) {
                setState(() {
                  _zoomLevel = 1.0;
                  _panOffset = Offset.zero;
                });
                _animationController.reset();
              });
            },
            onToggleGrid: () => setState(() => _showGrid = !_showGrid),
            onToggleIntercepts: () =>
                setState(() => _showIntercepts = !_showIntercepts),
            onToggleInfoPanel: () =>
                setState(() => _showInfoPanel = !_showInfoPanel),
          ),
          if (_showInfoPanel)
            GraphInfoPanelWidget(
              yIntercept: _yIntercept,
              xIntercepts: _xIntercepts,
              vertex: _vertex,
              minX: _minX,
              maxX: _maxX,
              zoomLevel: _zoomLevel,
              formatNumber: GraphUtilities.formatNumber,
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LaTeX header (one row per equation for line type, single row otherwise)
  // ---------------------------------------------------------------------------

  Widget _buildLatexHeader(
    String typeString,
    Color color,
    StyleUtils styleUtils,
    ThemeData theme,
  ) {
    final expression = content['expression']?.toString() ?? '';

    // For multi-equation line graphs render each equation with its colour swatch.
    if (typeString == 'line' && expression.contains(';')) {
      final parts = LatexExpressionFormatter.splitExpressions(expression);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: parts.asMap().entries.map((entry) {
          final idx = entry.key;
          final expr = entry.value;
          final equationColor = getEquationColor(idx, theme);
          final latex = LatexExpressionFormatter.formatExpression(expr, 'line');
          return Padding(
            padding: EdgeInsets.only(bottom: idx < parts.length - 1 ? 4 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Colour swatch matching the plotted line.
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: equationColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Math.tex(
                      latex,
                      textStyle: styleUtils
                          .applyStyle(widget.block.style)
                          .copyWith(
                            color: equationColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                      onErrorFallback: (FlutterMathException _) => Text(
                        expr,
                        style: styleUtils
                            .applyStyle(widget.block.style)
                            .copyWith(
                              color: equationColor,
                              fontFamily: 'RobotoMono',
                              fontSize: 13,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Single expression or non-line type – existing behaviour.
    String displayLatex = r'\text{[Empty graph block]}';
    try {
      if (expression.isNotEmpty) {
        displayLatex = LatexExpressionFormatter.formatExpression(
          expression,
          typeString,
        );
      }
    } catch (e) {
      displayLatex = r'\text{Invalid expression}';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Math.tex(
        displayLatex,
        textStyle: styleUtils
            .applyStyle(widget.block.style)
            .copyWith(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'CMU Serif',
            ),
        onErrorFallback: (FlutterMathException _) => Text(
          'Invalid expression',
          style: styleUtils
              .applyStyle(widget.block.style)
              .copyWith(
                color: theme.colorScheme.error,
                fontSize: theme.textTheme.bodyMedium?.fontSize,
              ),
        ),
      ),
    );
  }

  Widget _buildGraphContainer(ThemeData theme, StyleUtils styleUtils) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300.0, minHeight: 220.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _isLoading
              ? Center(
                  child: ShimmerCircularProgress(
                    size: 50,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : GestureDetector(
                  onScaleUpdate: (details) {
                    setState(() {
                      _zoomLevel = (details.scale * _zoomLevel).clamp(0.1, 4.0);
                      _panOffset += details.focalPointDelta / _zoomLevel;
                    });
                  },
                  child: _buildGraph(theme),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 36),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
              });
              _initializeContent();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildGraph(ThemeData theme) {
    switch (_graphType) {
      case GraphType.line:
        return GraphLineChartWidget(
          expression: content['expression'] ?? '',
          minX: _minX,
          maxX: _maxX,
          zoomLevel: _zoomLevel,
          panOffset: _panOffset,
          showGrid: _showGrid,
          showIntercepts: _showIntercepts,
          theme: theme,
          onKeyPointsCalculated: (keyPoints) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _updateKeyPoints(keyPoints));
              }
            });
          },
        );
      case GraphType.parametric:
        return GraphParametricChartWidget(
          expression: content['expression'] ?? '',
          tMin: _minX,
          tMax: _maxX,
          zoomLevel: _zoomLevel,
          panOffset: _panOffset,
          showGrid: _showGrid,
          theme: theme,
        );
      case GraphType.polar:
        return GraphPolarChartWidget(
          expression: content['expression'] ?? '',
          thetaMin: _minX,
          thetaMax: _maxX,
          zoomLevel: _zoomLevel,
          panOffset: _panOffset,
          showGrid: _showGrid,
          theme: theme,
        );
      case GraphType.bar:
        return GraphBarChartWidget(
          data: content['expression'] ?? '',
          showGrid: _showGrid,
          theme: theme,
        );
      case GraphType.scatter:
        return GraphScatterChartWidget(
          data: content['expression'] ?? '',
          showGrid: _showGrid,
          theme: theme,
        );
    }
  }
}
