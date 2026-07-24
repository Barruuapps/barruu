import 'dart:io';
import 'package:barruu/core/constants/design_tokens.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/utils/ui_utils.dart';
import 'package:barruu/core/utils/string_utils.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/presentation/controllers/documents_controller.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';

/// Template type for document creation
enum DocTemplate {
  blank(
    'Blank Document',
    IconsaxPlusLinear.document_text,
    'A clean slate to start from scratch',
    'Start with an empty page',
  ),
  meetingNotes(
    'Meeting Notes',
    IconsaxPlusLinear.calendar_2,
    'Structured meeting notes with agenda',
    'Capture decisions and action items',
  ),
  lectureNotes(
    'Lecture Notes',
    IconsaxPlusLinear.book,
    'Organized study notes with highlights',
    'Review and retain knowledge',
  ),
  book(
    'Book',
    IconsaxPlusLinear.book_square,
    'Long-form structured content',
    'Write chapters and sections',
  ),
  research(
    'Research',
    IconsaxPlusLinear.search_normal,
    'References, methodology, findings',
    'Academic and professional research',
  ),
  documentation(
    'Documentation',
    IconsaxPlusLinear.code_1,
    'Technical docs with code blocks',
    'API docs, guides, references',
  ),
  course(
    'Course',
    IconsaxPlusLinear.teacher,
    'Interactive learning content',
    'Lessons, quizzes, and exercises',
  ),
  journal(
    'Journal',
    IconsaxPlusLinear.edit,
    'Personal daily entries',
    'Track thoughts and reflections',
  ),
  checklist(
    'Checklist',
    IconsaxPlusLinear.task_square,
    'Task lists with due dates',
    'Manage projects and todos',
  ),
  kanban(
    'Kanban',
    IconsaxPlusLinear.element_3,
    'Visual board for workflows',
    'Track progress visually',
  );

  const DocTemplate(this.label, this.icon, this.description, this.exampleUse);
  final String label;
  final IconData icon;
  final String description;
  final String exampleUse;
}

// Suggested color themes for documents
const _themeColors = [
  Color(0xFF0F766E), // Teal (default)
  Color(0xFF7C3AED), // Purple
  Color(0xFF0284C7), // Blue
  Color(0xFF16A34A), // Green
  Color(0xFFEA580C), // Orange
  Color(0xFFDC2626), // Red
  Color(0xFF4F46E5), // Indigo
  Color(0xFF18181B), // Dark
];

class CreateDocumentScreen extends ConsumerStatefulWidget {
  const CreateDocumentScreen({super.key});

  @override
  ConsumerState<CreateDocumentScreen> createState() =>
      _CreateDocumentScreenState();
}

