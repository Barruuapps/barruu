import 'package:flutter/material.dart';
import 'package:barruu/core/constants/design_tokens.dart';

/// Auto-save status indicator widget for the editor toolbar.
///
/// Shows one of three states:
/// - **Saved** — green checkmark with "Saved"
/// - **Saving** — animated spinning dots
/// - **Unsaved** — subtle dot indicator
enum AutoSaveStatus { saved, saving, unsaved }

class AutoSaveIndicator extends StatelessWidget {
  final AutoSaveStatus status;
  final VoidCallback? onTap;

  const AutoSaveIndicator({super.key, required this.status, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignTokens.duration200,
        curve: DesignTokens.curveStandard,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing12,
          vertical: DesignTokens.spacing4,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(theme),
            const SizedBox(width: DesignTokens.spacing8),
            AnimatedSwitcher(
              duration: DesignTokens.duration200,
              child: Text(
                _label,
                key: ValueKey(_label),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _color(theme),
                  fontWeight: DesignTokens.weightMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _color(ThemeData theme) {
    switch (status) {
      case AutoSaveStatus.saved:
        return Colors.green.shade600;
      case AutoSaveStatus.saving:
        return theme.colorScheme.onSurfaceVariant;
      case AutoSaveStatus.unsaved:
        return Colors.orange.shade700;
    }
  }

  String get _label {
    switch (status) {
      case AutoSaveStatus.saved:
        return 'Saved';
      case AutoSaveStatus.saving:
        return 'Saving...';
      case AutoSaveStatus.unsaved:
        return 'Unsaved';
    }
  }

  Widget _buildIcon(ThemeData theme) {
    switch (status) {
      case AutoSaveStatus.saved:
        return Icon(
          Icons.check_circle_rounded,
          size: DesignTokens.iconXSmall,
          color: Colors.green.shade600,
        );
      case AutoSaveStatus.saving:
        return SizedBox(
          width: DesignTokens.iconXSmall,
          height: DesignTokens.iconXSmall,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      case AutoSaveStatus.unsaved:
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.orange.shade600,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}
