import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/constants/design_tokens.dart';
import 'package:barruu/core/utils/error_handler.dart';
import 'package:barruu/core/utils/ui_utils.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';

/// Base widget for all editable block types.
///
/// This provides a common interface for blocks that can be edited and displayed
/// in both edit and read-only modes. It handles common properties like the block
/// data, editing state, and document directory.
///
/// Usage:
/// ```dart
/// class MyBlock extends BaseEditableBlock {
///   const MyBlock({
///     required super.block,
///     required super.isEditing,
///     required super.docDir,
///     super.key,
///   });
///
///   @override
///   ConsumerState<MyBlock> createState() => _MyBlockState();
/// }
///
/// class _MyBlockState extends BaseEditableBlockState<MyBlock> {
///   @override
///   Map<String, dynamic> getDefaultContent() => {"text": ""};
///
///   @override
///   Widget buildEditor(BuildContext context) {
///     // Build editing UI
///   }
///
///   @override
///   Widget buildReader(BuildContext context) {
///     // Build read-only UI
///   }
/// }
/// ```
abstract class BaseEditableBlock extends ConsumerStatefulWidget {
  /// The block data containing content, type, and style
  final Block block;

  /// Whether the block is currently in editing mode
  final bool isEditing;

  /// The document directory for storing media and other assets
  final Directory docDir;

  const BaseEditableBlock({
    required this.block,
    required this.isEditing,
    required this.docDir,
    super.key,
  });
}

