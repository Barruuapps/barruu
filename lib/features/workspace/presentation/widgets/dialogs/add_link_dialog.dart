import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog for adding/editing links in paragraph blocks
class AddLinkDialog extends ConsumerStatefulWidget {
  final String? initialText;
  final String? initialUrl;

  const AddLinkDialog({
    super.key,
    this.initialText,
    this.initialUrl,
  });

  @override
  ConsumerState<AddLinkDialog> createState() => _AddLinkDialogState();
}

class _AddLinkDialogState extends ConsumerState<AddLinkDialog> {
  late TextEditingController _textController;
  late TextEditingController _urlController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
    _urlController = TextEditingController(text: widget.initialUrl ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a URL';
    }
    
    final urlPattern = RegExp(
      r'^https?://[^\s]+$',
      caseSensitive: false,
    );
    
    if (!urlPattern.hasMatch(value.trim())) {
      return 'Please enter a valid URL (e.g., https://example.com)';
    }
    
    return null;
  }

  String? _validateText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter display text';
    }
    return null;
  }

  void _handleAdd() {
    if (_formKey.currentState?.validate() ?? false) {
      final text = _textController.text.trim();
      final url = _urlController.text.trim();
      
      // Return markdown-formatted link
      Navigator.of(context).pop('[$text]($url)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text(
        'Add Link',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Display Text',
                hintText: 'e.g., Click here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.text_fields),
              ),
              validator: _validateText,
              textInputAction: TextInputAction.next,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.link),
              ),
              validator: _validateUrl,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleAdd(),
            ),
            const SizedBox(height: 8),
            Text(
              'The link will be inserted as: [Display Text](URL)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _handleAdd,
          child: const Text('Add Link'),
        ),
      ],
    );
  }
}
