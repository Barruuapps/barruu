import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/block_empty_state.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/cards_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/debouncer.dart';
import 'package:barruu/features/workspace/presentation/services/image_file_service.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/card_template_selector.dart';
import 'package:barruu/features/workspace/constants/block_dimension_constants.dart';

/// Cards block for displaying horizontally scrollable cards.
///
/// Content format:
/// ```json
/// {
///   "cards": [
///     {
///       "title": "Card 1",
///       "description": "Card description",
///       "emoji": "📝",
///       "imagePath": "path/to/image.jpg",
///       "imageType": "local"
///     }
///   ],
///   "cardStyle": "elevated",
///   "cardTemplate": "standard"
/// }
/// ```
class CardsBlock extends BaseEditableBlock {
  const CardsBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<CardsBlock> createState() => _CardsBlockState();
}

class _CardsBlockState extends BaseEditableBlockState<CardsBlock> {
  late String _cardStyle;
  late String _cardTemplate;
  late Debouncer _debouncer;
  late ImageFileService _imageFileService;
  final Map<int, Map<String, TextEditingController>> _cardControllers = {};

  @override
  Map<String, dynamic> getDefaultContent() => {
    'cards': [],
    'cardStyle': 'elevated',
    'cardTemplate': 'standard',
  };

  @override
  void initializeBlockSpecifics() {
    _debouncer = Debouncer(delay: const Duration(milliseconds: 500));
    _imageFileService = ImageFileService();

    // Ensure cards is a list
    if (content['cards'] is! List) {
      content['cards'] = [];
    }

    _cardStyle = content['cardStyle']?.toString() ?? 'elevated';
    _cardTemplate = content['cardTemplate']?.toString() ?? 'standard';

    // Initialize controllers for existing cards
    _initializeCardControllers();
  }

  @override
  void onContentChanged() {
    _cardStyle = content['cardStyle']?.toString() ?? 'elevated';
    _cardTemplate = content['cardTemplate']?.toString() ?? 'standard';

    // Update controllers when content changes externally
    _updateCardControllers();
  }

  @override
  void disposeBlockSpecifics() {
    _debouncer.dispose();
    _disposeCardControllers();
  }

  void _initializeCardControllers() {
    final cards = content['cards'] as List;
    for (int i = 0; i < cards.length; i++) {
      if (!_cardControllers.containsKey(i)) {
        final card = cards[i] as Map<String, dynamic>;
        _cardControllers[i] = {
          'title': TextEditingController(text: card['title']?.toString() ?? ''),
          'description': TextEditingController(
            text: card['description']?.toString() ?? '',
          ),
          'emoji': TextEditingController(
            text: card['emoji']?.toString() ?? '📝',
          ),
        };
      }
    }
  }

  void _updateCardControllers() {
    final cards = content['cards'] as List;

    // Remove controllers for cards that no longer exist
    _cardControllers.removeWhere((key, controllers) {
      if (key >= cards.length) {
        for (var controller in controllers.values) {
          controller.dispose();
        }
        return true;
      }
      return false;
    });

    // Update existing controllers and create new ones
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i] as Map<String, dynamic>;

