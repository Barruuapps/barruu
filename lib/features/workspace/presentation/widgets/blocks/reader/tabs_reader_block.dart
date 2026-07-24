import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/core/theme/platform_theme_helper.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/presentation/widgets/edit_document/page_drawer_widget.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/tab_templates.dart';

/// Read-only display of tabs block.
class TabsReaderBlock extends ConsumerStatefulWidget {
  final Block block;
  final Directory docDir;
  final bool allowSelection;
  
  const TabsReaderBlock({
    required this.block,
    required this.docDir,
    this.allowSelection = true,
    super.key,
  });

  @override
  ConsumerState<TabsReaderBlock> createState() => _TabsReaderBlockState();
}

class _TabsReaderBlockState extends ConsumerState<TabsReaderBlock> with SingleTickerProviderStateMixin {
  int _activeTab = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final content = _parseContent();
    final tabs = content['tabs'] as List? ?? [];
    _activeTab = (content['activeTab'] as num?)?.toInt() ?? 0;
    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: _activeTab.clamp(0, tabs.isNotEmpty ? tabs.length - 1 : 0),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _parseContent() {
    final converter = JsonStringConverter();
    try {
      return converter.convertFromJsonString(widget.block.content);
    } catch (e) {
      return {'tabs': [], 'activeTab': 0, 'tabTemplate': kDefaultTabTemplate, 'contentHeight': 400.0};
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = _parseContent();
    final tabs = content['tabs'] as List? ?? [];
    final tabTemplate = content['tabTemplate']?.toString() ?? kDefaultTabTemplate;
    final contentHeight = (content['contentHeight'] as num?)?.toDouble() ?? 400.0;

    if (tabs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No tabs configured',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      );
    }

    return _buildTabsWithTemplate(context, theme, tabs, tabTemplate, contentHeight);
  }

  Widget _buildTabsWithTemplate(BuildContext context, ThemeData theme, List tabs, String template, double contentHeight) {
    switch (template) {
      case kTabTemplatePills:
        return _buildPillsTabs(context, theme, tabs, contentHeight);
      case kTabTemplateUnderline:
        return _buildUnderlineTabs(context, theme, tabs, contentHeight);
      case kTabTemplateBoxed:
        return _buildBoxedTabs(context, theme, tabs, contentHeight);
      case kTabTemplateMinimal:
        return _buildMinimalTabs(context, theme, tabs, contentHeight);
      case kTabTemplateSidebar:
        return _buildSidebarTabs(context, theme, tabs, contentHeight);
      case kTabTemplateVertical:
        return _buildVerticalTabs(context, theme, tabs, contentHeight);
      case kTabTemplateSegmented:
        return _buildSegmentedTabs(context, theme, tabs, contentHeight);
      case kTabTemplateCards:
        return _buildCardsTabs(context, theme, tabs, contentHeight);
      case kTabTemplateStandard:
      default:
        return _buildStandardTabs(context, theme, tabs, contentHeight);
    }
  }

  Widget _buildStandardTabs(BuildContext context, ThemeData theme, List tabs, double contentHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // TabBar at the top with improved styling
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              labelColor: theme.colorScheme.onPrimaryContainer,
              labelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
              unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onTap: (index) {
                setState(() => _activeTab = index);
              },
              tabs: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final icon = getDrawerPageIcon(tab['icon']?.toString());
                
                return Tab(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(tab['title'] ?? 'Untitled'),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          // TabBarView with content and improved styling
          SizedBox(
            height: contentHeight,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final tabContent = tab['content']?.toString() ?? '';
                
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _buildMarkdownContent(context, theme, tabContent),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context, ThemeData theme, String content) {
    if (content.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconsaxPlusLinear.document_text,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No content yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add content in edit mode',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final baseStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.6,
      letterSpacing: 0.15,
    ) ?? const TextStyle();

    return MarkdownBody(
      data: content,
      styleSheet: MarkdownStyleSheet(
        p: baseStyle,
        strong: baseStyle.copyWith(fontWeight: FontWeight.bold),
        em: baseStyle.copyWith(fontStyle: FontStyle.italic),
        a: baseStyle.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: baseStyle.copyWith(
          fontFamily: 'monospace',
          fontSize: baseStyle.fontSize! * 0.9,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        codeblockDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        codeblockPadding: const EdgeInsets.all(16),
        blockquote: baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurface.withOpacity(0.8),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: theme.colorScheme.primary,
              width: 4,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        listBullet: baseStyle,
        h1: baseStyle.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        h2: baseStyle.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        h3: baseStyle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        h4: baseStyle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        h5: baseStyle.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        h6: baseStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
      ),
      selectable: widget.allowSelection,
      onTapLink: (text, href, title) async {
        if (href != null) {
          await LinkUtils.launchURL(href);
        }
      },
    );
  }

  // Pills template - Rounded pill-shaped tabs
  Widget _buildPillsTabs(BuildContext context, ThemeData theme, List tabs, double contentHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Pills tab bar
          Container(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final isSelected = _tabController.index == index;
                return InkWell(
                  onTap: () => _tabController.animateTo(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tab['title'] ?? 'Untitled',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isSelected 
                            ? theme.colorScheme.onPrimary 
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Content area
          SizedBox(
            height: contentHeight,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final tabContent = tab['content']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _buildMarkdownContent(context, theme, tabContent),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Underline template - Minimal underlined tabs
  Widget _buildUnderlineTabs(BuildContext context, ThemeData theme, List tabs, double contentHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 3,
                ),
              ),
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              tabs: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                return Tab(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(tab['title'] ?? 'Untitled'),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: contentHeight,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final tabContent = tab['content']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _buildMarkdownContent(context, theme, tabContent),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Boxed template - Tabs with background boxes
  Widget _buildBoxedTabs(BuildContext context, ThemeData theme, List tabs, double contentHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final isSelected = _tabController.index == index;
                return Expanded(
                  child: InkWell(
                    onTap: () => _tabController.animateTo(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected 
                            ? Border.all(
                                color: theme.colorScheme.primary.withOpacity(0.5),
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          tab['title'] ?? 'Untitled',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: contentHeight,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final tabContent = tab['content']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _buildMarkdownContent(context, theme, tabContent),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Minimal template - Clean minimal design
  Widget _buildMinimalTabs(BuildContext context, ThemeData theme, List tabs, double contentHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final isSelected = _tabController.index == index;
                return InkWell(
                  onTap: () => _tabController.animateTo(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      border: isSelected 
                          ? Border(
                              bottom: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      tab['title'] ?? 'Untitled',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: contentHeight,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final tabContent = tab['content']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _buildMarkdownContent(context, theme, tabContent),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar template - Sidebar navigation style
  Widget _buildSidebarTabs(BuildContext context, ThemeData theme, List tabs, double contentHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: contentHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: ListView.builder(
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final isSelected = _tabController.index == index;
                return InkWell(
                  onTap: () => _tabController.animateTo(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tab['title'] ?? 'Untitled',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final tabContent = tab['content']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _buildMarkdownContent(context, theme, tabContent),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Vertical template - Vertically stacked tabs
  Widget _buildVerticalTabs(BuildContext context, ThemeData theme, List tabs, double contentHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final isSelected = _tabController.index == index;
                return InkWell(
                  onTap: () => _tabController.animateTo(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? theme.colorScheme.primary.withOpacity(0.15)
                          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected 
                          ? Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            )
                          : null,
                    ),
                    child: Text(
                      tab['title'] ?? 'Untitled',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: contentHeight,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final tabContent = tab['content']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _buildMarkdownContent(context, theme, tabContent),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Segmented template - iOS-style segmented control
  Widget _buildSegmentedTabs(BuildContext context, ThemeData theme, List tabs, double contentHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final isSelected = _tabController.index == index;
                return Expanded(
                  child: InkWell(
                    onTap: () => _tabController.animateTo(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          tab['title'] ?? 'Untitled',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected 
                                ? theme.colorScheme.onPrimary 
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(
            height: contentHeight,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final tabContent = tab['content']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _buildMarkdownContent(context, theme, tabContent),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Cards template - Card-based tab selection
  Widget _buildCardsTabs(BuildContext context, ThemeData theme, List tabs, double contentHeight) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final isSelected = _tabController.index == index;
                final icon = getDrawerPageIcon(tab['icon']?.toString());
                return InkWell(
                  onTap: () => _tabController.animateTo(index),
                  child: Container(
                    width: 150,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.outline.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? theme.colorScheme.primaryContainer 
                                  : theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected 
                                  ? theme.colorScheme.onPrimaryContainer 
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          tab['title'] ?? 'Untitled',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected 
                                ? theme.colorScheme.primary 
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: contentHeight,
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index] as Map<String, dynamic>;
                final tabContent = tab['content']?.toString() ?? '';
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _buildMarkdownContent(context, theme, tabContent),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
