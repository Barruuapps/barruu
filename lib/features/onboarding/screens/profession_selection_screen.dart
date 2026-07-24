import 'package:flutter/material.dart';
import 'package:barruu/core/theme/design_tokens.dart';
import 'package:barruu/core/widgets/buttons/primary_button.dart';

/// Profession selection screen for onboarding
/// Helps personalize content and establish credibility
class ProfessionSelectionScreen extends StatefulWidget {
  const ProfessionSelectionScreen({super.key});

  @override
  State<ProfessionSelectionScreen> createState() =>
      _ProfessionSelectionScreenState();
}

class _ProfessionSelectionScreenState extends State<ProfessionSelectionScreen> {
  String? _selectedProfession;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredProfessions = [];

  static const _professions = [
    {'id': 'writer', 'label': 'Writer', 'icon': Icons.edit},
    {'id': 'developer', 'label': 'Developer', 'icon': Icons.code},
    {'id': 'designer', 'label': 'Designer', 'icon': Icons.palette},
    {'id': 'researcher', 'label': 'Researcher', 'icon': Icons.science},
    {'id': 'doctor', 'label': 'Doctor', 'icon': Icons.local_hospital},
    {'id': 'lawyer', 'label': 'Lawyer', 'icon': Icons.gavel},
    {'id': 'teacher', 'label': 'Teacher', 'icon': Icons.school},
    {'id': 'entrepreneur', 'label': 'Entrepreneur', 'icon': Icons.business},
    {'id': 'engineer', 'label': 'Engineer', 'icon': Icons.engineering},
    {'id': 'artist', 'label': 'Artist', 'icon': Icons.brush},
    {'id': 'journalist', 'label': 'Journalist', 'icon': Icons.article},
    {'id': 'student', 'label': 'Student', 'icon': Icons.school_outlined},
    {'id': 'other', 'label': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _filteredProfessions = List.from(_professions);
    _searchController.addListener(_filterProfessions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProfessions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProfessions = List.from(_professions);
      } else {
        _filteredProfessions = _professions
            .where((p) => (p['label'] as String).toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigate to home without selection
              Navigator.pushReplacementNamed(context, '/');
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
                'What do you do?',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This helps us personalize your experience',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search professions...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: AppBorders.medium,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Profession list
              Expanded(
                child: _filteredProfessions.isEmpty
                    ? Center(
                        child: Text(
                          'No professions found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredProfessions.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          color: AppColors.border,
                        ),
                        itemBuilder: (context, index) {
                          final profession = _filteredProfessions[index];
                          final isSelected =
                              _selectedProfession == profession['id'];

                          return _ProfessionListItem(
                            label: profession['label'] as String,
                            icon: profession['icon'] as IconData,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedProfession = profession['id'] as String;
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
                onPressed: _selectedProfession != null
                    ? () {
                        // Navigate to home
                        Navigator.pushReplacementNamed(context, '/');
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

/// Profession list item widget
class _ProfessionListItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfessionListItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surface,
                borderRadius: AppBorders.small,
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTypography.bodyMedium,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