      if (_cardControllers.containsKey(i)) {
        // Only update if text is different to avoid cursor reset
        final titleText = card['title']?.toString() ?? '';
        if (_cardControllers[i]!['title']!.text != titleText) {
          _cardControllers[i]!['title']!.text = titleText;
        }

        final descText = card['description']?.toString() ?? '';
        if (_cardControllers[i]!['description']!.text != descText) {
          _cardControllers[i]!['description']!.text = descText;
        }

        final emojiText = card['emoji']?.toString() ?? '📝';
        if (_cardControllers[i]!['emoji']!.text != emojiText) {
          _cardControllers[i]!['emoji']!.text = emojiText;
        }
      } else {
        _cardControllers[i] = {
          'title': TextEditingController(text: card['title']?.toString() ?? ''),
          'description': TextEditingController(
            text: card['description']?.toString() ?? '',
          ),
          'emoji': TextEditingController(
            text: card['emoji']?.toString() ?? '📝',
          ),
        };
      }
    }
  }

  void _disposeCardControllers() {
    for (var controllers in _cardControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    _cardControllers.clear();
  }

  void _addCard() {
    final cards = List<Map<String, dynamic>>.from(content['cards'] as List);
    final newIndex = cards.length;
    cards.add({
      'title': '',
      'description': '',
      'emoji': '📝',
      'imagePath': '',
      'imageType': 'local',
    });

    content['cards'] = cards;

    // Create controllers for new card
    _cardControllers[newIndex] = {
      'title': TextEditingController(text: ''),
      'description': TextEditingController(text: ''),
      'emoji': TextEditingController(text: '📝'),
    };

    saveContent();
  }

  Future<void> _addImageToCard(int cardIndex) async {
    final images = await _imageFileService.pickAndSaveImages(widget.docDir);
    if (images != null && images.isNotEmpty) {
      final cards = List<Map<String, dynamic>>.from(content['cards'] as List);
      if (cardIndex >= 0 && cardIndex < cards.length) {
        cards[cardIndex]['imagePath'] = images[0]['path'];
        cards[cardIndex]['imageType'] = images[0]['type'];
        content['cards'] = cards;
        saveContent();
      }
    }
  }

  /// Replaces the existing card image: removes the old file, then picks a new one.
  Future<void> _changeImageInCard(int cardIndex) async {
    final cards = List<Map<String, dynamic>>.from(content['cards'] as List);
    if (cardIndex < 0 || cardIndex >= cards.length) return;
    // Delete old file first
    final oldPath = cards[cardIndex]['imagePath'] as String?;
    if (oldPath != null && oldPath.isNotEmpty) {
      final file = File('${widget.docDir.path}/$oldPath');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    cards[cardIndex]['imagePath'] = '';
    cards[cardIndex]['imageType'] = 'local';
    content['cards'] = cards;
    saveContent();
    // Now pick a new image
    final images = await _imageFileService.pickAndSaveImages(widget.docDir);
    if (images != null && images.isNotEmpty) {
      final updatedCards = List<Map<String, dynamic>>.from(
        content['cards'] as List,
      );
      if (cardIndex < updatedCards.length) {
        updatedCards[cardIndex]['imagePath'] = images[0]['path'];
        updatedCards[cardIndex]['imageType'] = images[0]['type'];
        content['cards'] = updatedCards;
        saveContent();
      }
    }
  }

  void _removeImageFromCard(int cardIndex) {
    final cards = List<Map<String, dynamic>>.from(content['cards'] as List);
    if (cardIndex >= 0 && cardIndex < cards.length) {
      final imagePath = cards[cardIndex]['imagePath'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        // Delete the image file
        final file = File('${widget.docDir.path}/$imagePath');
        if (file.existsSync()) {
          file.deleteSync();
        }
      }

      cards[cardIndex]['imagePath'] = '';
      cards[cardIndex]['imageType'] = 'local';
      content['cards'] = cards;
      saveContent();
    }
  }

  void _removeCard(int index) {
    final cards = List<Map<String, dynamic>>.from(content['cards'] as List);
    if (index < 0 || index >= cards.length) return;

    final removedCard = Map<String, dynamic>.from(cards[index]);
    cards.removeAt(index);
    content['cards'] = cards;

    // Dispose and remove controllers for removed card
    if (_cardControllers.containsKey(index)) {
      for (var controller in _cardControllers[index]!.values) {
        controller.dispose();
      }
      _cardControllers.remove(index);
    }

    // Reindex remaining controllers
    final newControllers = <int, Map<String, TextEditingController>>{};
    for (var entry in _cardControllers.entries) {
      if (entry.key > index) {
        newControllers[entry.key - 1] = entry.value;
      } else {
        newControllers[entry.key] = entry.value;
      }
    }
    _cardControllers.clear();
    _cardControllers.addAll(newControllers);

    setState(() {});
    saveContent();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: BlockDimensionConstants.undoSnackbarDuration,
        content: const Text('Card deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            final currentCards = List<Map<String, dynamic>>.from(
              content['cards'] as List,
            );
            currentCards.insert(index, removedCard);
            content['cards'] = currentCards;

            // Shift controllers for items at or after the restored index
            final shifted = <int, Map<String, TextEditingController>>{};
            for (var e in _cardControllers.entries) {
              shifted[e.key >= index ? e.key + 1 : e.key] = e.value;
            }
            _cardControllers.clear();
            _cardControllers.addAll(shifted);
            // Controllers for the restored card will be created lazily

            setState(() {});
            saveContent();
          },
        ),
      ),
    );
  }

  void _reorderCards(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final cards = List<Map<String, dynamic>>.from(content['cards'] as List);
    final moved = cards.removeAt(oldIndex);
    cards.insert(newIndex, moved);
    content['cards'] = cards;

    // Reindex controllers without disposing to preserve text/focus state
    final n = cards.length;
    final controllerList = List<Map<String, TextEditingController>?>.generate(
      n,
      (i) => _cardControllers[i],
    );
    final movedCtrl = controllerList.removeAt(oldIndex);
    controllerList.insert(newIndex, movedCtrl);
    _cardControllers.clear();
    for (int i = 0; i < n; i++) {
      if (controllerList[i] != null) {
        _cardControllers[i] = controllerList[i]!;
      }
    }

    setState(() {});
    saveContent();
  }

  void _updateCard(int index, String field, String value) {
    final cards = List<Map<String, dynamic>>.from(content['cards'] as List);
    if (index >= 0 && index < cards.length) {
      cards[index][field] = value;
      content['cards'] = cards;
      _debouncer.call(() => saveContent());
    }
  }

  void _updateCardStyle(String newStyle) {
    setState(() {
      _cardStyle = newStyle;
      content['cardStyle'] = newStyle;
      saveContent();
    });
  }

  void _updateCardTemplate(String newTemplate) {
    setState(() {
      _cardTemplate = newTemplate;
      content['cardTemplate'] = newTemplate;
      saveContent();
    });
  }

  double _getCardHeight() {
    switch (_cardTemplate) {
      case 'horizontal':
        return 240;
      case 'compact':
        return 240;
      case 'featured':
        return 300;
      case 'overlay':
        return 280;
      case 'magazine':
        return 300;
      case 'split':
        return 260;
      case 'banner':
        return 220;
      case 'avatar':
        return 240;
      case 'imageRight':
        return 240;
      case 'icon':
        return 240;
      case 'social':
        return 320;
      case 'product':
        return 300;
      case 'standard':
      default:
        return 300;
    }
  }

  @override
  Widget buildReader(BuildContext context) {
    return CardsReaderBlock(block: widget.block, docDir: widget.docDir);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    final cards = content['cards'] as List;

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
                    'Cards',
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
                            builder: (context) => CardTemplateSelector(
                              selectedTemplate: _cardTemplate,
                              onTemplateSelected: (value) {
                                _updateCardTemplate(value);
                                Navigator.of(context).pop();
                              },
                              theme: theme,
                            ),
                          );
                        },
                        icon: const Icon(IconsaxPlusLinear.gallery, size: 16),
                        label: Text(_getTemplateDisplayName(_cardTemplate)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Style selector
                      DropdownButton<String>(
                        value: _cardStyle,
                        hint: const Text('Style'),
                        items: const [
                          DropdownMenuItem(
                            value: 'elevated',
                            child: Text('Elevated'),
                          ),
                          DropdownMenuItem(
                            value: 'outlined',
                            child: Text('Outlined'),
                          ),
                          DropdownMenuItem(
                            value: 'filled',
                            child: Text('Filled'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _updateCardStyle(value);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Card list
              if (cards.isEmpty)
                BlockEmptyState(
                  icon: Icons.style_outlined,
                  message: 'No cards added yet',
                  actionLabel: 'Add Card',
                  onAction: _addCard,
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  onReorder: _reorderCards,
                  itemBuilder: (context, index) {
                    final card = cards[index] as Map<String, dynamic>;
                    return KeyedSubtree(
                      key: ValueKey('card_$index'),
                      child: _buildCardEditor(theme, card, index),
                    );
                  },
                ),

              const SizedBox(height: 12),

              // Add card button
              OutlinedButton.icon(
                onPressed: _addCard,
                icon: const Icon(IconsaxPlusLinear.add),
                label: const Text('Add Card'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardEditor(
    ThemeData theme,
    Map<String, dynamic> card,
    int index,
  ) {
    final imagePath = card['imagePath'] as String?;
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    // Ensure controllers exist for this card
    if (!_cardControllers.containsKey(index)) {
      _cardControllers[index] = {
        'title': TextEditingController(text: card['title']?.toString() ?? ''),
        'description': TextEditingController(
          text: card['description']?.toString() ?? '',
        ),
        'emoji': TextEditingController(text: card['emoji']?.toString() ?? '📝'),
      };
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header section with image/emoji and delete button
            Stack(
              children: [
                // Image or gradient header
                if (hasImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.file(
                      File('${widget.docDir.path}/$imagePath'),
                      width: double.infinity,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _cardControllers[index]!['emoji']!.text.isEmpty
                            ? '📝'
                            : _cardControllers[index]!['emoji']!.text,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),

                // Action buttons overlay
                Positioned(
                  top: 4,
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasImage) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.9,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              IconsaxPlusLinear.gallery_edit,
                              color: theme.colorScheme.primary,
                            ),
                            onPressed: () => _changeImageInCard(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 18,
                            tooltip: 'Change image',
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: 0.9,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              IconsaxPlusLinear.close_circle,
                              color: theme.colorScheme.error,
                            ),
                            onPressed: () => _removeImageFromCard(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 20,
                            tooltip: 'Remove image',
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.9,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(IconsaxPlusLinear.trash, size: 18),
                          onPressed: () => _removeCard(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Delete card',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Content section - optimized for mobile, no excessive spacing
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add image button (only show if no image)
                  if (!hasImage) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _addImageToCard(index),
                        icon: const Icon(
                          IconsaxPlusLinear.gallery_add,
                          size: 16,
                        ),
                        label: const Text(
                          'Add Image',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Emoji field (only show if no image)
                  if (!hasImage) ...[
                    TextField(
                      controller: _cardControllers[index]!['emoji'],
                      style: const TextStyle(fontSize: 20),
                      decoration: InputDecoration(
                        hintText: '📝',
                        labelText: 'Emoji',
                        labelStyle: theme.textTheme.labelSmall,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        isDense: true,
                      ),
                      maxLines: 1,
                      onChanged: (value) => _updateCard(index, 'emoji', value),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Title field - compact for mobile
                  TextField(
                    controller: _cardControllers[index]!['title'],
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Card Title',
                      labelText: 'Title',
                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      isDense: true,
                    ),
                    maxLines: 2,
                    minLines: 1,
                    onChanged: (value) => _updateCard(index, 'title', value),
                  ),
                  const SizedBox(height: 8),

                  // Description field - compact, no extra space below
                  TextField(
                    controller: _cardControllers[index]!['description'],
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Description...',
                      labelText: 'Description',
                      labelStyle: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      isDense: true,
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onChanged: (value) =>
                        _updateCard(index, 'description', value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTemplateDisplayName(String template) {
    switch (template) {
      case 'standard':
        return 'Standard';
      case 'horizontal':
        return 'Horizontal';
      case 'compact':
        return 'Compact';
      case 'featured':
        return 'Featured';
      case 'overlay':
        return 'Overlay';
      case 'magazine':
        return 'Magazine';
      case 'split':
        return 'Split';
      case 'banner':
        return 'Banner';
      case 'avatar':
        return 'Avatar';
      case 'imageRight':
        return 'Image Right';
      case 'icon':
        return 'Icon';
      case 'social':
        return 'Social';
      case 'product':
        return 'Product';
      default:
        return 'Standard';
    }
  }
}
