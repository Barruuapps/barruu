import 'dart:io';
import 'dart:convert';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/data/services/media_path_validator.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';

/// Service for block CRUD operations and style management.
///
/// Responsibilities:
/// - Adding new blocks with appropriate defaults
/// - Updating block content and styles
/// - Deleting blocks with cleanup (media files, nested pages)
/// - Managing block styles and style presets
/// - Handling AI-generated blocks
class BlockOperationsService {
  final Directory docDir;
  final PageRepository repository;
  final DocumentService documentService;
  final MediaPathValidator pathValidator;
  final Map<BlockType, BlockStyle> _recentStyles = {};

  /// Minimum font size enforced for all blocks to ensure readability
  static const double minFontSize = 16;

  /// Default font sizes for different block types
  static const double headerFontSize = 32;
  static const double paragraphFontSize = 18;
  static const double blockquoteFontSize = 18;
  static const double codeFontSize = 16;
  static const double listFontSize = 18;
  static const double mathFontSize = 20;
  static const double questionFontSize = 18;
  static const double chatFontSize = 16;
  static const double checkboxFontSize = 18;
  static const double graphFontSize = 16;
  static const double evaluationButtonFontSize = 16;
  static const double pageFontSize = 18;
  static const double wordOrderFontSize = 18;
  static const double dividerFontSize = 16;
  static const double tableFontSize = 16;

  BlockOperationsService(
    this.docDir,
    this.repository,
    this.documentService,
    this.pathValidator,
  );

  /// Gets or creates a default style for a block type.
  ///
  /// If a recent style exists for this block type, returns it.
  /// Otherwise, returns the default style for the type.
  ///
  /// [type] - The block type
  ///
  /// Returns the appropriate BlockStyle
  BlockStyle getStyleForType(BlockType type) {
    return _recentStyles[type] ?? _getDefaultStyle(type);
  }

  /// Resets the recent style for a block type to the default.
  ///
  /// [type] - The block type to reset
  void resetRecentStyle(BlockType type) {
    _recentStyles[type] = _getDefaultStyle(type);
  }

  /// Updates the recent style for a block type.
  ///
  /// This style will be used for new blocks of this type.
  ///
  /// [type] - The block type
  /// [style] - The style to remember
  void updateRecentStyle(BlockType type, BlockStyle style) {
    _recentStyles[type] = style;
  }

  /// Clears all recent styles.
  void clearRecentStyles() {
    _recentStyles.clear();
  }

