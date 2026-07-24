import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/fill_blank_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';

/// Fill-in-the-blank question block for creating text completion questions.
///
/// Template format: wrap each target word in square brackets, e.g.:
///   "How [are] you?" → one blank; correct answer is "are".
///   "The [Sun] rises in the [east]." → two blanks.
///
/// The writer only sees a template field and an explanation field.
/// Blanks are extracted automatically from [word] markers in the background.
class FillBlankBlock extends BaseEditableBlock {
  const FillBlankBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<FillBlankBlock> createState() => _FillBlankBlockState();
}

class _FillBlankBlockState extends BaseEditableBlockState<FillBlankBlock> {
  late TextEditingController _templateController;
  late TextEditingController _explanationController;
  late FocusNode _templateFocusNode;
  late FocusNode _explanationFocusNode;
  late Debouncer _debouncer;
  List<Map<String, dynamic>> _blanks = [];

  // Regex that matches [word] placeholders in the template.
  static final _bracketRegex = RegExp(r'\[([^\]]+)\]');

  @override
  Map<String, dynamic> getDefaultContent() => {
    'questionType': 'fillInBlank',
    'template': 'The [Sun] is the closest star to Earth.',
    'blanks': [
      {
        'id': 'blank_1',
        'position': 0,
        'correctAnswers': ['Sun'],
        'caseSensitive': false,
        'acceptTypos': true,
        'maxLevenshteinDistance': 2,
      },
    ],
    'explanation': 'The Sun is the star at the center of our Solar System.',
    'showExplanation': true,
    'points': 1,
    'tags': [],
    'difficulty': 'easy',
  };

  @override
  void initializeBlockSpecifics() {
    _templateController = TextEditingController(text: content['template'] ?? '');
    _explanationController = TextEditingController(text: content['explanation'] ?? '');
    _templateFocusNode = FocusNode();
    _explanationFocusNode = FocusNode();
    _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
    _blanks = List<Map<String, dynamic>>.from(content['blanks'] ?? []);
    if (_blanks.isEmpty) {
      _blanks = List<Map<String, dynamic>>.from(
          getDefaultContent()['blanks'] as List);
    }
  }

  @override
  void onContentChanged() {
    if (_templateController.text != content['template']) {
      _templateController.text = content['template'] ?? '';
    }
    if (_explanationController.text != content['explanation']) {
      _explanationController.text = content['explanation'] ?? '';
    }
    _blanks = List<Map<String, dynamic>>.from(content['blanks'] ?? []);
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _templateController.dispose();
    _explanationController.dispose();
    _templateFocusNode.dispose();
    _explanationFocusNode.dispose();
  }

  void _saveContentLocal() {
    content['template'] = _templateController.text;
    content['explanation'] = _explanationController.text;
    content['blanks'] = _blanks;
    saveContent();
  }

  /// Parses [word] brackets from the current template and synchronizes the
  /// _blanks list. Each bracketed word becomes the correct answer for that
  /// blank; existing blanks at the same position keep their settings.
  void _syncBlanksFromTemplate() {
    final matches = _bracketRegex.allMatches(_templateController.text).toList();
    if (matches.isEmpty) {
      if (_blanks.isNotEmpty) {
        setState(() {
          _blanks = [];
        });
      }
      return;
    }

    final newBlanks = <Map<String, dynamic>>[];
    for (int i = 0; i < matches.length; i++) {
      final word = matches[i].group(1)!.trim();
      if (i < _blanks.length) {
        final existing = Map<String, dynamic>.from(_blanks[i]);
        existing['position'] = i;
        existing['correctAnswers'] = [word];
        newBlanks.add(existing);
      } else {
        newBlanks.add({
          'id': 'blank_${i + 1}',
          'position': i,
          'correctAnswers': [word],
          'caseSensitive': false,
          'acceptTypos': true,
          'maxLevenshteinDistance': 2,
        });
      }
    }

    setState(() {
      _blanks = newBlanks;
    });
  }

  @override
  Widget buildReader(BuildContext context) {
    return FillBlankReaderBlock(
      block: widget.block,
      docDir: widget.docDir,
    );
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Icon(IconsaxPlusBold.edit, size: 18,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Fill in the Blank',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Template field ───────────────────────────────────────
              TextField(
                controller: _templateController,
                focusNode: _templateFocusNode,
                maxLines: 5,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g.  How [are] you?  or  The [Sun] is a star.',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                onChanged: (_) {
                  _syncBlanksFromTemplate();
                  _debouncer.call(_saveContentLocal);
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Text(
                  'Wrap the answer word in [brackets] — it becomes the blank.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Explanation field ────────────────────────────────────
              TextField(
                controller: _explanationController,
                focusNode: _explanationFocusNode,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Explanation (optional, shown after submission)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                onChanged: (_) => _debouncer.call(_saveContentLocal),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
