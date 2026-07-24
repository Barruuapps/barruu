import 'package:flutter/material.dart';
import 'package:barruu/core/constants/user_constants.dart';

/// Widget for selecting interests for personalized content.
///
/// Supports two display modes:
/// - Default (chip grid): shows all categories as toggleable chips — ideal
///   for onboarding where every option is visible at once.
/// - Compact (dropdown): shows a summary button that opens a bottom sheet
///   with checkboxes — ideal for profile editing where space is limited.
class InterestsSelector extends StatelessWidget {
  final List<String> selectedInterests;
  final ValueChanged<List<String>> onInterestsChanged;
  final int minSelection;
  final int maxSelection;

  /// When [compact] is true the widget renders as a tappable summary that
  /// opens a selection bottom-sheet instead of a full chip grid.
  final bool compact;

  /// Minimum number of interests required
  static const int defaultMinSelection = 3;

  /// Maximum number of interests allowed
  static const int defaultMaxSelection = 10;

  const InterestsSelector({
    super.key,
    required this.selectedInterests,
    required this.onInterestsChanged,
    this.minSelection = defaultMinSelection,
    this.maxSelection = defaultMaxSelection,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return compact
        ? _CompactInterestsSelector(
            selectedInterests: selectedInterests,
            onInterestsChanged: onInterestsChanged,
            minSelection: minSelection,
            maxSelection: maxSelection,
          )
        : _ChipInterestsSelector(
            selectedInterests: selectedInterests,
            onInterestsChanged: onInterestsChanged,
            minSelection: minSelection,
            maxSelection: maxSelection,
          );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip grid mode (onboarding)
// ─────────────────────────────────────────────────────────────────────────────

class _ChipInterestsSelector extends StatelessWidget {
  final List<String> selectedInterests;
  final ValueChanged<List<String>> onInterestsChanged;
  final int minSelection;
  final int maxSelection;

  const _ChipInterestsSelector({
    required this.selectedInterests,
    required this.onInterestsChanged,
    required this.minSelection,
    required this.maxSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select at least $minSelection interests (max $maxSelection) to personalize your feed',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppCategories.all.map((interest) {
            final isSelected = selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                _handleInterestToggle(interest, selected);
              },
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${selectedInterests.length}/$maxSelection',
          style: theme.textTheme.bodySmall?.copyWith(
            color: selectedInterests.length >= minSelection
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _handleInterestToggle(String interest, bool selected) {
    final newInterests = List<String>.from(selectedInterests);

    if (selected) {
      if (newInterests.length < maxSelection) {
        newInterests.add(interest);
      } else {
        return;
      }
    } else {
      newInterests.remove(interest);
    }

    onInterestsChanged(newInterests);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact dropdown mode (profile edit)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactInterestsSelector extends StatelessWidget {
  final List<String> selectedInterests;
  final ValueChanged<List<String>> onInterestsChanged;
  final int minSelection;
  final int maxSelection;

  const _CompactInterestsSelector({
    required this.selectedInterests,
    required this.onInterestsChanged,
    required this.minSelection,
    required this.maxSelection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMin = selectedInterests.length >= minSelection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary / trigger button
        InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Interests',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              suffixIcon: const Icon(Icons.arrow_drop_down),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            child: selectedInterests.isEmpty
                ? Text(
                    'Tap to select your interests…',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedInterests.map((i) {
                      return Chip(
                        label: Text(i, style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onDeleted: () {
                          final updated = List<String>.from(selectedInterests)
                            ..remove(i);
                          onInterestsChanged(updated);
                        },
                      );
                    }).toList(),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hasMin
              ? '${selectedInterests.length}/$maxSelection selected'
              : 'Select at least $minSelection (${selectedInterests.length}/$maxSelection)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: hasMin ? theme.colorScheme.primary : theme.colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final updated = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _InterestsPickerSheet(
        selectedInterests: List<String>.from(selectedInterests),
        maxSelection: maxSelection,
      ),
    );
    if (updated != null) {
      onInterestsChanged(updated);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom-sheet used by compact mode
// ─────────────────────────────────────────────────────────────────────────────

class _InterestsPickerSheet extends StatefulWidget {
  final List<String> selectedInterests;
  final int maxSelection;

  const _InterestsPickerSheet({
    required this.selectedInterests,
    required this.maxSelection,
  });

  @override
  State<_InterestsPickerSheet> createState() => _InterestsPickerSheetState();
}

class _InterestsPickerSheetState extends State<_InterestsPickerSheet> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedInterests);
  }

  void _toggle(String item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else if (_selected.length < widget.maxSelection) {
        _selected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Interests',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${_selected.length}/${widget.maxSelection}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: AppCategories.all.length,
                itemBuilder: (context, index) {
                  final item = AppCategories.all[index];
                  final isSelected = _selected.contains(item);
                  return CheckboxListTile(
                    title: Text(item),
                    value: isSelected,
                    onChanged: (_) => _toggle(item),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: theme.colorScheme.primary,
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                8,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Apply'),
              ),
            ),
          ],
        );
      },
    );
  }
}
