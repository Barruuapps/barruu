import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barruu/core/constants/design_tokens.dart';

/// A single command/action item within the palette.
class CommandItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onExecute;
  final List<String> keywords;
  final String? shortcutLabel;

  const CommandItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onExecute,
    this.keywords = const [],
    this.shortcutLabel,
  });
}

/// A global command palette inspired by Cursor, VS Code, and Raycast.
///
/// Press Ctrl+K to open. Search, navigate with arrows, execute with Enter.
class CommandPalette extends StatefulWidget {
  final List<CommandItem> commands;
  final String searchPlaceholder;
  final List<CommandItem>? recentCommands;

  const CommandPalette({
    super.key,
    required this.commands,
    this.searchPlaceholder = 'Type a command or search...',
    this.recentCommands,
  });

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  int _selectedIndex = 0;

  List<CommandItem> get _filteredCommands {
    if (_query.isEmpty) return widget.commands;
    final q = _query.toLowerCase();
    return widget.commands.where((cmd) {
      return cmd.title.toLowerCase().contains(q) ||
          (cmd.subtitle?.toLowerCase().contains(q) ?? false) ||
          cmd.keywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _executeCommand(CommandItem cmd) {
    Navigator.of(context).pop();
    cmd.onExecute();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final filtered = _filteredCommands;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, filtered.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(0, filtered.length - 1);
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (filtered.isNotEmpty && _selectedIndex < filtered.length) {
        _executeCommand(filtered[_selectedIndex]);
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredCommands;

    // Clamp selected index
    if (_selectedIndex >= filtered.length && filtered.isNotEmpty) {
      _selectedIndex = filtered.length - 1;
    } else if (filtered.isEmpty) {
      _selectedIndex = 0;
    }

    return Center(
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: DesignTokens.commandPaletteMaxWidth,
            constraints: const BoxConstraints(
              maxHeight: DesignTokens.commandPaletteMaxHeight,
            ),
            margin: const EdgeInsets.all(DesignTokens.spacing24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(DesignTokens.radius2XLarge),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radius2XLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchInput(theme),
                  Divider(height: 1, thickness: 1, color: theme.colorScheme.outlineVariant),
                  Flexible(
                    child: filtered.isEmpty
                        ? _buildEmptyState(theme)
                        : _buildResultsList(theme, filtered),
                  ),
                  if (filtered.isNotEmpty) _buildFooter(theme, filtered.length),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacing16,
        DesignTokens.spacing8,
        DesignTokens.spacing8,
        DesignTokens.spacing8,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              size: DesignTokens.iconCompact, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  _query = value;
                  _selectedIndex = 0;
                });
              },
              decoration: InputDecoration(
                hintText: widget.searchPlaceholder,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: DesignTokens.spacing12),
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing8,
              vertical: DesignTokens.spacing4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text('esc',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: DesignTokens.spacing4),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.spacing32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: DesignTokens.icon3XLarge,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(height: DesignTokens.spacing16),
          Text('No commands found',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: DesignTokens.weightSemiBold)),
        ],
      ),
    );
  }

  Widget _buildResultsList(ThemeData theme, List<CommandItem> filtered) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacing8),
      shrinkWrap: true,
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final cmd = filtered[index];
        final isSelected = index == _selectedIndex;
        return _CommandResultTile(
          command: cmd,
          isSelected: isSelected,
          onTap: () => _executeCommand(cmd),
          onHover: () => setState(() => _selectedIndex = index),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacing16,
        vertical: DesignTokens.spacing8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          _buildKeyHint(theme, '\u2191\u2193', 'Navigate'),
          const SizedBox(width: DesignTokens.spacing12),
          _buildKeyHint(theme, '\u21B5', 'Open'),
          const Spacer(),
          Text('$totalCount command${totalCount == 1 ? '' : 's'}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildKeyHint(ThemeData theme, String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacing8,
            vertical: DesignTokens.spacing4,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Text(key,
              style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: DesignTokens.weightSemiBold,
                  color: theme.colorScheme.onSurface)),
        ),
        const SizedBox(width: DesignTokens.spacing8),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _CommandResultTile extends StatelessWidget {
  final CommandItem command;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onHover;

  const _CommandResultTile({
    required this.command,
    required this.isSelected,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacing8,
        vertical: DesignTokens.spacing2,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHover(),
        child: Material(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: InkWell(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacing12,
                vertical: DesignTokens.spacing12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    ),
                    child: Icon(command.icon,
                        size: DesignTokens.iconCompact,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: DesignTokens.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(command.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: isSelected
                                    ? DesignTokens.weightSemiBold
                                    : DesignTokens.weightMedium,
                                color: theme.colorScheme.onSurface)),
                        if (command.subtitle != null) ...[
                          const SizedBox(height: DesignTokens.spacing4),
                          Text(command.subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                  if (command.shortcutLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing8,
                        vertical: DesignTokens.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Text(command.shortcutLabel!,
                          style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: DesignTokens.weightSemiBold,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}