import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/presentation/dialogs/graph_type_selector_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

// Service imports
import 'package:barruu/features/workspace/data/services/media_path_validator.dart';
import 'package:barruu/features/workspace/data/services/block_content_normalizer.dart';
import 'package:barruu/features/workspace/data/services/block_ordering_service.dart';
import 'package:barruu/features/workspace/data/services/block_media_service.dart';
import 'package:barruu/features/workspace/data/services/block_operations_service.dart';

// Service providers
final mediaPathValidatorProvider =
    Provider.family<MediaPathValidator, Directory>((ref, docDir) {
      return MediaPathValidator(docDir);
    });

final blockContentNormalizerProvider =
    Provider.family<BlockContentNormalizer, Directory>((ref, docDir) {
      return BlockContentNormalizer(docDir);
    });

final blockOrderingServiceProvider =
    Provider.family<BlockOrderingService, Directory>((ref, docDir) {
      // Read currentPageIdProvider once to avoid rebuilds
      final currentPageId = ref.read(currentPageIdProvider(docDir.path));
      final repository = ref.read(
        pageRepositoryProvider((docDir: docDir, pageId: currentPageId)),
      );
      return BlockOrderingService(repository);
    });

final blockMediaServiceProvider = Provider.family<BlockMediaService, Directory>(
  (ref, docDir) {
    final pathValidator = ref.watch(mediaPathValidatorProvider(docDir));
    return BlockMediaService(docDir, pathValidator);
  },
);

final blockOperationsServiceProvider =
    Provider.family<BlockOperationsService, Directory>((ref, docDir) {
      final currentPageId = ref.watch(currentPageIdProvider(docDir.path));
      final repository = ref.watch(
        pageRepositoryProvider((docDir: docDir, pageId: currentPageId)),
      );
      final documentService = ref.watch(documentServiceProvider);
      final pathValidator = ref.watch(mediaPathValidatorProvider(docDir));
      return BlockOperationsService(
        docDir,
        repository,
        documentService,
        pathValidator,
      );
    });

final editDocumentControllerProvider =
    StateNotifierProvider.family<
      EditDocumentController,
      List<Block>,
      Directory
    >((ref, docDir) {
      final currentPageId = ref.watch(currentPageIdProvider(docDir.path));
      final repository = ref.read(
        pageRepositoryProvider((docDir: docDir, pageId: currentPageId)),
      );
      final documentService = ref.read(documentServiceProvider);
      final pathValidator = ref.read(mediaPathValidatorProvider(docDir));
      final contentNormalizer = ref.read(
        blockContentNormalizerProvider(docDir),
      );
      final orderingService = ref.read(blockOrderingServiceProvider(docDir));
      final mediaService = ref.read(blockMediaServiceProvider(docDir));
      final operationsService = ref.read(
        blockOperationsServiceProvider(docDir),
      );

      return EditDocumentController(
        docDir,
        currentPageId,
        repository,
        documentService,
        pathValidator,
        contentNormalizer,
        orderingService,
        mediaService,
        operationsService,
      );
    });

class EditDocumentController extends StateNotifier<List<Block>> {
  final Directory docDir;
  final String currentPageId;
  final PageRepository _repository;
  final DocumentService _documentService;
  final MediaPathValidator _pathValidator;
  final BlockContentNormalizer _contentNormalizer;
  final BlockOrderingService _orderingService;
  final BlockMediaService _mediaService;
  final BlockOperationsService _operationsService;

  String? editingBlockId;

  EditDocumentController(
    this.docDir,
    this.currentPageId,
    this._repository,
    this._documentService,
    this._pathValidator,
    this._contentNormalizer,
    this._orderingService,
    this._mediaService,
    this._operationsService,
  ) : super([]) {
    _loadBlocks();
  }

  @override
  void dispose() {
    _operationsService.clearRecentStyles();
    super.dispose();
  }

