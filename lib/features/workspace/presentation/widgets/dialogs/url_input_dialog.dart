import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Dialog for entering a URL for media import
class UrlInputDialog {
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String? hint,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'URL',
              hintText: hint ?? 'https://example.com/media',
              prefixIcon: const Icon(IconsaxPlusLinear.link),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a URL';
              }
              final uri = Uri.tryParse(value.trim());
              if (uri == null ||
                  !uri.hasScheme ||
                  (!uri.scheme.startsWith('http'))) {
                return 'Please enter a valid URL';
              }
              return null;
            },
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (value) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, controller.text.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
