import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/block_empty_state.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/stepper_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/stepper_template_selector.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/stepper_templates.dart';
import 'package:barruu/features/workspace/constants/block_dimension_constants.dart';

/// Stepper block for step-by-step instructions.
///
/// Content format:
/// ```json
/// {
///   "steps": [
///     {
///       "title": "Step 1",
///       "description": "First step description"
///     }
///   ],
///   "orientation": "vertical",
///   "stepperTemplate": "standard"
/// }
/// ```
class StepperBlock extends BaseEditableBlock {
  const StepperBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<StepperBlock> createState() => _StepperBlockState();
}

class _StepperBlockState extends BaseEditableBlockState<StepperBlock> {
  late String _orientation;
  late String _stepperTemplate;
  late Debouncer _debouncer;
  final Map<int, Map<String, TextEditingController>> _stepControllers = {};

  @override
  Map<String, dynamic> getDefaultContent() => {
    'steps': [],
    'orientation': 'vertical',
    'stepperTemplate': kDefaultStepperTemplate,
  };

  @override
  void initializeBlockSpecifics() {
    _debouncer = Debouncer(delay: const Duration(milliseconds: 500));

    // Ensure steps is a list
    if (content['steps'] is! List) {
      content['steps'] = [];
    }

    _orientation = content['orientation']?.toString() ?? 'vertical';
    _stepperTemplate =
        content['stepperTemplate']?.toString() ?? kDefaultStepperTemplate;

    // Initialize controllers for existing steps
    _initializeStepControllers();
  }

  @override
  void onContentChanged() {
    _orientation = content['orientation']?.toString() ?? 'vertical';
    _stepperTemplate =
        content['stepperTemplate']?.toString() ?? kDefaultStepperTemplate;

    // Update controllers when content changes externally
    _updateStepControllers();
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _disposeStepControllers();
  }

  void _initializeStepControllers() {
    final steps = content['steps'] as List;
    for (int i = 0; i < steps.length; i++) {
      if (!_stepControllers.containsKey(i)) {
        final step = steps[i] as Map<String, dynamic>;
        _stepControllers[i] = {
          'title': TextEditingController(text: step['title']?.toString() ?? ''),
          'description': TextEditingController(
            text: step['description']?.toString() ?? '',
          ),
        };
      }
    }
  }

  void _updateStepControllers() {
    final steps = content['steps'] as List;

    // Remove controllers for steps that no longer exist
    _stepControllers.removeWhere((key, controllers) {
      if (key >= steps.length) {
        for (var controller in controllers.values) {
          controller.dispose();
        }
        return true;
      }
      return false;
    });

    // Update existing controllers and create new ones
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i] as Map<String, dynamic>;

