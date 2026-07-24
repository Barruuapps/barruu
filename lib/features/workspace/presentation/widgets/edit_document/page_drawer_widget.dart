import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/core/utils/ui_utils.dart';
import 'package:barruu/features/workspace/domain/entities/page.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';

/// The default icon option (no icon).
const Map<String, dynamic> _defaultIconOption = {'name': 'none', 'icon': null, 'label': 'No Icon'};

/// Available page icon options with their display names.
/// Default is 'none' which means no icon is shown.
const List<Map<String, dynamic>> drawerPageIconOptions = [
  _defaultIconOption,
  {'name': 'document', 'icon': IconsaxPlusLinear.document_text, 'label': 'Document'},
  {'name': 'folder', 'icon': IconsaxPlusLinear.folder_2, 'label': 'Folder'},
  {'name': 'note', 'icon': IconsaxPlusLinear.note, 'label': 'Note'},
  {'name': 'bookmark', 'icon': IconsaxPlusLinear.bookmark, 'label': 'Bookmark'},
  {'name': 'clipboard', 'icon': IconsaxPlusLinear.clipboard_text, 'label': 'Clipboard'},
  {'name': 'archive', 'icon': IconsaxPlusLinear.archive_book, 'label': 'Archive'},
  {'name': 'star', 'icon': IconsaxPlusLinear.star, 'label': 'Star'},
  {'name': 'heart', 'icon': IconsaxPlusLinear.heart, 'label': 'Heart'},
  {'name': 'category', 'icon': IconsaxPlusLinear.category, 'label': 'Category'},
  {'name': 'tag', 'icon': IconsaxPlusLinear.tag, 'label': 'Tag'},
];

/// Finds a page icon option by name.
/// Returns the default 'none' option if not found.
Map<String, dynamic> _findIconOption(String? iconName) {
  if (iconName == null || iconName.isEmpty) return _defaultIconOption;
  return drawerPageIconOptions.firstWhere(
    (option) => option['name'] == iconName,
    orElse: () => _defaultIconOption,
  );
}

/// Gets the icon for a page based on its icon name.
/// Returns null if no icon is set (default).
IconData? getDrawerPageIcon(String? iconName) {
  if (iconName == null || iconName.isEmpty || iconName == 'none') return null;
  return _findIconOption(iconName)['icon'] as IconData?;
}

/// A drawer widget for managing document pages.
///
/// This widget displays a list of pages in the current document and provides
/// functionality to add, edit, and delete pages. It automatically filters to
/// show only root-level pages (drawer pages) and highlights the currently
/// active page.
///
/// The widget includes:
/// - A header with navigation back to workspace
/// - A scrollable list of pages with optional icons
/// - A dropdown menu (...) for page actions: rename, change icon, delete
/// - An "Add New Page" button at the bottom of the list
class PageDrawerWidget extends ConsumerWidget {
  /// The document directory for which to display pages.
  final Directory docDir;

