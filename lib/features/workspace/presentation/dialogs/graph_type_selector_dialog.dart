import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Enum for different graph and chart types available in the application
enum EnhancedGraphType {
  // Basic mathematical graphs (using existing fl_chart)
  line,
  parametric,
  polar,
  bar,
  scatter,
  
  // Syncfusion charts - Business & Analytics
  sfLine,
  sfBar,
  sfColumn,
  sfPie,
  sfDoughnut,
  sfArea,
  sfSpline,
  sfStepLine,
  sfBubble,
  sfScatter,
  
  // GraphView - Node-based graphs
  flowchart,
  mindMap,
  orgChart,
  tree,
  network,
}

/// Extension to provide display information for each graph type
extension EnhancedGraphTypeExtension on EnhancedGraphType {
  String get displayName {
    switch (this) {
      case EnhancedGraphType.line:
        return 'Line Graph';
      case EnhancedGraphType.parametric:
        return 'Parametric';
      case EnhancedGraphType.polar:
        return 'Polar';
      case EnhancedGraphType.bar:
        return 'Bar Chart';
      case EnhancedGraphType.scatter:
        return 'Scatter Plot';
      case EnhancedGraphType.sfLine:
        return 'SF Line';
      case EnhancedGraphType.sfBar:
        return 'SF Bar';
      case EnhancedGraphType.sfColumn:
        return 'SF Column';
      case EnhancedGraphType.sfPie:
        return 'SF Pie';
      case EnhancedGraphType.sfDoughnut:
        return 'SF Doughnut';
      case EnhancedGraphType.sfArea:
        return 'SF Area';
      case EnhancedGraphType.sfSpline:
        return 'SF Spline';
      case EnhancedGraphType.sfStepLine:
        return 'SF Step Line';
      case EnhancedGraphType.sfBubble:
        return 'SF Bubble';
      case EnhancedGraphType.sfScatter:
        return 'SF Scatter';
      case EnhancedGraphType.flowchart:
        return 'Flowchart';
      case EnhancedGraphType.mindMap:
        return 'Mind Map';
      case EnhancedGraphType.orgChart:
        return 'Org Chart';
      case EnhancedGraphType.tree:
        return 'Tree Graph';
      case EnhancedGraphType.network:
        return 'Network';
    }
  }
  
  String get description {
    switch (this) {
      case EnhancedGraphType.line:
        return 'Mathematical line graph';
      case EnhancedGraphType.parametric:
        return 'Parametric equations';
      case EnhancedGraphType.polar:
        return 'Polar coordinates';
      case EnhancedGraphType.bar:
        return 'Simple bar chart';
      case EnhancedGraphType.scatter:
        return 'Scatter plot';
      case EnhancedGraphType.sfLine:
        return 'Professional line chart';
      case EnhancedGraphType.sfBar:
        return 'Horizontal bar chart';
      case EnhancedGraphType.sfColumn:
        return 'Vertical column chart';
      case EnhancedGraphType.sfPie:
        return 'Circular pie chart';
      case EnhancedGraphType.sfDoughnut:
        return 'Doughnut chart';
      case EnhancedGraphType.sfArea:
        return 'Area chart';
      case EnhancedGraphType.sfSpline:
        return 'Smooth spline chart';
      case EnhancedGraphType.sfStepLine:
        return 'Step line chart';
      case EnhancedGraphType.sfBubble:
        return 'Bubble chart';
      case EnhancedGraphType.sfScatter:
        return 'Professional scatter';
      case EnhancedGraphType.flowchart:
        return 'Process flowchart';
      case EnhancedGraphType.mindMap:
        return 'Mind mapping diagram';
      case EnhancedGraphType.orgChart:
        return 'Organization chart';
      case EnhancedGraphType.tree:
        return 'Hierarchical tree';
      case EnhancedGraphType.network:
        return 'Network diagram';
    }
  }
  
  IconData get icon {
    switch (this) {
      case EnhancedGraphType.line:
      case EnhancedGraphType.sfLine:
      case EnhancedGraphType.sfSpline:
      case EnhancedGraphType.sfStepLine:
        return IconsaxPlusLinear.chart;
      case EnhancedGraphType.bar:
      case EnhancedGraphType.sfBar:
      case EnhancedGraphType.sfColumn:
        return IconsaxPlusLinear.chart_21;
      case EnhancedGraphType.sfPie:
      case EnhancedGraphType.sfDoughnut:
        return IconsaxPlusLinear.chart_1;
      case EnhancedGraphType.scatter:
      case EnhancedGraphType.sfScatter:
      case EnhancedGraphType.sfBubble:
        return IconsaxPlusLinear.chart_square;
      case EnhancedGraphType.parametric:
      case EnhancedGraphType.polar:
        return IconsaxPlusLinear.math;
      case EnhancedGraphType.sfArea:
        return IconsaxPlusLinear.activity;
      case EnhancedGraphType.flowchart:
        return IconsaxPlusLinear.diagram;
      case EnhancedGraphType.mindMap:
        return IconsaxPlusLinear.hierarchy_square_2;
      case EnhancedGraphType.orgChart:
        return IconsaxPlusLinear.hierarchy_3;
      case EnhancedGraphType.tree:
        return IconsaxPlusLinear.hierarchy;
      case EnhancedGraphType.network:
        return IconsaxPlusLinear.blend;
    }
  }
  