/// Base state for all editable blocks with common lifecycle and utility methods.
///
/// This abstract class provides:
/// - Common state management (content parsing, animation)
/// - Lifecycle hooks (initialization, updates, disposal)
/// - Utility methods (save content, show messages)
/// - Template methods for subclasses to implement
///
/// Subclasses must implement:
/// - [getDefaultContent] - Default content structure for the block type
/// - [buildEditor] - UI for editing mode
/// - [buildReader] - UI for read-only mode
///
/// Subclasses can optionally override:
/// - [initializeBlockSpecifics] - Initialize block-specific state
/// - [disposeBlockSpecifics] - Dispose block-specific resources
/// - [onContentChanged] - React to content changes
/// - [getAnimationDuration] - Customize animation duration
/// - [getAnimationCurve] - Customize animation curve
abstract class BaseEditableBlockState<T extends BaseEditableBlock>
    extends ConsumerState<T>
    with SingleTickerProviderStateMixin {
  // ============================================================================
  // STATE
  // ============================================================================

  /// Animation controller for toolbar and transitions
  late AnimationController animationController;

  /// Opacity animation for toolbar
  late Animation<double> toolbarOpacity;

  /// Current content of the block as a Map
  late Map<String, dynamic> content;

  /// JSON converter for parsing and serializing content
  final jsonConverter = JsonStringConverter();

  // ============================================================================
  // TEMPLATE METHODS (must be implemented by subclasses)
  // ============================================================================

  /// Returns the default content structure for this block type.
  ///
  /// This is used when the block content is empty or fails to parse.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, dynamic> getDefaultContent() => {
  ///   "text": "",
  ///   "alignment": "left",
  /// };
  /// ```
  @protected
  Map<String, dynamic> getDefaultContent();

  /// Builds the editing UI for this block.
  ///
  /// Called when [widget.isEditing] is true.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildEditor(BuildContext context) {
  ///   return TextField(
  ///     controller: _textController,
  ///     onChanged: (value) {
  ///       content['text'] = value;
  ///       saveContent();
  ///     },
  ///   );
  /// }
  /// ```
  @protected
  Widget buildEditor(BuildContext context);

  /// Builds the read-only UI for this block.
  ///
  /// Called when [widget.isEditing] is false.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildReader(BuildContext context) {
  ///   return Text(content['text'] ?? '');
  /// }
  /// ```
  @protected
  Widget buildReader(BuildContext context);

  // ============================================================================
  // OPTIONAL HOOKS (can be overridden by subclasses)
  // ============================================================================

  /// Initialize block-specific state.
  ///
  /// Called after common initialization in [initState].
  /// Use this to initialize controllers, focus nodes, etc.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void initializeBlockSpecifics() {
  ///   _textController = TextEditingController(
  ///     text: content['text'] ?? '',
  ///   );
  ///   _focusNode = FocusNode();
  /// }
  /// ```
  @protected
  void initializeBlockSpecifics() {}

  /// Dispose block-specific resources.
  ///
  /// Called before common disposal in [dispose].
  /// Use this to dispose controllers, focus nodes, etc.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void disposeBlockSpecifics() {
  ///   _textController.dispose();
  ///   _focusNode.dispose();
  /// }
  /// ```
  @protected
  void disposeBlockSpecifics() {}

  /// Called when content changes.
  ///
  /// Override this to react to content updates.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void onContentChanged() {
  ///   _textController.text = content['text'] ?? '';
  /// }
  /// ```
  @protected
  void onContentChanged() {}

  /// Returns the animation duration for this block.
  ///
  /// Override to customize animation timing.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Duration getAnimationDuration() => DesignTokens.durationFast;
  /// ```
  @protected
  Duration getAnimationDuration() => DesignTokens.durationMedium;

  /// Returns the animation curve for this block.
  ///
  /// Override to customize animation easing.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Curve getAnimationCurve() => DesignTokens.curveEmphasized;
  /// ```
  @protected
  Curve getAnimationCurve() => DesignTokens.curveStandard;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _initializeContent();
    _setupAnimations();
    initializeBlockSpecifics();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleContentUpdate(oldWidget);
    _handleEditingStateChange(oldWidget);
  }

  @override
  void dispose() {
    disposeBlockSpecifics();
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isEditing ? buildEditor(context) : buildReader(context);
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Initializes content from block JSON or uses default.
  void _initializeContent() {
    content = parseJsonContent(widget.block.content, getDefaultContent());
  }

  /// Sets up animation controller and toolbar opacity animation.
  void _setupAnimations() {
    animationController = AnimationController(
      vsync: this,
      duration: getAnimationDuration(),
    );
    toolbarOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: getAnimationCurve()),
    );
    if (widget.isEditing) {
      animationController.forward();
    }
  }

  /// Handles content updates when widget is updated.
  void _handleContentUpdate(T oldWidget) {
    if (oldWidget.block.content != widget.block.content) {
      final newContent = parseJsonContent(
        widget.block.content,
        getDefaultContent(),
      );
      if (newContent != content) {
        setState(() => content = newContent);
        onContentChanged();
      }
    }
  }

  /// Handles editing state changes when widget is updated.
  void _handleEditingStateChange(T oldWidget) {
    if (widget.isEditing && !oldWidget.isEditing) {
      // Entering edit mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        animationController.forward();
      });
    } else if (!widget.isEditing && oldWidget.isEditing) {
      // Exiting edit mode
      animationController.reverse();
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Parses JSON content with error handling.
  ///
  /// Returns the parsed content or [defaultContent] if parsing fails.
  /// Logs errors using [ErrorHandler].
  ///
  /// Example:
  /// ```dart
  /// final data = parseJsonContent(
  ///   '{"text": "Hello"}',
  ///   {"text": ""},
  /// );
  /// ```
  @protected
  Map<String, dynamic> parseJsonContent(
    String? json,
    Map<String, dynamic> defaultContent,
  ) {
    if (json == null || json.isEmpty) return defaultContent;

    try {
      return jsonConverter.convertFromJsonString(json);
    } catch (e, stackTrace) {
      ErrorHandler.handle(
        e,
        stackTrace,
        context: context,
        userMessage: 'Error loading block content',
      );
      return defaultContent;
    }
  }

  /// Saves the current content to the repository.
  ///
  /// Converts [content] to JSON, updates the block, and persists changes.
  /// Shows error message if save fails.
  ///
  /// Example:
  /// ```dart
  /// content['text'] = newText;
  /// await saveContent();
  /// ```
  @protected
  Future<void> saveContent() async {
    try {
      final jsonString = jsonConverter.convertToJsonString(content);
      final updatedBlock = widget.block.copyWith(content: jsonString);
      await ref
          .read(editDocumentControllerProvider(widget.docDir).notifier)
          .saveBlock(updatedBlock);
      onContentChanged();
    } catch (e, stackTrace) {
      if (!mounted) return;
      // Silently ignore database_closed — happens when the DB is being torn
      // down (e.g., app lifecycle change) and does not indicate a real error.
      if (e.toString().toLowerCase().contains('database_closed')) return;
      ErrorHandler.handle(
        e,
        stackTrace,
        context: context,
        userMessage: 'Error saving block content',
      );
    }
  }

  /// Shows a success message to the user.
  ///
  /// Example:
  /// ```dart
  /// showSuccess('Image uploaded successfully');
  /// ```
  @protected
  void showSuccess(String message) {
    if (mounted) {
      UIUtils.showSnackBar(context, message);
    }
  }

  /// Shows an error message to the user.
  ///
  /// Example:
  /// ```dart
  /// showError('Failed to upload image');
  /// ```
  @protected
  void showError(String message) {
    if (mounted) {
      UIUtils.showSnackBar(context, message, isError: true);
    }
  }

  /// Validates that a value is not null or empty.
  ///
  /// Shows an error message if validation fails unless [showError] is false.
  ///
  /// Example:
  /// ```dart
  /// // With automatic error display
  /// if (validateNotEmpty(title, 'Title')) {
  ///   // Proceed with valid title
  /// }
  ///
  /// // Without automatic error display (custom handling)
  /// if (!validateNotEmpty(title, 'Title', showError: false)) {
  ///   // Handle error custom way
  /// }
  /// ```
  @protected
  bool validateNotEmpty(
    String? value,
    String fieldName, {
    bool showError = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (showError) {
        this.showError('$fieldName cannot be empty');
      }
      return false;
    }
    return true;
  }
}
