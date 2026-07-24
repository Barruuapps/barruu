import 'package:flutter/material.dart';

/// Dialog for renaming a page.
///
/// Displays a text field for entering a new page title and returns
/// the entered value when confirmed, or null if cancelled.
///
/// Example:
/// ```dart
/// final newTitle = await showPageRenameDialog(
///   context: context,
///   initialTitle: 'Old Title',
/// );
/// if (newTitle != null) {
///   // Use the new title
/// }
/// ```
Future<String?> showPageRenameDialog({
  required BuildContext context,
  required String initialTitle,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _RenamePageDialog(initialTitle: initialTitle),
  );
}

/// Stateful dialog for renaming a page.
/// Manages its own TextEditingController lifecycle to avoid disposal issues.
class _RenamePageDialog extends StatefulWidget {
  final String initialTitle;

  const _RenamePageDialog({required this.initialTitle});

  @override
  State<_RenamePageDialog> createState() => _RenamePageDialogState();
}

class _RenamePageDialogState extends State<_RenamePageDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename Page'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Page Title',
          hintText: 'Enter page title',
        ),
        autofocus: true,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
