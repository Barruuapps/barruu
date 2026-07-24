import 'package:flutter/material.dart';

/// A widget that provides interactive controls for graph manipulation.
///
/// This widget displays a row of control buttons that allow users to:
/// - Zoom in and out
/// - Reset the view
/// - Toggle grid visibility
/// - Toggle intercept markers
/// - Toggle info panel visibility
///
/// Example usage:
/// ```dart
/// GraphControlsWidget(
///   zoomLevel: 1.0,
///   showGrid: true,
///   showIntercepts: true,
///   showInfoPanel: false,
///   onZoomIn: () => setState(() => zoomLevel += 0.5),
///   onZoomOut: () => setState(() => zoomLevel -= 0.5),
///   onResetView: () => setState(() => zoomLevel = 1.0),
///   onToggleGrid: () => setState(() => showGrid = !showGrid),
///   onToggleIntercepts: () => setState(() => showIntercepts = !showIntercepts),
///   onToggleInfoPanel: () => setState(() => showInfoPanel = !showInfoPanel),
/// )
/// ```
class GraphControlsWidget extends StatelessWidget {
  /// Current zoom level (used to enable/disable zoom buttons)
  final double zoomLevel;

  /// Whether the grid is currently visible
  final bool showGrid;

  /// Whether intercept markers are currently visible
  final bool showIntercepts;

  /// Whether the info panel is currently visible
  final bool showInfoPanel;

  /// Callback when zoom in button is pressed
  final VoidCallback onZoomIn;

  /// Callback when zoom out button is pressed
  final VoidCallback onZoomOut;

  /// Callback when reset view button is pressed
  final VoidCallback onResetView;

  /// Callback when grid toggle button is pressed
  final VoidCallback onToggleGrid;

  /// Callback when intercepts toggle button is pressed
  final VoidCallback onToggleIntercepts;

  /// Callback when info panel toggle button is pressed
  final VoidCallback onToggleInfoPanel;

  const GraphControlsWidget({
    required this.zoomLevel,
    required this.showGrid,
    required this.showIntercepts,
    required this.showInfoPanel,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
    required this.onToggleGrid,
    required this.onToggleIntercepts,
    required this.onToggleInfoPanel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          _buildControlButton(
            icon: Icons.zoom_out,
            tooltip: 'Zoom out',
            onPressed: onZoomOut,
            theme: theme,
          ),
          _buildControlButton(
            icon: Icons.zoom_in,
            tooltip: 'Zoom in',
            onPressed: onZoomIn,
            theme: theme,
          ),
          _buildControlButton(
            icon: Icons.refresh,
            tooltip: 'Reset view',
            onPressed: onResetView,
            theme: theme,
          ),
          _buildControlButton(
            icon: showGrid ? Icons.grid_on : Icons.grid_off,
            tooltip: showGrid ? 'Hide grid' : 'Show grid',
            onPressed: onToggleGrid,
            theme: theme,
          ),
          _buildControlButton(
            icon: showIntercepts
                ? Icons.scatter_plot
                : Icons.scatter_plot_outlined,
            tooltip: showIntercepts ? 'Hide intercepts' : 'Show intercepts',
            onPressed: onToggleIntercepts,
            theme: theme,
          ),
          _buildControlButton(
            icon: showInfoPanel ? Icons.info : Icons.info_outline,
            tooltip: showInfoPanel ? 'Hide info' : 'Show info',
            onPressed: onToggleInfoPanel,
            theme: theme,
          ),
        ],
      ),
    );
  }

  /// Builds a single control button with consistent styling.
  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}