  /// Creates a page drawer widget.
  ///
  /// [docDir] is the directory of the document whose pages should be displayed.
  const PageDrawerWidget({
    super.key,
    required this.docDir,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final documentService = ref.watch(documentServiceProvider);

    return Drawer(
      child: FutureBuilder<List<DocumentPage>>(
        future: documentService.getDocumentPages(docDir),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: ShimmerCircularProgress(
                color: theme.colorScheme.primary,
              ),
            );
          }

          final allPages = snapshot.data!;
          // Filter to show only drawer pages (root pages without parent)
          final drawerPages = allPages.where((page) => page.isDrawerPage).toList();
          final currentPageId = ref.watch(currentPageIdProvider(docDir.path));

          return Column(
            children: [
              _buildHeader(context, theme),
              Expanded(
                child: _buildPageList(
                  context,
                  ref,
                  theme,
                  drawerPages,
                  currentPageId,
                  documentService,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the drawer header with title and navigation button.
  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pages',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              IconButton(
                icon: Icon(IconsaxPlusLinear.home, color: theme.colorScheme.primary),
                tooltip: 'Back to Workspace',
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable list of pages.
  Widget _buildPageList(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<DocumentPage> drawerPages,
    String? currentPageId,
    DocumentService documentService,
  ) {
    return ListView.builder(
      itemCount: drawerPages.length + 1, // +1 for add page tile
      itemBuilder: (context, index) {
        // Last item is the "Add Page" tile
        if (index == drawerPages.length) {
          return _buildAddPageTile(context, ref, theme, drawerPages, documentService);
        }

        final page = drawerPages[index];
        return _buildPageTile(context, ref, theme, page, currentPageId, drawerPages, documentService);
      },
    );
  }

  /// Builds the "Add New Page" tile.
  Widget _buildAddPageTile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    List<DocumentPage> drawerPages,
    DocumentService documentService,
  ) {
    return ListTile(
      leading: Icon(IconsaxPlusLinear.add_circle, color: theme.colorScheme.primary),
      title: Text(
        'Add New Page',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () async {
        final drawerPageCount = drawerPages.length + 1;
        final defaultTitle = 'Page $drawerPageCount';
        final newPage = await documentService.createPage(docDir, defaultTitle);

        if (newPage != null && context.mounted) {
          UIUtils.showSnackBar(context, 'Page "${newPage.displayTitle}" created');
          ref.read(currentPageIdProvider(docDir.path).notifier).state = newPage.id;
          Navigator.pop(context);
        } else if (context.mounted) {
          UIUtils.showSnackBar(context, 'Failed to create page', isError: true);
        }
      },
    );
  }

  /// Builds a tile for an individual page.
  Widget _buildPageTile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    DocumentPage page,
    String? currentPageId,
    List<DocumentPage> drawerPages,
    DocumentService documentService,
  ) {
    final isCurrentPage = page.id == currentPageId;
    final pageIcon = getDrawerPageIcon(page.icon);

    return ListTile(
      // Only show leading icon if the page has one
      leading: pageIcon != null
          ? Icon(
              pageIcon,
              color: isCurrentPage ? theme.colorScheme.primary : null,
            )
          : null,
      title: Text(
        page.displayTitle,
        style: TextStyle(
          fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
          color: isCurrentPage ? theme.colorScheme.primary : null,
          fontStyle: page.title.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
      trailing: _buildPageActionsMenu(context, ref, theme, page, drawerPages, documentService),
      selected: isCurrentPage,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
      onTap: () {
        ref.read(currentPageIdProvider(docDir.path).notifier).state = page.id;
        Navigator.pop(context);
      },
    );
  }

  /// Builds the dropdown menu for page actions.
  Widget _buildPageActionsMenu(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    DocumentPage page,
    List<DocumentPage> drawerPages,
    DocumentService documentService,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(
        IconsaxPlusLinear.more,
        size: 20,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
      tooltip: 'Page Options',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        // Get the navigator before any async operations
        final navigator = Navigator.of(context);
        
        switch (value) {
          case 'rename':
            // Show dialog first, then close drawer
            final success = await PageDialogHelper.showEditPageTitleDialog(
              context,
              ref,
              docDir,
              page,
              documentService,
            );
            if (context.mounted && success) {
              navigator.pop(); // Close drawer after successful rename
            }
            break;
          case 'change_icon':
            final success = await PageDialogHelper.showChangeIconDialog(
              context,
              ref,
              docDir,
              page,
              documentService,
            );
            if (context.mounted && success) {
              navigator.pop(); // Close drawer after successful icon change
            }
            break;
          case 'delete':
            if (drawerPages.length > 1) {
              final success = await PageDialogHelper.confirmDeletePage(
                context,
                ref,
                docDir,
                page,
                documentService,
              );
              if (context.mounted && success) {
                navigator.pop(); // Close drawer after successful delete
              }
            }
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              Icon(IconsaxPlusLinear.edit, size: 18, color: theme.colorScheme.onSurface),
              const SizedBox(width: 12),
              const Text('Rename Page'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'change_icon',
          child: Row(
            children: [
              Icon(
                page.hasIcon ? IconsaxPlusLinear.paintbucket : IconsaxPlusLinear.add_circle,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Text(page.hasIcon ? 'Change Icon' : 'Add Icon'),
            ],
          ),
        ),
        if (drawerPages.length > 1)
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(IconsaxPlusLinear.trash, size: 18, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Text('Delete Page', style: TextStyle(color: theme.colorScheme.error)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Helper class for page-related dialogs.
///
/// This class provides static methods for showing dialogs related to page
/// management, including editing page titles, changing icons, and confirming page deletion.
class PageDialogHelper {
  /// Shows a dialog to edit a page title.
  ///
  /// Returns true if the title was successfully updated, false otherwise.
  static Future<bool> showEditPageTitleDialog(
    BuildContext context,
    WidgetRef ref,
    Directory docDir,
    DocumentPage page,
    DocumentService documentService,
  ) async {
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => _EditPageTitleDialog(initialTitle: page.title),
    );

    if (result != null && context.mounted) {
      // Allow empty string - will be displayed as "Untitled Screen"
      final success = await documentService.updatePageTitle(docDir, page.id, result.isEmpty ? '' : result);

      if (success && context.mounted) {
        final displayTitle = result.isEmpty ? 'Untitled Screen' : result;
        UIUtils.showSnackBar(context, 'Page title updated to "$displayTitle"');
        return true;
      } else if (context.mounted) {
        UIUtils.showSnackBar(context, 'Failed to update page title', isError: true);
      }
    }
    return false;
  }

  /// Shows a dialog to change the page icon.
  ///
  /// Returns true if the icon was successfully updated, false otherwise.
  static Future<bool> showChangeIconDialog(
    BuildContext context,
    WidgetRef ref,
    Directory docDir,
    DocumentPage page,
    DocumentService documentService,
  ) async {
    final theme = Theme.of(context);
    
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Choose Page Icon'),
          content: SizedBox(
            width: 280,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: drawerPageIconOptions.map((option) {
                final iconName = option['name'] as String;
                final icon = option['icon'] as IconData?;
                final label = option['label'] as String;
                final isSelected = _isIconSelected(page.icon, iconName);
                
                return Tooltip(
                  message: label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.pop(dialogContext, iconName),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: icon != null
                            ? Icon(
                                icon,
                                size: 24,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              )
                            : Text(
                                '\u2014', // Em dash for "no icon"
                                style: TextStyle(
                                  fontSize: 20,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (result != null && context.mounted) {
      // Pass null for 'none' to remove the icon
      final iconValue = result == 'none' ? null : result;
      final success = await documentService.updatePageIcon(docDir, page.id, iconValue);

      if (success && context.mounted) {
        final iconLabel = _getIconLabel(result);
        UIUtils.showSnackBar(context, 'Page icon changed to "$iconLabel"');
        return true;
      } else if (context.mounted) {
        UIUtils.showSnackBar(context, 'Failed to update page icon', isError: true);
      }
    }
    return false;
  }

  /// Helper to check if an icon is selected.
  static bool _isIconSelected(String? pageIcon, String optionName) {
    if (optionName == 'none') {
      return pageIcon == null || pageIcon.isEmpty;
    }
    return pageIcon == optionName;
  }

  /// Helper to get the label for an icon name.
  static String _getIconLabel(String iconName) {
    return _findIconOption(iconName)['label'] as String;
  }

  /// Shows a confirmation dialog for deleting a page.
  ///
  /// Returns true if the page was successfully deleted, false otherwise.
  static Future<bool> confirmDeletePage(
    BuildContext context,
    WidgetRef ref,
    Directory docDir,
    DocumentPage page,
    DocumentService documentService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Page?'),
        content: Text('Are you sure you want to delete "${page.displayTitle}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await documentService.deletePage(docDir, page.id);

      if (success && context.mounted) {
        UIUtils.showSnackBar(context, 'Page deleted');
        // Switch to first page if current page was deleted
        final currentPageId = ref.read(currentPageIdProvider(docDir.path));
        if (currentPageId == page.id) {
          final pages = await documentService.getDocumentPages(docDir);
          if (pages.isNotEmpty) {
            ref.read(currentPageIdProvider(docDir.path).notifier).state = pages.first.id;
          }
        }
        return true;
      } else if (context.mounted) {
        UIUtils.showSnackBar(context, 'Failed to delete page', isError: true);
      }
    }
    return false;
  }
}

/// Stateful dialog for editing page title.
/// Manages its own TextEditingController lifecycle to avoid disposal issues.
class _EditPageTitleDialog extends StatefulWidget {
  final String initialTitle;

  const _EditPageTitleDialog({required this.initialTitle});

  @override
  State<_EditPageTitleDialog> createState() => _EditPageTitleDialogState();
}

class _EditPageTitleDialogState extends State<_EditPageTitleDialog> {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Page Title'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Page Title',
          hintText: 'Enter page title (leave empty for "Untitled Screen")',
          counterText: '', // Hide counter, but still enforce limit
        ),
        autofocus: true,
        maxLength: 100,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