  Future<void> _loadBlocks() async {
    try {
      final blocks = await _repository.getBlocks();
      if (mounted) {
        // Normalize content for all blocks that need it
        final normalizedBlocks = blocks.map((block) {
          return _contentNormalizer.normalizeBlockContent(block);
        }).toList();
        // Validate media file existence
        for (var block in normalizedBlocks) {
          if (block.type == BlockType.image ||
              block.type == BlockType.audio ||
              block.type == BlockType.video) {
            try {
              final json = jsonDecode(block.content) as Map<String, dynamic>;
              final relativePath = json['path'] as String? ?? '';
              if (relativePath.isNotEmpty) {
                final absolutePath = _pathValidator.resolveRelativePath(
                  relativePath,
                );
                final file = File(absolutePath);
                if (!file.existsSync()) {
                  logger.w(
                    'Media file not found for block ${block.id}: $absolutePath',
                  );
                  // Optionally update block content to mark as invalid
                  json['path'] = '';
                  block = block.copyWith(content: jsonEncode(json));
                }
              }
            } catch (e) {
              logger.w(
                'Failed to validate media file for block ${block.id}: $e',
              );
            }
          }
        }
        state = normalizedBlocks;
        logger.i('Blocks loaded for document: ${docDir.path}');
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to load blocks for document: ${docDir.path}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> saveBlock(Block block) async {
    try {
      // Validate media path before saving
      if (block.type == BlockType.image ||
          block.type == BlockType.video ||
          block.type == BlockType.audio) {
        try {
          final json = jsonDecode(block.content) as Map<String, dynamic>;
          final filePath = json['path'] as String? ?? '';
          if (filePath.isNotEmpty &&
              !await _pathValidator.isValidMediaPath(
                _pathValidator.resolveRelativePath(filePath),
              )) {
            logger.w('Invalid media path for block: ${block.id}');
            return;
          }
        } catch (e) {
          logger.w('Invalid JSON content for block: ${block.id}');
          return;
        }
      }
      await _operationsService.saveBlock(block);
      if (mounted) {
        _updateBlockInMemory(block);
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to save block: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // reset recent styles to default style
  void resetRecentStyles(Block block) {
    if (mounted) {
      _operationsService.resetRecentStyle(block.type);
    }
  }

  Future<void> updateStyle(Block block, BlockStyle style) async {
    try {
      final updatedBlock = await _operationsService.updateStyle(block, style);
      if (mounted) {
        _updateBlockInMemory(updatedBlock);
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update style for block: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<bool> deleteBlock(Block block) async {
    try {
      final success = await _operationsService.deleteBlock(block, state);
      if (success && mounted) {
        state = state.where((b) => b.id != block.id).toList();
      }
      return success;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to delete block: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> addBlock({
    String content = '',
    BlockType type = BlockType.paragraph,
  }) async {
    try {
      BlockStyle style = _operationsService.getStyleForType(type);
      String finalContent = content;

      if (type == BlockType.image) {
        final imageResult = await _mediaService.handleImageFromFile();
        if (imageResult == null) return;
        finalContent = jsonEncode(imageResult);
      } else if (type == BlockType.video) {
        final videoResult = await _mediaService.handleVideoFromFile();
        if (videoResult == null) return;
        finalContent = jsonEncode(videoResult);
      } else if (type == BlockType.audio) {
        final audioResult = await _mediaService.handleAudioFromFile();
        if (audioResult == null) return;
        finalContent = jsonEncode(audioResult);
      } else if (type == BlockType.graph) {
        finalContent = jsonEncode({
          'expression': '',
          'caption': '',
          'min_x': '-10',
          'max_x': '10',
        });
      } else if (type == BlockType.wordOrder) {
        finalContent = jsonEncode({
          'question': 'Arrange the words to build a natural, correct sentence.',
          'content': 'She studies every morning',
          'type': 'sentence',
          'isBilingual': false,
          'translation': '',
          'explanation':
              'Use the correct English word order: subject + verb + time phrase.',
          'answerOnce': false,
          'showFeedbackInstantly': true,
          'marksPerQuestion': 1.0,
          'mathDifficulty': 'easy',
        });
      } else if (type == BlockType.mathWorkpad) {
        finalContent = jsonEncode({
          'mode': 'line_order',
          'question':
              'Arrange the solution steps to solve the problem correctly.',
          'content': '3x - 6 = 9\n3x = 15\nx = 5',
          'steps': ['3x - 6 = 9', '3x = 15', 'x = 5'],
          'correctOrder': [0, 1, 2],
          'type': 'math',
          'explanation': 'Move constants first, then isolate the variable.',
          'points': 1.0,
          'marksPerQuestion': 1.0,
          'mathDifficulty': 'easy',
          'answerOnce': false,
          'showFeedbackInstantly': true,
        });
      } else if (type == BlockType.theorem) {
        finalContent = jsonEncode({
          'statementType': 'theorem',
          'number': '',
          'title': '',
          'statement': '',
          'tags': <String>[],
          'linkedProofBlockId': null,
        });
      } else if (type == BlockType.proof) {
        finalContent = jsonEncode({
          'proofOf': '',
          'strategy': '',
          'steps': [
            {
              'number': '1',
              'statement': '',
              'justification': '',
              'isKeyStep': false,
            },
          ],
          'qedStyle': 'halmos',
        });
      } else if (type == BlockType.definition) {
        finalContent = jsonEncode({
          'term': '',
          'number': '',
          'domain': '',
          'formalDefinition': '',
          'informalSummary': '',
          'relatedTerms': <String>[],
        });
      } else if (type == BlockType.example) {
        finalContent = jsonEncode({
          'number': '',
          'title': '',
          'difficulty': 1,
          'context': '',
          'problem': '',
          'solutionSteps': [
            {'label': 'Step 1', 'content': '', 'hint': ''},
          ],
          'finalAnswer': '',
          'checkYourUnderstanding': <String>[],
        });
      } else if (type == BlockType.learningObjective) {
        finalContent = jsonEncode({
          'sectionScope': '',
          'objectives': [
            {
              'id': '',
              'verb': 'Explain',
              'statement': '',
              'bloomsLevel': 2,
              'linkedAssessmentBlockIds': <String>[],
            },
          ],
        });
      } else if (type == BlockType.conceptSummary) {
        finalContent = jsonEncode({
          'sectionTitle': '',
          'keyPoints': [''],
          'keyFormulas': <String>[],
          'keyTerms': <String>[],
          'commonMistakes': <String>[],
          'nextSteps': '',
        });
      } else if (type == BlockType.numericalQuestion) {
        finalContent = jsonEncode({
          'question': '',
          'correctValue': 0,
          'tolerancePercent': 1,
          'unit': '',
          'acceptedUnitAliases': <String>[],
          'hint': '',
          'solution': '',
          'significantFigures': 0,
        });
      } else if (type == BlockType.glossary) {
        finalContent = jsonEncode({
          'scope': 'document',
          'customTermIds': <String>[],
          'showDomainTags': true,
          'showPageRefs': false,
        });
      } else if (type == BlockType.parametricGraph) {
        finalContent = jsonEncode({
          'expression': 'a*sin(b*x+c)',
          'parameters': [
            {
              'name': 'a',
              'label': 'Amplitude',
              'min': -5,
              'max': 5,
              'step': 0.1,
              'defaultValue': 1,
            },
            {
              'name': 'b',
              'label': 'Frequency',
              'min': 0.1,
              'max': 5,
              'step': 0.1,
              'defaultValue': 1,
            },
            {
              'name': 'c',
              'label': 'Phase',
              'min': -3.14,
              'max': 3.14,
              'step': 0.05,
              'defaultValue': 0,
            },
          ],
          'xDomain': [-10, 10],
          'yDomain': [-5, 5],
          'showGrid': true,
          'showAxesLabels': false,
          'caption': '',
        });
      } else if (type == BlockType.citation) {
        finalContent = jsonEncode({
          'citationKey': '',
          'type': 'book',
          'authors': <String>[],
          'title': '',
          'year': DateTime.now().year,
          'journal': '',
          'volume': '',
          'pages': '',
          'doi': '',
          'url': '',
          'accessedDate': '',
        });
      } else if (type == BlockType.toc) {
        finalContent = jsonEncode({
          'title': 'Contents',
          'depth': 'pages',
          'showPageNumbers': true,
          'numbered': true,
        });
      } else if (type == BlockType.faq) {
        finalContent = jsonEncode({
          'header': '',
          'items': [
            {'question': '', 'answer': ''},
          ],
        });
      } else if (type == BlockType.keyPoint) {
        finalContent = jsonEncode({
          'header': '',
          'items': [
            {'icon': '💡', 'title': '', 'description': ''},
          ],
        });
      }

      final block = Block(
        content: finalContent.isEmpty ? '{}' : finalContent,
        position: state.length,
        type: type,
        style: style,
      );

      final id = await _repository.addBlock(block);
      final newBlock = block.copyWith(id: id);

      if (mounted) {
        state = [...state, newBlock];
        editingBlockId = id;
        logger.i('Block added: $id, type: $type');
      }
    } catch (e, stackTrace) {
      logger.e('Failed to add block: $type', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Adds a graph block with the specified graph type
  Future<void> addGraphBlock({required EnhancedGraphType graphType}) async {
    try {
      BlockStyle style = _operationsService.getStyleForType(BlockType.graph);

      // Create default content based on graph type
      Map<String, dynamic> defaultContent = {};

      // Map EnhancedGraphType to the graph type string
      String graphTypeString = _getGraphTypeString(graphType);

      // Set default content based on the graph category
      switch (graphType.category) {
        case GraphCategory.mathematical:
          defaultContent = {
            'type': graphTypeString,
            'expression': '',
            'caption': '',
            'min_x': '-10',
            'max_x': '10',
            'color_scheme': 'default',
          };
          break;

        case GraphCategory.business:
          // Syncfusion charts - default data structure
          defaultContent = {
            'type': graphTypeString,
            'chartType': graphTypeString,
            'data': [],
            'xAxisLabel': 'X Axis',
            'yAxisLabel': 'Y Axis',
            'title': '',
            'caption': '',
            'showLegend': true,
            'showDataLabels': false,
          };
          break;

        case GraphCategory.diagram:
          // GraphView diagrams - default node structure
          defaultContent = {
            'type': graphTypeString,
            'diagramType': graphTypeString,
            'nodes': [],
            'edges': [],
            'title': '',
            'caption': '',
            'layoutType': 'hierarchical',
          };
          break;
      }

      final block = Block(
        content: jsonEncode(defaultContent),
        position: state.length,
        type: BlockType.graph,
        style: style,
      );

      final id = await _repository.addBlock(block);
      final newBlock = block.copyWith(id: id);

      if (mounted) {
        state = [...state, newBlock];
        editingBlockId = id;
        logger.i('Graph block added: $id, graphType: ${graphType.name}');
      }
    } catch (e, stackTrace) {
      logger.e('Failed to add graph block', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Helper method to convert EnhancedGraphType to string
  String _getGraphTypeString(EnhancedGraphType graphType) {
    // For backward compatibility with existing graph types
    switch (graphType) {
      case EnhancedGraphType.line:
        return 'line';
      case EnhancedGraphType.parametric:
        return 'parametric';
      case EnhancedGraphType.polar:
        return 'polar';
      case EnhancedGraphType.bar:
        return 'bar';
      case EnhancedGraphType.scatter:
        return 'scatter';
      default:
        // For new types, use the enum name
        return graphType.name;
    }
  }

  /// Adds a block with pre-specified content (useful for duplicating media blocks with different trim ranges)
  Future<void> addBlockWithContent({
    required String content,
    required BlockType type,
    BlockStyle? style,
  }) async {
    try {
      final blockStyle = style ?? _operationsService.getStyleForType(type);

      final block = Block(
        content: content,
        position: state.length,
        type: type,
        style: blockStyle,
      );

      final id = await _repository.addBlock(block);
      final newBlock = block.copyWith(id: id);

      if (mounted) {
        state = [...state, newBlock];
        logger.i('Block added with content: $id, type: $type');
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add block with content: $type',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds a block from AI generation (preserves the block's content and style)
  Future<String?> addBlockFromAI(Block aiBlock) async {
    try {
      final block = Block(
        content: aiBlock.content,
        position: state.length,
        type: aiBlock.type,
        style: aiBlock.style,
      );

      final id = await _repository.addBlock(block);
      final newBlock = block.copyWith(id: id);

      if (mounted) {
        state = [...state, newBlock];
        logger.i('AI block added: $id, type: ${aiBlock.type}');
        return id;
      }
      return null;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add AI block: ${aiBlock.type}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds an image block from a file (file picker)
  Future<void> addImageFromFile() async {
    try {
      final imageResult = await _mediaService.handleImageFromFile();
      if (imageResult == null) return;

      await addBlockWithContent(
        content: jsonEncode(imageResult),
        type: BlockType.image,
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add image from file',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds an image block from a URL
  Future<void> addImageFromUrl(String url) async {
    if (!_pathValidator.isFileOperationSupported) return;
    try {
      final imageResult = await _mediaService.handleImageFromUrl(url);
      if (imageResult == null) return;

      await addBlockWithContent(
        content: jsonEncode(imageResult),
        type: BlockType.image,
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add image from URL',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds an image block from camera
  Future<void> addImageFromCamera() async {
    if (!_pathValidator.isFileOperationSupported) return;
    try {
      final imageResult = await _mediaService.handleImageFromCamera();
      if (imageResult == null) return;

      await addBlockWithContent(
        content: jsonEncode(imageResult),
        type: BlockType.image,
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add image from camera',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds a video block from a file (file picker or gallery)
  Future<void> addVideoFromFile() async {
    try {
      final videoResult = await _mediaService.handleVideoFromFile();
      if (videoResult == null) return;

      await addBlockWithContent(
        content: jsonEncode(videoResult),
        type: BlockType.video,
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add video from file',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds a video block from a URL
  Future<void> addVideoFromUrl(String url) async {
    if (!_pathValidator.isFileOperationSupported) return;
    try {
      final videoResult = await _mediaService.handleVideoFromUrl(url);
      if (videoResult == null) return;

      await addBlockWithContent(
        content: jsonEncode(videoResult),
        type: BlockType.video,
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add video from URL',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds a video block from camera
  Future<void> addVideoFromCamera() async {
    if (!_pathValidator.isFileOperationSupported) return;
    try {
      final videoResult = await _mediaService.handleVideoFromCamera();
      if (videoResult == null) return;

      await addBlockWithContent(
        content: jsonEncode(videoResult),
        type: BlockType.video,
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add video from camera',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds an audio block from a file (file picker)
  Future<void> addAudioFromFile() async {
    try {
      final audioResult = await _mediaService.handleAudioFromFile();
      if (audioResult == null) return;

      await addBlockWithContent(
        content: jsonEncode(audioResult),
        type: BlockType.audio,
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add audio from file',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds an audio block from a URL
  Future<void> addAudioFromUrl(String url) async {
    if (!_pathValidator.isFileOperationSupported) return;
    try {
      final audioResult = await _mediaService.handleAudioFromUrl(url);
      if (audioResult == null) return;

      await addBlockWithContent(
        content: jsonEncode(audioResult),
        type: BlockType.audio,
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add audio from URL',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Adds an audio block from recording (microphone)
  Future<void> addAudioFromRecording() async {
    if (!_pathValidator.isFileOperationSupported) return;
    try {
      final audioResult = await _mediaService.handleAudioFromRecording();
      if (audioResult == null) return;

      await addBlockWithContent(
        content: jsonEncode(audioResult),
        type: BlockType.audio,
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add audio from recording',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  void _updateBlockInMemory(Block block) {
    final idx = state.indexWhere((b) => b.id == block.id);
    if (idx != -1) {
      final newBlocks = List<Block>.from(state);
      newBlocks[idx] = block;
      state = newBlocks;
    }
  }

  Future<String?> duplicateBlock(Block block) async {
    try {
      final (id, newBlocks) = await _orderingService.duplicateBlock(
        block,
        state,
      );
      if (mounted) {
        state = newBlocks;
        return id;
      }
      return null;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to duplicate block: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> moveBlockUp(Block block) async {
    final index = state.indexOf(block);
    if (index <= 0) return;
    try {
      final newBlocks = await _orderingService.moveBlockUp(block, state);
      if (mounted) {
        state = newBlocks;
        logger.i('Block moved up: ${block.id}');
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to move block up: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> moveBlockDown(Block block) async {
    final index = state.indexOf(block);
    if (index < 0 || index >= state.length - 1) return;
    try {
      final newBlocks = await _orderingService.moveBlockDown(block, state);
      if (mounted) {
        state = newBlocks;
        logger.i('Block moved down: ${block.id}');
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to move block down: ${block.id}',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> saveBlockOrder(List<Block> updatedBlocks) async {
    try {
      final newBlocks = await _orderingService.saveBlockOrder(updatedBlocks);
      if (mounted) {
        state = newBlocks;
        logger.i('Block order saved');
      }
    } catch (e, stackTrace) {
      logger.e('Failed to save block order', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getDocumentMetadata() async {
    try {
      final metadata = await _documentService.getDocumentMetadata(docDir);
      logger.i('Metadata retrieved for document: ${docDir.path}');
      return metadata;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to get document metadata: ${docDir.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> updateDocumentInfo(
    String name,
    String description,
    String tags,
    String coverPath,
  ) async {
    try {
      if (coverPath.isNotEmpty &&
          !await _pathValidator.isValidMediaPath(
            _pathValidator.resolveRelativePath(coverPath),
          )) {
        logger.w('Invalid cover path: $coverPath');
        return false;
      }
      final success = await _documentService.updateDocumentInfo(
        docDir,
        name,
        description,
        tags,
        coverPath,
      );
      logger.i('Document info updated: ${docDir.path}');
      return success;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to update document info: ${docDir.path}',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

extension EditDocumentControllerExtension on WidgetRef {
  EditDocumentController editDocumentController(Directory docDir) =>
      read(editDocumentControllerProvider(docDir).notifier);
}
