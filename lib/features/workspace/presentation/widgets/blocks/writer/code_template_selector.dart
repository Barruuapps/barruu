import 'package:flutter/material.dart';

/// Visual template selector for code blocks.
/// Shows visual previews of each code template.
class CodeTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const CodeTemplateSelector({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Code Template'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: [
            _buildTemplateOption('minimal', 'Minimal', _buildMinimalPreview()),
            _buildTemplateOption('default', 'Default', _buildDefaultPreview()),
            _buildTemplateOption('card', 'Card', _buildCardPreview()),
            _buildTemplateOption('terminal', 'Terminal', _buildTerminalPreview()),
            _buildTemplateOption('github', 'GitHub', _buildGithubPreview()),
            _buildTemplateOption('bordered', 'Bordered', _buildBorderedPreview()),
            _buildTemplateOption('dracula', 'Dracula', _buildDraculaPreview()),
            _buildTemplateOption('monokai', 'Monokai', _buildMonokaiPreview()),
            _buildTemplateOption('vscode', 'VS Code', _buildVscodePreview()),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildTemplateOption(String value, String label, Widget preview) {
    final isSelected = selectedTemplate == value;
    return InkWell(
      onTap: () => onTemplateSelected(value),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: preview,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Template preview widgets ──────────────────────────────────────────────

  /// Minimal: just code lines, no header bar
  Widget _buildMinimalPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _codeLine(0.6, theme.colorScheme.primary.withValues(alpha: 0.7)),
          const SizedBox(height: 3),
          _codeLine(0.8, theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(height: 3),
          _codeLine(0.5, theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  /// Default: header bar with language label + code lines
  Widget _buildDefaultPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 8, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                const SizedBox(width: 3),
                Expanded(
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _codeLine(0.7, theme.colorScheme.primary.withValues(alpha: 0.6)),
                  const SizedBox(height: 3),
                  _codeLine(0.9, theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card: elevated with shadow and accent header
  Widget _buildCardPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 8, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                const SizedBox(width: 3),
                Expanded(
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _codeLine(0.6, theme.colorScheme.primary.withValues(alpha: 0.6)),
                  const SizedBox(height: 3),
                  _codeLine(0.8, theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Terminal: dark header with macOS-style colored dots
  Widget _buildTerminalPreview() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A3C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Row(
              children: [
                _terminalDot(const Color(0xFFFF5F57)),
                const SizedBox(width: 2),
                _terminalDot(const Color(0xFFFFBD2E)),
                const SizedBox(width: 2),
                _terminalDot(const Color(0xFF28CA41)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _codeLine(0.6, const Color(0xFF98C379)),
                  const SizedBox(height: 3),
                  _codeLine(0.8, const Color(0xFFABB2BF)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// GitHub: grey header with code badge
  Widget _buildGithubPreview() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8FA),
        border: Border.all(color: const Color(0xFFD0D7DE)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: const BoxDecoration(
              color: Color(0xFFEAECF0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD0D7DE)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    '{ }',
                    style: TextStyle(
                      fontSize: 5,
                      color: Color(0xFF24292F),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _codeLine(0.7, const Color(0xFF0550AE).withValues(alpha: 0.8)),
                  const SizedBox(height: 3),
                  _codeLine(0.9, const Color(0xFF24292F).withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bordered: thick primary-color left-border accent with header
  Widget _buildBorderedPreview() {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
          top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          right: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: Row(
              children: [
                Icon(Icons.code, size: 8, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                const SizedBox(width: 3),
                Expanded(
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _codeLine(0.6, theme.colorScheme.primary.withValues(alpha: 0.7)),
                  const SizedBox(height: 3),
                  _codeLine(0.8, theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  const SizedBox(height: 3),
                  _codeLine(0.5, theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dracula: dark purple-accented theme
  Widget _buildDraculaPreview() {
    const bg = Color(0xFF282A36);
    const headerBg = Color(0xFF21222C);
    const accent = Color(0xFFBD93F9);
    const textColor = Color(0xFFF8F8F2);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF44475A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: const BoxDecoration(
              color: headerBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: accent),
                const SizedBox(width: 3),
                Expanded(
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _codeLine(0.6, accent.withValues(alpha: 0.8)),
                  const SizedBox(height: 3),
                  _codeLine(0.8, textColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 3),
                  _codeLine(0.5, const Color(0xFF50FA7B).withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Monokai: warm dark olive theme
  Widget _buildMonokaiPreview() {
    const bg = Color(0xFF272822);
    const headerBg = Color(0xFF1D1E1A);
    const accent = Color(0xFFA6E22E);
    const textColor = Color(0xFFF8F8F2);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3E3D32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: const BoxDecoration(
              color: headerBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _codeLine(0.6, const Color(0xFFF92672).withValues(alpha: 0.8)),
                  const SizedBox(height: 3),
                  _codeLine(0.8, textColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 3),
                  _codeLine(0.5, accent.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// VS Code Dark: realistic VS Code dark editor tab-style
  Widget _buildVscodePreview() {
    const bg = Color(0xFF1E1E1E);
    const headerBg = Color(0xFF2D2D2D);
    const accent = Color(0xFF569CD6);
    const textColor = Color(0xFFD4D4D4);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: headerBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    border: const Border(
                      top: BorderSide(color: accent, width: 1.5),
                    ),
                  ),
                  child: Container(
                    height: 2.5,
                    width: 20,
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _codeLine(0.6, accent.withValues(alpha: 0.8)),
                  const SizedBox(height: 3),
                  _codeLine(0.8, textColor.withValues(alpha: 0.4)),
                  const SizedBox(height: 3),
                  _codeLine(0.5, const Color(0xFF9CDCFE).withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _codeLine(double widthFraction, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        height: 2.5,
        width: constraints.maxWidth * widthFraction,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _terminalDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
