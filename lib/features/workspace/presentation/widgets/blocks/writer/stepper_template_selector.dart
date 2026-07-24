import 'package:flutter/material.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/stepper_templates.dart';

/// Visual template selector for stepper blocks.
/// Shows visual previews of each stepper template instead of text labels.
class StepperTemplateSelector extends StatelessWidget {
  final String selectedTemplate;
  final Function(String) onTemplateSelected;
  final ThemeData theme;

  const StepperTemplateSelector({
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Stepper Template'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
          children: [
            _buildTemplateOption(kStepperTemplateStandard, kStepperTemplateNames[kStepperTemplateStandard]!, _buildStandardPreview()),
            _buildTemplateOption(kStepperTemplateNumbered, kStepperTemplateNames[kStepperTemplateNumbered]!, _buildNumberedPreview()),
            _buildTemplateOption(kStepperTemplateProgress, kStepperTemplateNames[kStepperTemplateProgress]!, _buildProgressPreview()),
            _buildTemplateOption(kStepperTemplateTimeline, kStepperTemplateNames[kStepperTemplateTimeline]!, _buildTimelinePreview()),
            _buildTemplateOption(kStepperTemplateMinimal, kStepperTemplateNames[kStepperTemplateMinimal]!, _buildMinimalPreview()),
            _buildTemplateOption(kStepperTemplateCards, kStepperTemplateNames[kStepperTemplateCards]!, _buildCardsPreview()),
            _buildTemplateOption(kStepperTemplateChecklist, kStepperTemplateNames[kStepperTemplateChecklist]!, _buildChecklistPreview()),
            _buildTemplateOption(kStepperTemplateDots, kStepperTemplateNames[kStepperTemplateDots]!, _buildDotsPreview()),
          ],
        ),
      ),
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
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
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
                padding: const EdgeInsets.all(8.0),
                child: preview,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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

  // Template preview widgets - simplified visual representations

  Widget _buildStandardPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        final isCompleted = index == 0;
        return Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: isCompleted ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: isCompleted 
                  ? Icon(Icons.check, size: 10, color: theme.colorScheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNumberedPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        return Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProgressPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.6,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(3, (index) {
            return Container(
              width: 3,
              height: 8,
              color: index == 0 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.onSurface.withValues(alpha: 0.3),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimelinePreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        final isFirst = index == 0;
        final isLast = index == 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 12,
              child: Column(
                children: [
                  if (!isFirst)
                    Container(
                      width: 2,
                      height: 6,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 6,
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 2,
                    width: double.infinity,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 2,
                    width: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMinimalPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        return Row(
          children: [
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCardsPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        final isActive = index == 0;
        return Container(
          height: 18,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive 
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildChecklistPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        final isChecked = index == 0;
        return Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isChecked ? theme.colorScheme.primary : theme.colorScheme.surface,
                border: Border.all(
                  color: isChecked 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline.withValues(alpha: 0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: isChecked 
                  ? Icon(Icons.check, size: 10, color: theme.colorScheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 2,
                color: theme.colorScheme.onSurface.withValues(
                  alpha: isChecked ? 0.2 : 0.3,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDotsPreview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isActive = index == 1;
        final isCompleted = index == 0;
        return Container(
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isCompleted 
                ? theme.colorScheme.primary 
                : isActive 
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