  /// Saves a block to the repository.
  ///
  /// Performs validation before saving based on block type.
  ///
  /// [block] - The block to save
  ///
  /// Throws if saving fails
  Future<void> saveBlock(Block block) async {
    try {
      // Validation is handled by BlockContentNormalizer before calling this
      await repository.updateBlock(block);
      logger.i('Block saved: ${block.id}');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to save block: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Updates the style of a block.
  ///
  /// Ensures minimum font size of minFontSize.
  ///
  /// [block] - The block to update
  /// [style] - The new style
  ///
  /// Returns the updated block
  Future<Block> updateStyle(Block block, BlockStyle style) async {
    try {
      final adjustedStyle = style.copyWith(
        fontSize: style.fontSize >= minFontSize ? style.fontSize : minFontSize,
      );
      final updatedBlock = block.copyWith(style: adjustedStyle);
      await repository.updateBlock(updatedBlock);
      _recentStyles[block.type] = adjustedStyle;
      logger.i('Style updated for block: ${block.id}, type: ${block.type}');
      return updatedBlock;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update style for block: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Deletes a block and cleans up associated resources.
  ///
  /// For media blocks, deletes the file if not referenced elsewhere.
  /// For page blocks, deletes the nested page if not referenced elsewhere.
  ///
  /// [block] - The block to delete
  /// [allBlocks] - All blocks in the current page (to check references)
  ///
  /// Returns true if deletion succeeded
  Future<bool> deleteBlock(Block block, List<Block> allBlocks) async {
    try {
      if (block.type == BlockType.audio ||
          block.type == BlockType.video ||
          block.type == BlockType.image) {
        final mediaDeleted = await _deleteMedia(block, allBlocks);
        if (!mediaDeleted) {
          logger.w('Media deletion failed for block: ${block.id}');
        }
      } else if (block.type == BlockType.page) {
        final pageDeleted = await _deleteNestedPage(block);
        if (!pageDeleted) {
          logger.w('Nested page deletion failed for block: ${block.id}');
        }
      }
      await repository.deleteBlock(block.id!);
      logger.i('Block deleted: ${block.id}');
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to delete block: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Deletes the media file associated with a block.
  ///
  /// Only deletes if the file is not referenced by other blocks.
  ///
  /// [block] - The block whose media to delete
  /// [allBlocks] - All blocks to check for references
  ///
  /// Returns true if deletion succeeded or file is referenced elsewhere
  Future<bool> _deleteMedia(Block block, List<Block> allBlocks) async {
    if (!pathValidator.isFileOperationSupported) return false;
    try {
      final json = jsonDecode(block.content) as Map<String, dynamic>;
      final filePath = json['path'] as String? ?? '';
      if (filePath.isEmpty) {
        logger.w('No media file path for block: ${block.id}');
        return false;
      }

      // Check if any other blocks reference the same file
      final otherBlocksUsingFile = allBlocks.where((b) {
        if (b.id == block.id) return false;
        if (b.type != BlockType.audio &&
            b.type != BlockType.video &&
            b.type != BlockType.image) {
          return false;
        }

        try {
          final otherJson = jsonDecode(b.content) as Map<String, dynamic>;
          final otherPath = otherJson['path'] as String? ?? '';
          return otherPath == filePath;
        } catch (e) {
          return false;
        }
      }).toList();

      if (otherBlocksUsingFile.isNotEmpty) {
        logger.i(
          'Media file is referenced by ${otherBlocksUsingFile.length} other block(s), skipping deletion: $filePath',
        );
        return true;
      }

      final absolutePath = pathValidator.resolveRelativePath(filePath);
      if (!await pathValidator.isValidMediaPath(absolutePath)) {
        logger.w('Invalid media path for block: ${block.id}');
        return false;
      }
      final file = File(absolutePath);
      if (!await file.exists()) {
        logger.w('Media file not found: $absolutePath');
        return false;
      }
      await file.delete();
      logger.i('Media file deleted: $absolutePath');
      return true;
    } catch (e, stackTrace) {
      logger.e(
        'Error deleting media file for block: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Deletes a nested page associated with a page block.
  ///
  /// Only deletes if the page is auto-created and not referenced elsewhere.
  ///
  /// [block] - The page block whose nested page to delete
  ///
  /// Returns true if deletion succeeded or page is referenced elsewhere
  Future<bool> _deleteNestedPage(Block block) async {
    try {
      if (block.content.isEmpty) {
        logger.w('No content in page block: ${block.id}');
        return false;
      }

      final content = JsonStringConverter().convertFromJsonString(
        block.content,
      );
      final pageId = content['pageId']?.toString();
      final isNested = content['isNested'] == true;

      if (pageId == null || pageId.isEmpty || !isNested) {
        return true;
      }

      // Check if any other blocks reference this page
      final allPages = await documentService.getDocumentPages(docDir);
      bool isReferencedElsewhere = false;

      for (final page in allPages) {
        try {
          final blocks = await documentService.getPageBlocks(docDir, page.id);
          for (final otherBlock in blocks) {
            if (otherBlock.id == block.id) continue;

            if (otherBlock.type == BlockType.page &&
                otherBlock.content.isNotEmpty) {
              try {
                final otherContent = JsonStringConverter()
                    .convertFromJsonString(otherBlock.content);
                final otherPageId = otherContent['pageId']?.toString();
                if (otherPageId == pageId) {
                  isReferencedElsewhere = true;
                  break;
                }
              } catch (e) {
                // Skip invalid content
              }
            }
          }
          if (isReferencedElsewhere) break;
        } catch (e) {
          // Skip if can't read page blocks
        }
      }

      if (!isReferencedElsewhere) {
        final deleted = await documentService.deletePage(docDir, pageId);
        if (deleted) {
          logger.i('Deleted auto-created nested page: $pageId');
        } else {
          logger.w('Failed to delete nested page: $pageId');
        }
        return deleted;
      } else {
        logger.i(
          'Not deleting page $pageId as it is referenced by other blocks',
        );
        return true;
      }
    } catch (e, stackTrace) {
      logger.e(
        'Error deleting nested page for block: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Gets the default style for a block type.
  ///
  /// [type] - The block type
  ///
  /// Returns the default BlockStyle for the type
  BlockStyle _getDefaultStyle(BlockType type) {
    switch (type) {
      case BlockType.header:
        return const BlockStyle(
          bold: true,
          fontSize: headerFontSize,
          headerStyle: 'normal',
        );
      case BlockType.paragraph:
        return const BlockStyle();
      case BlockType.blockquote:
        return const BlockStyle(italic: true, fontFamily: 'Georgia');
      case BlockType.code:
        return const BlockStyle(
          fontFamily: 'monospace',
          fontSize: codeFontSize,
          language: 'dart',
        );
      case BlockType.list:
        return const BlockStyle(listType: 'bullet');
      case BlockType.image:
      case BlockType.video:
      case BlockType.audio:
        return const BlockStyle();
      case BlockType.divider:
        return const BlockStyle(fontSize: dividerFontSize, height: 16);
      case BlockType.spacer:
        return const BlockStyle(height: 24);
      case BlockType.table:
        return const BlockStyle(fontSize: tableFontSize);
      case BlockType.box:
        return const BlockStyle(borderColor: '#000000');
      case BlockType.math:
        return const BlockStyle(fontSize: mathFontSize);
      case BlockType.chat:
        return const BlockStyle(fontSize: chatFontSize);
      case BlockType.checkbox:
        return const BlockStyle();
      case BlockType.graph:
        return const BlockStyle(fontSize: graphFontSize);
      case BlockType.evaluationButton:
        return const BlockStyle(fontSize: evaluationButtonFontSize);
      case BlockType.page:
        return const BlockStyle();
      case BlockType.wordOrder:
      case BlockType.mathWorkpad:
        return const BlockStyle();
      default:
        return const BlockStyle();
    }
  }
}
