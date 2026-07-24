import 'package:flutter/material.dart';
import 'package:barruu/core/theme/design_tokens.dart';
import 'package:barruu/core/widgets/buttons/primary_button.dart';

/// Topic selection screen for onboarding
/// Allows users to select their interests for personalized content
class TopicSelectionScreen extends StatefulWidget {
  const TopicSelectionScreen({super.key});

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  final Set<String> _selectedTopics = {};
  final int _minTopics = 3;

  static const _topics = [
    {'id': 'tech', 'label': 'Technology', 'icon': Icons.computer},
    {'id': 'business', 'label': 'Business', 'icon': Icons.business},
    {'id': 'design', 'label': 'Design', 'icon': Icons.palette},
    {'id': 'science', 'label': 'Science', 'icon': Icons.science},
    {'id': 'health', 'label': 'Health', 'icon': Icons.favorite},
    {'id': 'finance', 'label': 'Finance', 'icon': Icons.attach_money},
    {'id': 'writing', 'label': 'Writing', 'icon': Icons.edit},
    {'id': 'education', 'label': 'Education', 'icon': Icons.school},
    {'id': 'arts', 'label': 'Arts', 'icon': Icons.brush},
    {'id': 'politics', 'label': 'Politics', 'icon': Icons.how_to_vote},
    {'id': 'philosophy', 'label': 'Philosophy', 'icon': Icons.psychology},
    {'id': 'psychology', 'label': 'Psychology', 'icon': Icons.psychology_alt},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canContinue = _selectedTopics.length >= _minTopics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to next screen without selection
              Navigator.pushReplacementNamed(context, '/profession-selection');
            },
            child: Text(
              'Skip',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: AppTypography.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'What interests you?',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Select $_minTopics or more topics',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Progress indicator
              if (_selectedTopics.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppBorders.circular,
                  ),
                  child: Text(
                    '${_selectedTopics.length} of $_minTopics selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // Topic grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.base,
                    mainAxisSpacing: AppSpacing.base,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: _topics.length,
                  itemBuilder: (context, index) {
                    final topic = _topics[index];
                    final isSelected = _selectedTopics.contains(topic['id']);

                    return _TopicChip(
                      label: topic['label'] as String,
                      icon: topic['icon'] as IconData,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTopics.remove(topic['id']);
                          } else {
                            _selectedTopics.add(topic['id'] as String);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Continue button
              PrimaryButton(
                label: 'Continue',
                fullWidth: true,
                onPressed: canContinue
                    ? () {
                        // Navigate to profession selection
                        Navigator.pushReplacementNamed(
                          context,
                          '/profession-selection',
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Topic selection chip widget
class _TopicChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TopicChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorders.medium,
      child: AnimatedContainer(
        duration: AppDurations.short,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppBorders.medium,
          boxShadow: isSelected ? AppShadows.small : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.bodyMedium,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