class _CreateDocumentScreenState extends ConsumerState<CreateDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  File? _coverImage;
  String? _coverImageOriginalName;
  bool _isSubmitting = false;

  DocTemplate? _selectedTemplate;
  Color _selectedColor = _themeColors[0];
  String _emoji = '📄';

  // Emoji picker state
  bool _showEmojiPicker = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _handleImageSelection() async {
    if (kIsWeb) {
      _showSnackBar('Image picking not supported on web', isError: true);
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() {
          _coverImage = File(picked.path);
          _coverImageOriginalName = picked.name;
        });
      }
    } catch (e, stackTrace) {
      logger.e('Failed to select image', error: e, stackTrace: stackTrace);
      if (mounted) _showSnackBar('Failed to select image: $e', isError: true);
    }
  }

  void _selectTemplate(DocTemplate template) {
    setState(() {
      _selectedTemplate = template;
      if (_nameController.text.isEmpty) {
        _nameController.text = template.label;
      }
      _emoji = _templateEmoji(template);
    });
  }

  String _templateEmoji(DocTemplate t) {
    switch (t) {
      case DocTemplate.blank:
        return '📄';
      case DocTemplate.meetingNotes:
        return '📋';
      case DocTemplate.lectureNotes:
        return '📖';
      case DocTemplate.book:
        return '📚';
      case DocTemplate.research:
        return '🔬';
      case DocTemplate.documentation:
        return '📘';
      case DocTemplate.course:
        return '🎓';
      case DocTemplate.journal:
        return '📓';
      case DocTemplate.checklist:
        return '✅';
      case DocTemplate.kanban:
        return '📌';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShimmerCircularProgress(
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Creating document...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final documentService = ref.read(documentServiceProvider);
      final docDir = await documentService.createDocument(
        StringUtils.limitLength(_nameController.text.trim()),
        StringUtils.limitLength(_descriptionController.text.trim()),
        StringUtils.limitLength(_tagsController.text.trim()),
        coverImage: _coverImage,
        coverImageOriginalName: _coverImageOriginalName,
      );
      if (mounted) {
        Navigator.of(context).pop();
        if (docDir != null) {
          context.pop();
          ref.read(documentsProvider.notifier).loadDocuments();
          final docPath = Uri.encodeComponent(docDir.path);
          context.push('/edit-document/$docPath');
          _showSnackBar('"${_nameController.text}" created successfully');
        } else {
          _showSnackBar('Document creation failed', isError: true);
        }
      }
    } catch (e, stackTrace) {
      logger.e('Document creation failed', error: e, stackTrace: stackTrace);
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Document creation failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    UIUtils.showSnackBar(context, message, isError: isError);
  }

  Future<void> _handlePopRequest() async {
    if (!_isSubmitting) {
      if (mounted) context.pop();
      return;
    }
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
        ),
        title: const Text('Cancel Creation'),
        content: const Text(
          'A document is being created. Are you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (shouldPop == true && mounted) {
      context.pop();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_isSubmitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handlePopRequest();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: _buildAppBar(theme),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spacing16,
                DesignTokens.spacing8,
                DesignTokens.spacing16,
                DesignTokens.spacing40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: DesignTokens.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Emoji + Title
                      _buildTitleSection(theme),
                      const SizedBox(height: DesignTokens.spacing24),
                      // Cover image
                      _buildCoverImage(theme),
                      const SizedBox(height: DesignTokens.spacing24),
                      // Template selector
                      _buildTemplateSelector(theme),
                      const SizedBox(height: DesignTokens.spacing24),
                      // Color theme picker
                      _buildColorThemePicker(theme),
                      const SizedBox(height: DesignTokens.spacing24),
                      // Description
                      _buildDescriptionField(theme),
                      const SizedBox(height: DesignTokens.spacing16),
                      // Tags
                      _buildTagsField(theme),
                      const SizedBox(height: DesignTokens.spacing32),
                      // Submit
                      _buildSubmitButton(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Create Document',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: DesignTokens.weightBold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          IconsaxPlusLinear.arrow_left,
          color: theme.colorScheme.primary,
        ),
        onPressed: _isSubmitting ? null : () => context.pop(),
        tooltip: 'Back',
      ),
    );
  }

  // ─── Title with Emoji ────────────────────────────────────────────────

  Widget _buildTitleSection(ThemeData theme) {
    return Column(
      children: [
        // Emoji picker
        GestureDetector(
          onTap: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
          child: Container(
            width: DesignTokens.icon3XLarge + 32,
            height: DesignTokens.icon3XLarge + 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DesignTokens.radius2XLarge),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Center(
              child: Text(_emoji, style: const TextStyle(fontSize: 40)),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacing4),
        Text(
          'Tap emoji to change',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (_showEmojiPicker) ...[
          const SizedBox(height: DesignTokens.spacing8),
          _buildEmojiGrid(theme),
        ],
        const SizedBox(height: DesignTokens.spacing16),
        // Title field
        TextFormField(
          controller: _nameController,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: DesignTokens.weightBold,
            color: theme.colorScheme.onSurface,
            height: DesignTokens.lineHeightHeading,
          ),
          decoration: InputDecoration(
            hintText: 'Untitled Document',
            hintStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: DesignTokens.weightBold,
              color: theme.colorScheme.onSurface.withValues(
                alpha: DesignTokens.opacityInactive,
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacing16,
              vertical: DesignTokens.spacing8,
            ),
          ),
          enabled: !_isSubmitting,
          maxLength: 245,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a document name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmojiGrid(ThemeData theme) {
    final emojis = [
      '📄',
      '📋',
      '📖',
      '📚',
      '🔬',
      '📘',
      '🎓',
      '📓',
      '✅',
      '📌',
      '📝',
      '💡',
      '🎯',
      '🚀',
      '💻',
      '🎨',
      '📊',
      '🗂️',
      '✍️',
      '🧠',
    ];
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: DesignTokens.spacing8,
        runSpacing: DesignTokens.spacing8,
        children: emojis.map((e) {
          final isSelected = e == _emoji;
          return GestureDetector(
            onTap: () {
              setState(() {
                _emoji = e;
                _showEmojiPicker = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spacing8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              ),
              child: Text(e, style: const TextStyle(fontSize: 28)),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Cover Image ─────────────────────────────────────────────────────

  Widget _buildCoverImage(ThemeData theme) {
    final imageHeight = 180.0;
    return GestureDetector(
      onTap: kIsWeb || _isSubmitting ? null : _handleImageSelection,
      child: Container(
        height: imageHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
          color: theme.colorScheme.surfaceContainer,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
          child: _coverImage != null && !kIsWeb
              ? Image.file(
                  _coverImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _coverPlaceholder(theme),
                )
              : _coverPlaceholder(theme),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          IconsaxPlusLinear.gallery,
          size: DesignTokens.icon3XLarge,
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: DesignTokens.spacing8),
        Text(
          kIsWeb ? 'Cover not supported on web' : 'Tap to add cover image',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!kIsWeb)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.spacing4),
            child: Text(
              'Recommended: 1200×800px',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: DesignTokens.opacitySubtle,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Template Selector ───────────────────────────────────────────────

  Widget _buildTemplateSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: DesignTokens.spacing4,
            bottom: DesignTokens.spacing12,
          ),
          child: Text(
            'Choose a template',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: DesignTokens.weightSemiBold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: DocTemplate.values.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: DesignTokens.spacing12),
            itemBuilder: (context, index) {
              final t = DocTemplate.values[index];
              final isSelected = _selectedTemplate == t;
              return _TemplateCard(
                template: t,
                isSelected: isSelected,
                onTap: () => _selectTemplate(t),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Color Theme Picker ──────────────────────────────────────────────

  Widget _buildColorThemePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: DesignTokens.spacing4,
            bottom: DesignTokens.spacing12,
          ),
          child: Text(
            'Accent color',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: DesignTokens.weightSemiBold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Wrap(
          spacing: DesignTokens.spacing12,
          runSpacing: DesignTokens.spacing8,
          children: _themeColors.map((c) {
            final isSelected = c == _selectedColor;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = c),
              child: AnimatedContainer(
                duration: DesignTokens.durationFast,
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? c : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: c.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: DesignTokens.iconSmall,
                        color: Colors.white,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Fields ──────────────────────────────────────────────────────────

  Widget _buildDescriptionField(ThemeData theme) {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'What is this document about?',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer,
      ),
      enabled: !_isSubmitting,
      maxLines: 3,
      maxLength: 245,
    );
  }

  Widget _buildTagsField(ThemeData theme) {
    return TextFormField(
      controller: _tagsController,
      decoration: InputDecoration(
        labelText: 'Tags (comma-separated)',
        hintText: 'fiction, technology, science',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer,
      ),
      enabled: !_isSubmitting,
      maxLength: 245,
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return FilledButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacing16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        ),
      ),
      child: _isSubmitting
          ? SizedBox(
              height: 24,
              width: 24,
              child: ShimmerCircularProgress(
                size: 24,
                color: theme.colorScheme.onPrimary,
              ),
            )
          : Text(
              'Create Document',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: DesignTokens.weightSemiBold,
              ),
            ),
    );
  }
}

// ─── Template Card ────────────────────────────────────────────────────

class _TemplateCard extends StatefulWidget {
  final DocTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesignTokens.durationHover,
          width: 160,
          padding: const EdgeInsets.all(DesignTokens.spacing16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : _isHovered
                ? theme.colorScheme.surfaceContainerHigh
                : theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
            border: Border.all(
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : _isHovered
                  ? theme.colorScheme.outline
                  : theme.colorScheme.outlineVariant,
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(
                        alpha: isDark ? 0.08 : 0.06,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                ),
                child: Icon(
                  widget.template.icon,
                  size: DesignTokens.iconCompact,
                  color: widget.isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.spacing12),
              Text(
                widget.template.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: DesignTokens.weightSemiBold,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: DesignTokens.spacing4),
              Expanded(
                child: Text(
                  widget.template.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: DesignTokens.opacitySubtle,
                    ),
                    height: DesignTokens.lineHeightLabel,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