  GraphCategory get category {
    switch (this) {
      case EnhancedGraphType.line:
      case EnhancedGraphType.parametric:
      case EnhancedGraphType.polar:
      case EnhancedGraphType.bar:
      case EnhancedGraphType.scatter:
        return GraphCategory.mathematical;
      case EnhancedGraphType.sfLine:
      case EnhancedGraphType.sfBar:
      case EnhancedGraphType.sfColumn:
      case EnhancedGraphType.sfPie:
      case EnhancedGraphType.sfDoughnut:
      case EnhancedGraphType.sfArea:
      case EnhancedGraphType.sfSpline:
      case EnhancedGraphType.sfStepLine:
      case EnhancedGraphType.sfBubble:
      case EnhancedGraphType.sfScatter:
        return GraphCategory.business;
      case EnhancedGraphType.flowchart:
      case EnhancedGraphType.mindMap:
      case EnhancedGraphType.orgChart:
      case EnhancedGraphType.tree:
      case EnhancedGraphType.network:
        return GraphCategory.diagram;
    }
  }
}

/// Categories for organizing graph types
enum GraphCategory {
  mathematical,
  business,
  diagram,
}

extension GraphCategoryExtension on GraphCategory {
  String get displayName {
    switch (this) {
      case GraphCategory.mathematical:
        return 'Mathematical';
      case GraphCategory.business:
        return 'Business & Analytics';
      case GraphCategory.diagram:
        return 'Diagrams & Flowcharts';
    }
  }
  
  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (this) {
      case GraphCategory.mathematical:
        return Colors.blue;
      case GraphCategory.business:
        return Colors.green;
      case GraphCategory.diagram:
        return Colors.purple;
    }
  }
}

/// A bottom sheet dialog for selecting graph/chart types
/// Provides an interactive, mobile-first interface with categorized options
class GraphTypeSelectorDialog extends StatefulWidget {
  const GraphTypeSelectorDialog({super.key});

  @override
  State<GraphTypeSelectorDialog> createState() => _GraphTypeSelectorDialogState();

  /// Shows the graph type selector as a modal bottom sheet
  static Future<EnhancedGraphType?> show(BuildContext context) {
    return showModalBottomSheet<EnhancedGraphType>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GraphTypeSelectorDialog(),
    );
  }
}

class _GraphTypeSelectorDialogState extends State<GraphTypeSelectorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: GraphCategory.values.length,
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Icon(
                  IconsaxPlusLinear.chart_21,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Choose Graph Type',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          
          // Tab bar for categories
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: theme.textTheme.titleSmall,
              tabs: GraphCategory.values.map((category) {
                return Tab(
                  icon: Icon(
                    _getCategoryIcon(category),
                    size: 20,
                  ),
                  text: category.displayName,
                );
              }).toList(),
            ),
          ),
          
          // Tab content
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: GraphCategory.values.map((category) {
                return _buildCategoryContent(context, category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getCategoryIcon(GraphCategory category) {
    switch (category) {
      case GraphCategory.mathematical:
        return IconsaxPlusLinear.math;
      case GraphCategory.business:
        return IconsaxPlusLinear.chart_1;
      case GraphCategory.diagram:
        return IconsaxPlusLinear.diagram;
    }
  }
  
  Widget _buildCategoryContent(BuildContext context, GraphCategory category) {
    final types = EnhancedGraphType.values
        .where((type) => type.category == category)
        .toList();
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        return _GraphTypeCard(
          type: types[index],
          category: category,
          onTap: () => Navigator.of(context).pop(types[index]),
        );
      },
    );
  }
}

/// Individual card for each graph type option
class _GraphTypeCard extends StatelessWidget {
  final EnhancedGraphType type;
  final GraphCategory category;
  final VoidCallback onTap;

  const _GraphTypeCard({
    required this.type,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = category.getColor(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withValues(alpha: 0.1),
              categoryColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with gradient background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    categoryColor.withValues(alpha: 0.2),
                    categoryColor.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: Icon(
                type.icon,
                size: 32,
                color: categoryColor,
              ),
            ),
            const SizedBox(height: 12),
            
            // Name
            Text(
              type.displayName,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            
            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                type.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
