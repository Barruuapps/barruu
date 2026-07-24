import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/core/utils/app_logger.dart';

import '../../../utils/json_string_converter.dart';

/// Provides controls for inserting mathematical expressions into a GraphBlock,
/// optimized for graphable functions and symbols.
class GraphControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;
  final TextEditingController expressionController;

  /// Optional callback invoked after the expression has been inserted into
  /// [expressionController].  When supplied, the default block-save logic is
  /// skipped in favour of this callback (allows callers that manage multiple
  /// equations to save the full combined expression themselves).
  final VoidCallback? onExpressionSaved;

  const GraphControls({
    super.key,
    required this.controller,
    required this.block,
    required this.expressionController,
    this.onExpressionSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GraphExpressionMenu(
      controller: controller,
      block: block,
      expressionController: expressionController,
      onExpressionSaved: onExpressionSaved,
    );
  }
}

/// A popup menu for selecting and inserting mathematical expressions for graphing.
class _GraphExpressionMenu extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;
  final TextEditingController expressionController;
  final VoidCallback? onExpressionSaved;

  const _GraphExpressionMenu({
    required this.controller,
    required this.block,
    required this.expressionController,
    this.onExpressionSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.functions_rounded, color: theme.colorScheme.primary),
      tooltip: 'Insert Graph Expressions',
      itemBuilder: (_) => _getExpressionMenuItems(),
      onSelected: (expr) =>
          _insertExpression(expr, controller, block, expressionController),
      elevation: 0.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(maxWidth: 300.0),
    );
  }

  List<PopupMenuEntry<String>> _getExpressionMenuItems() {
    return [
      _buildCategoryHeader('Common Functions'),
      _buildExpressionItem(r'x^{2}', 'x²', 'x^2'),
      _buildExpressionItem(r'x^{3}', 'x³', 'x^3'),
      _buildExpressionItem(r'\sqrt{x}', '√x', 'sqrt(x)'),
      _buildExpressionItem(r'\frac{1}{x}', '1/x', '1/x'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Trigonometric'),
      _buildExpressionItem(r'sin(x)', 'sin(x)', 'sin(x)'),
      _buildExpressionItem(r'cos(x)', 'cos(x)', 'cos(x)'),
      _buildExpressionItem(r'tan(x)', 'tan(x)', 'tan(x)'),
      _buildExpressionItem(r'asin(x)', 'asin(x)', 'asin(x)'),
      _buildExpressionItem(r'acos(x)', 'acos(x)', 'acos(x)'),
      _buildExpressionItem(r'atan(x)', 'atan(x)', 'atan(x)'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Hyperbolic'),
      _buildExpressionItem(r'sinh(x)', 'sinh(x)', 'sinh(x)'),
      _buildExpressionItem(r'cosh(x)', 'cosh(x)', 'cosh(x)'),
      _buildExpressionItem(r'tanh(x)', 'tanh(x)', 'tanh(x)'),
      _buildExpressionItem(r'asinh(x)', 'asinh(x)', 'asinh(x)'),
      _buildExpressionItem(r'acosh(x)', 'acosh(x)', 'acosh(x)'),
      _buildExpressionItem(r'atanh(x)', 'atanh(x)', 'atanh(x)'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Exponential & Log'),
      _buildExpressionItem(r'\exp(x)', 'eˣ', 'exp(x)'),
      _buildExpressionItem(r'e^{x}', 'eˣ', 'e^x'),
      _buildExpressionItem(r'\ln(x)', 'ln(x)', 'ln(x)'),
      _buildExpressionItem(r'\log(x)', 'log(x)', 'log(x)'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Other Functions'),
      _buildExpressionItem(r'|x|', '|x|', 'abs(x)'),
      _buildExpressionItem(r'\lfloor x \rfloor', '⌊x⌋', 'floor(x)'),
      _buildExpressionItem(r'\lceil x \rceil', '⌈x⌉', 'ceil(x)'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Operators'),
      _buildExpressionItem(r'+', '+', ' + '),
      _buildExpressionItem(r'-', '−', ' - '),
      _buildExpressionItem(r'*', '×', '*'),
      _buildExpressionItem(r'/', '÷', '/'),
      _buildExpressionItem(r'^', '^', '^'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Constants'),
      _buildExpressionItem(r'\pi', 'π', 'pi'),
      _buildExpressionItem(r'e', 'e', 'e'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Grouping'),
      _buildExpressionItem(r'\left( \right)', '( )', '()'),
    ];
  }

  PopupMenuItem<String> _buildExpressionItem(
    String latex,
    String preview,
    String graphExpr,
  ) {
    return PopupMenuItem<String>(
      value: graphExpr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(preview, style: const TextStyle(fontSize: 18.0)),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              latex,
              style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildCategoryHeader(String text) {
    return PopupMenuItem<String>(
      enabled: false,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
          fontSize: 14.0,
        ),
      ),
    );
  }

  void _insertExpression(
    String expr,
    EditDocumentController controller,
    Block block,
    TextEditingController expressionController,
  ) {
    Map<String, dynamic> content = {
      'expression': '',
      'caption': '',
      'min_x': '-10',
      'max_x': '10',
    };

    if (block.content.isNotEmpty) {
      try {
        content = JsonStringConverter().convertFromJsonString(block.content);
      } catch (e, stackTrace) {
        logger.e(
          'Failed to parse graph block content: $e',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    // Get the current text and cursor position
    final currentText = expressionController.text;
    final cursorPosition = expressionController.selection.start;

    // Insert the expression at the cursor position
    String newText;
    int newCursorPosition;

    // Check if expression is a function with parentheses
    if (expr.contains('(') && expr.endsWith(')')) {
      // For functions like 'sin(x)', insert as-is
      newText =
          currentText.substring(0, cursorPosition) +
          expr +
          currentText.substring(cursorPosition);
      newCursorPosition = cursorPosition + expr.length;
    } else if (expr == '()') {
      // For empty parentheses, place cursor inside
      newText =
          '${currentText.substring(0, cursorPosition)}()${currentText.substring(cursorPosition)}';
      newCursorPosition = cursorPosition + 1;
    } else if (expr.trim() == '+' || expr.trim() == '-') {
      // For operators with spaces, insert as-is
      newText =
          currentText.substring(0, cursorPosition) +
          expr +
          currentText.substring(cursorPosition);
      newCursorPosition = cursorPosition + expr.length;
    } else {
      // For everything else, insert with space if needed
      final needsSpace =
          cursorPosition < currentText.length &&
          currentText[cursorPosition] != ' ' &&
          currentText[cursorPosition] != ')';
      newText =
          currentText.substring(0, cursorPosition) +
          expr +
          (needsSpace ? ' ' : '') +
          currentText.substring(cursorPosition);
      newCursorPosition = cursorPosition + expr.length + (needsSpace ? 1 : 0);
    }

    // Update the controller's text and cursor position
    expressionController.text = newText;
    expressionController.selection = TextSelection.collapsed(
      offset: newCursorPosition,
    );

    // If an external save callback is provided (e.g. for multi-equation blocks),
    // call it instead of saving directly so the caller can combine all equations.
    if (onExpressionSaved != null) {
      onExpressionSaved!();
    } else {
      _updateBlockContent(newText, content, controller, block);
    }
  }

  void _updateBlockContent(
    String newText,
    Map<String, dynamic> content,
    EditDocumentController controller,
    Block block,
  ) {
    content['expression'] = newText;
    final newContent = JsonStringConverter().convertToJsonString(content);
    final updatedBlock = block.copyWith(content: newContent);
    controller.saveBlock(updatedBlock);
  }
}
