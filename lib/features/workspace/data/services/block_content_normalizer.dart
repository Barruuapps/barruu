import 'dart:io';
import 'dart:convert';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';

/// Service for normalizing and validating block content.
///
/// Responsibilities:
/// - Normalizes JSON content in media and graph blocks
/// - Converts absolute paths to relative paths
/// - Provides default content for malformed blocks
/// - Validates block content structure
class BlockContentNormalizer {
  final Directory docDir;

  /// Default graph range for x-axis
  static const String defaultGraphMinX = '-10';
  static const String defaultGraphMaxX = '10';

  BlockContentNormalizer(this.docDir);

  /// Normalizes block content to ensure consistency.
  ///
  /// For media blocks (image, audio, video):
  /// - Converts absolute paths to relative paths
  /// - Provides default JSON structure if content is malformed
  /// - For images: handles both old (path) and new (images array) formats
  ///
  /// For graph blocks:
  /// - Validates JSON structure
  /// - Provides default graph configuration if malformed
  ///
  /// [block] - The block to normalize
  ///
  /// Returns a normalized copy of the block.
  Block normalizeBlockContent(Block block) {
    if (block.type == BlockType.image || block.type == BlockType.audio || block.type == BlockType.video) {
      try {
        final json = jsonDecode(block.content) as Map<String, dynamic>;
        logger.d('Normalized JSON content for block ${block.id}: $json');
        
        // For image blocks, handle both old (path) and new (images array) formats
        if (block.type == BlockType.image) {
          // Handle old single-path format - migrate to new images array format
          if (json.containsKey('path') && !json.containsKey('images')) {
            final oldPath = json['path'] as String? ?? '';
            final oldFileName = json['fileName'] as String? ?? '';
            if (oldPath.isNotEmpty) {
              // Detect if network image before converting to relative path
              final isNetwork = oldPath.startsWith('http://') || oldPath.startsWith('https://');
              final relativePath = !isNetwork && oldPath.startsWith(docDir.path)
                  ? oldPath.replaceFirst('${docDir.path}/', '')
                  : oldPath;
              json['images'] = [
                {
                  'path': relativePath,
                  'fileName': oldFileName,
                  'type': isNetwork ? 'network' : 'local',
                }
              ];
            } else {
              json['images'] = [];
            }
            json.remove('path');
            json.remove('fileName');
          }
          
          // Normalize paths in images array
          if (json['images'] is List) {
            final images = json['images'] as List<dynamic>;
            for (var i = 0; i < images.length; i++) {
              if (images[i] is Map<String, dynamic>) {
                final imageData = images[i] as Map<String, dynamic>;
                if (imageData['path'] != null && 
                    imageData['path'].toString().startsWith(docDir.path)) {
                  imageData['path'] = imageData['path'].toString().replaceFirst('${docDir.path}/', '');
                }
              }
            }
          }
        } else {
          // For audio/video, ensure path is relative
          if (json['path'] != null && json['path'].toString().startsWith(docDir.path)) {
            json['path'] = json['path'].toString().replaceFirst('${docDir.path}/', '');
          }
        }
        
        return block.copyWith(content: jsonEncode(json));
      } catch (e, stackTrace) {
        logger.w('Invalid JSON content for block ${block.id}: ${block.content}, error: $e', stackTrace: stackTrace);
        return block.copyWith(content: jsonEncode(_getDefaultMediaContent(block.type)));
      }
    } else if (block.type == BlockType.graph) {
      try {
        final json = jsonDecode(block.content) as Map<String, dynamic>;
        logger.d('Normalized JSON content for graph block ${block.id}: $json');
        return block;
      } catch (e, stackTrace) {
        logger.w('Invalid JSON content for graph block ${block.id}: ${block.content}, error: $e', stackTrace: stackTrace);
        return block.copyWith(content: jsonEncode(_getDefaultGraphContent()));
      }
    }

    return block;
  }

  /// Validates media block content structure.
  ///
  /// Checks that the content is valid JSON and contains required fields.
  /// For image blocks: validates new images array format or old path format.
  ///
  /// [block] - The block to validate
  ///
  /// Returns true if content is valid, false otherwise.
  bool validateMediaBlockContent(Block block) {
    if (block.type != BlockType.image && block.type != BlockType.video && block.type != BlockType.audio) {
      return true;
    }

    try {
      final json = jsonDecode(block.content) as Map<String, dynamic>;
      
      // For image blocks, check for either new images array or old path format
      if (block.type == BlockType.image) {
        return json.containsKey('images') || json.containsKey('path');
      }
      
      // For audio/video, check that path field exists (can be empty)
      return json.containsKey('path');
    } catch (e) {
      logger.w('Invalid JSON content for block: ${block.id}');
      return false;
    }
  }

  /// Validates graph block content structure.
  ///
  /// Checks that the content contains all required graph fields:
  /// - expression
  /// - caption
  /// - min_x
  /// - max_x
  ///
  /// [block] - The block to validate
  ///
  /// Returns true if content is valid, false otherwise.
  bool validateGraphBlockContent(Block block) {
    if (block.type != BlockType.graph) {
      return true;
    }

    try {
      final json = jsonDecode(block.content) as Map<String, dynamic>;
      return json['expression'] != null &&
          json['caption'] != null &&
          json['min_x'] != null &&
          json['max_x'] != null;
    } catch (e) {
      logger.w('Invalid JSON content for graph block: ${block.id}');
      return false;
    }
  }

  /// Gets default content structure for media blocks.
  ///
  /// [type] - The block type (image, audio, or video)
  ///
  /// Returns a map with default values for the specified media type.
  Map<String, dynamic> _getDefaultMediaContent(BlockType type) {
    if (type == BlockType.image) {
      return {
        'images': [],
        'caption': '',
        'cropTop': 0.0,
        'cropBottom': 0.0,
        'fit': 'cover',
      };
    } else if (type == BlockType.audio) {
      return {
        'path': '',
        'customTitle': '',
        'caption': '',
        'fileName': ''
      };
    } else {
      // Video
      return {
        'path': '',
        'caption': '',
        'fileName': ''
      };
    }
  }

  /// Gets default content structure for graph blocks.
  ///
  /// Returns a map with default graph configuration.
  Map<String, dynamic> _getDefaultGraphContent() {
    return {
      'expression': '',
      'caption': '',
      'min_x': defaultGraphMinX,
      'max_x': defaultGraphMaxX,
    };
  }
}