      if (_stepControllers.containsKey(i)) {
        // Only update if text is different to avoid cursor reset
        final titleText = step['title']?.toString() ?? '';
        if (_stepControllers[i]!['title']!.text != titleText) {
          _stepControllers[i]!['title']!.text = titleText;
        }

        final descText = step['description']?.toString() ?? '';
        if (_stepControllers[i]!['description']!.text != descText) {
          _stepControllers[i]!['description']!.text = descText;
        }
      } else {
        _stepControllers[i] = {
          'title': TextEditingController(text: step['title']?.toString() ?? ''),
          'description': TextEditingController(
            text: step['description']?.toString() ?? '',
          ),
        };
      }
    }
  }

  void _disposeStepControllers() {
    for (var controllers in _stepControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    _stepControllers.clear();
  }

  void _addStep() {
    final steps = List<Map<String, dynamic>>.from(content['steps'] as List);
    final newIndex = steps.length;
    steps.add({'title': '', 'description': '', 'isCompleted': false});

    content['steps'] = steps;

    // Create controllers for new step
    _stepControllers[newIndex] = {
      'title': TextEditingController(text: ''),
      'description': TextEditingController(text: ''),
    };

    saveContent();
  }

  void _toggleStepCompletion(int index) {
    final steps = List<Map<String, dynamic>>.from(content['steps'] as List);
    if (index >= 0 && index < steps.length) {
      steps[index]['isCompleted'] =
          !((steps[index]['isCompleted'] as bool?) ?? false);
      content['steps'] = steps;
      saveContent();
    }
  }

  void _removeStep(int index) {
    final steps = List<Map<String, dynamic>>.from(content['steps'] as List);
    if (index < 0 || index >= steps.length) return;

    final removedStep = Map<String, dynamic>.from(steps[index]);
    steps.removeAt(index);
    content['steps'] = steps;

    // Dispose and remove controllers for removed step
    if (_stepControllers.containsKey(index)) {
      for (var controller in _stepControllers[index]!.values) {
        controller.dispose();
      }
      _stepControllers.remove(index);
    }

    // Reindex remaining controllers
    final newControllers = <int, Map<String, TextEditingController>>{};
    for (var entry in _stepControllers.entries) {
      if (entry.key > index) {
        newControllers[entry.key - 1] = entry.value;
      } else {
        newControllers[entry.key] = entry.value;
      }
    }
    _stepControllers.clear();
    _stepControllers.addAll(newControllers);

    setState(() {});
    saveContent();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: BlockDimensionConstants.undoSnackbarDuration,
        content: const Text('Step deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            final currentSteps = List<Map<String, dynamic>>.from(
              content['steps'] as List,
            );
            currentSteps.insert(index, removedStep);
            content['steps'] = currentSteps;

            final shifted = <int, Map<String, TextEditingController>>{};
            for (var e in _stepControllers.entries) {
              shifted[e.key >= index ? e.key + 1 : e.key] = e.value;
            }
            _stepControllers.clear();
            _stepControllers.addAll(shifted);

            setState(() {});
            saveContent();
          },
        ),
      ),
    );
  }

  void _updateStep(int index, String field, String value) {
    final steps = List<Map<String, dynamic>>.from(content['steps'] as List);
    if (index >= 0 && index < steps.length) {
      steps[index][field] = value;
      content['steps'] = steps;
      _debouncer.call(() => saveContent());
    }
  }

  void _updateOrientation(String newOrientation) {
    setState(() {
      _orientation = newOrientation;
      content['orientation'] = newOrientation;
      saveContent();
    });
  }

  void _updateStepperTemplate(String newTemplate) {
    setState(() {
      _stepperTemplate = newTemplate;
      content['stepperTemplate'] = newTemplate;
      saveContent();
    });
  }

  @override
  Widget buildReader(BuildContext context) {
    return StepperReaderBlock(
      block: widget.block,
      docDir: widget.docDir,
      allowInteraction: false,
    );
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final steps = content['steps'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stepper',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Visual template selector button
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => StepperTemplateSelector(
                              selectedTemplate: _stepperTemplate,
                              onTemplateSelected: (value) {
                                _updateStepperTemplate(value);
                                Navigator.of(context).pop();
                              },
                              theme: theme,
                            ),
                          );
                        },
                        icon: const Icon(IconsaxPlusLinear.gallery, size: 16),
                        label: Text(_getTemplateDisplayName(_stepperTemplate)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Orientation selector
                      DropdownButton<String>(
                        value: _orientation,
                        items: const [
                          DropdownMenuItem(
                            value: 'vertical',
                            child: Text('Vertical'),
                          ),
                          DropdownMenuItem(
                            value: 'horizontal',
                            child: Text('Horizontal'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _updateOrientation(value);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Steps list
              if (steps.isEmpty)
                BlockEmptyState(
                  icon: Icons.linear_scale_outlined,
                  message: 'No steps added yet',
                  actionLabel: 'Add Step',
                  onAction: _addStep,
                )
              else
                ...List.generate(steps.length, (index) {
                  final step = steps[index] as Map<String, dynamic>;
                  return _buildStepEditor(theme, step, index);
                }),

              const SizedBox(height: 16),

              // Add step button
              OutlinedButton.icon(
                onPressed: _addStep,
                icon: const Icon(IconsaxPlusLinear.add),
                label: const Text('Add Step'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepEditor(
    ThemeData theme,
    Map<String, dynamic> step,
    int index,
  ) {
    final isCompleted = (step['isCompleted'] as bool?) ?? false;

    // Ensure controllers exist for this step
    if (!_stepControllers.containsKey(index)) {
      _stepControllers[index] = {
        'title': TextEditingController(text: step['title']?.toString() ?? ''),
        'description': TextEditingController(
          text: step['description']?.toString() ?? '',
        ),
      };
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleStepCompletion(index),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _stepControllers[index]!['title'],
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                        : null,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Step title',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) => _updateStep(index, 'title', value),
                ),
              ),
              IconButton(
                icon: const Icon(IconsaxPlusLinear.trash, size: 18),
                onPressed: () => _removeStep(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: theme.colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: TextField(
              controller: _stepControllers[index]!['description'],
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                    : null,
              ),
              decoration: const InputDecoration(
                hintText: 'Step description',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              onChanged: (value) => _updateStep(index, 'description', value),
            ),
          ),
        ],
      ),
    );
  }

  String _getTemplateDisplayName(String template) {
    return kStepperTemplateNames[template] ??
        kStepperTemplateNames[kDefaultStepperTemplate]!;
  }
}
