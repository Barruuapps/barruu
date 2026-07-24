import 'dart:io';
import 'package:barruu/features/workspace/domain/entities/page.dart';
import 'package:barruu/features/workspace/presentation/services/page_navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Shows a dialog for selecting a page to link to.
///
/// Displays all available pages in the document except the current page.
/// Shows which pages are already referenced by other page blocks.
///
/// Returns the selected [DocumentPage] or null if cancelled.
///
/// Example:
/// ```dart
/// final selectedPage = await showPageSelectorDialog(
///   context: context,
///   docDir: docDir,
///   currentPageId: 'page_1',
///   navigationService: pageNavService,
/// );
/// if (selectedPage != null) {
///   // Use the selected page
/// }
/// ```
Future<DocumentPage?> showPageSelectorDialog({
  required BuildContext context,
  required Directory docDir,
  required String currentPageId,
  required PageNavigationService navigationService,
}) async {
  try {
    final allPages = await navigationService.getAllPages(docDir);
    
    // Filter out the current page to avoid circular references
    final availablePages = allPages
        .where((page) => page.id != currentPageId)
        .toList();
    
    if (availablePages.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No other pages available to link')),
        );
      }
      return null;
    }
    
    // Get referenced page IDs
    final referencedPageIds = await navigationService.getReferencedPageIds(docDir);
    
    if (!context.mounted) return null;
    
    return await showDialog<DocumentPage>(
      context: context,
      builder: (context) => _PageSelectorDialog(
        availablePages: availablePages,
        referencedPageIds: referencedPageIds,
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pages: $e')),
      );
    }
    return null;
  }
}

/// Dialog widget for page selection.
class _PageSelectorDialog extends StatelessWidget {
  final List<DocumentPage> availablePages;
  final Set<String> referencedPageIds;

  const _PageSelectorDialog({
    required this.availablePages,
    required this.referencedPageIds,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Page to Link'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    IconsaxPlusLinear.info_circle,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select a page to link. Pages already linked will show a reference indicator.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availablePages.length,
                itemBuilder: (context, index) {
                  final page = availablePages[index];
                  final isReferenced = referencedPageIds.contains(page.id);
                  
                  return ListTile(
                    leading: Icon(
                      page.isDrawerPage ? IconsaxPlusLinear.document : IconsaxPlusLinear.folder_open,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(page.title)),
                        if (isReferenced)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  IconsaxPlusLinear.link_1,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Linked',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(page.isDrawerPage ? 'Main Page' : 'Nested Page'),
                    onTap: () => Navigator.of(context).pop(page),
                  );
                },
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
      ],
    );
  }
}
