import 'dart:io';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:barruu/core/services/ai/ai_service.dart';
import 'package:file_picker/file_picker.dart';

import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/utils/ui_utils.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/data/sources/document_local_source.dart';
import 'package:barruu/features/workspace/utils/link_utils.dart';
import 'package:barruu/core/services/file_extraction_service.dart';
import 'package:go_router/go_router.dart' hide Block;

/// Chat message model for UI
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isLoading;
  final AIGenerationResult? generatedContent;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.isLoading = false,
    this.generatedContent,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// AI Chat Page - Full page chat interface like OpenAI
class AIChatPage extends ConsumerStatefulWidget {
  final Directory? docDir;

  const AIChatPage({super.key, this.docDir});

  @override
  ConsumerState<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends ConsumerState<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  final FileExtractionService _fileExtractionService = FileExtractionService();
  bool _isLoading = false;
  AIGenerationType _selectedType = AIGenerationType.page;
  String? _extractedText;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        role: 'assistant',
        content:
            "Hi! I'm your AI assistant. Select a mode below, then describe what you want to create.",
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Handle file upload for document processing
  Future<void> _handleFileUpload() async {
    if (_isLoading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: false,
        withReadStream: false,
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        logger.i('No file selected for upload');
        return;
      }

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      // Add user message showing file upload
      setState(() {
        _messages.add(
          ChatMessage(role: 'user', content: '📎 Uploaded file: **$fileName**'),
        );
        _isLoading = true;
      });
      _scrollToBottom();

      // Add loading message for extraction
      setState(() {
        _messages.add(
          ChatMessage(role: 'assistant', content: '', isLoading: true),
        );
      });
      _scrollToBottom();

      // Extract text from file
      final extractedText = await _fileExtractionService.extractTextFromFile(
        file,
      );

      if (extractedText == null || extractedText.isEmpty) {
        setState(() {
          _messages.removeLast();
          _messages.add(
            ChatMessage(
              role: 'assistant',
              content:
                  '❌ **Extraction Failed**\n\nCould not extract text from the file. Please make sure:\n• The file is not empty\n• The file is a valid text file\n• The file is not corrupted',
            ),
          );
          _isLoading = false;
        });
        return;
      }

      // Store extracted text
      _extractedText = extractedText;

      final wordCount = extractedText.split(RegExp(r'\s+')).length;
      final charCount = extractedText.length;

      setState(() {
        _messages.removeLast();
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content:
                '''✅ **File Processed Successfully!**

📊 **Extracted Content:**
• Characters: $charCount
• Words: ~$wordCount

🤖 **Processing with AI...**
Extracting questions, adding answers and explanations...''',
          ),
        );
      });
      _scrollToBottom();

      // Automatically process the document with AI
      await _processUploadedDocument();
    } catch (e, stackTrace) {
      logger.e('File upload error', error: e, stackTrace: stackTrace);
      final errorMessage = _fileExtractionService.getErrorMessage(e);

      setState(() {
        if (_messages.isNotEmpty && _messages.last.isLoading) {
          _messages.removeLast();
        }
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content: '❌ **File Upload Failed**\n\n$errorMessage',
          ),
        );
        _isLoading = false;
      });
    }
  }

  /// Clear uploaded document and extracted text
  void _clearUploadedDocument() {
    setState(() {
      _extractedText = null;
    });

    // Add feedback message
    setState(() {
      _messages.add(
        ChatMessage(
          role: 'assistant',
          content:
              '🗑️ **Uploaded document cleared**\n\nYou can upload a new file or continue with other tasks.',
        ),
      );
    });
    _scrollToBottom();
  }

  /// Process uploaded document automatically with AI
  Future<void> _processUploadedDocument() async {
    if (_extractedText == null || _extractedText!.isEmpty) {
      return;
    }

    try {
      // Check if API is configured
      if (!DeepSeekConfig.isConfigured) {
        setState(() {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              content:
                  '❌ API Key Not Configured\n\nPlease add your AI API key to the .env file:\n\nDEEP_SEEK_API_KEY=your_api_key_here',
            ),
          );
          _isLoading = false;
        });
        return;
      }

      // Add loading message
      setState(() {
        _messages.add(
          ChatMessage(role: 'assistant', content: '', isLoading: true),
        );
      });
      _scrollToBottom();

      final aiService = ref.read(aiContentServiceProvider);

      // Default prompt for exam processing
      const defaultPrompt =
          'Extract all questions from this document, provide correct answers, and add detailed explanations for each. Format it beautifully with proper structure, emojis, and interactive elements where appropriate.';

      final result = await aiService.generate(
        AIGenerationRequest(
          type: AIGenerationType.fromDocument,
          prompt: defaultPrompt,
          documentContent: _extractedText,
        ),
      );

      setState(() {
        _messages.removeLast(); // Remove loading message

        if (result.success) {
          final blocksCount =
              result.blocks?.length ??
              (result.pages?.fold<int>(
                    0,
                    (sum, page) => sum + page.blocks.length,
                  ) ??
                  0);
          final pagesCount = result.pages?.length ?? 0;

          String responseContent = '✅ **Content Generated Successfully!**\n\n';

          if (pagesCount > 0) {
            responseContent +=
                '📄 Generated **$pagesCount page(s)** with **$blocksCount block(s)**\n\n';
            for (int i = 0; i < result.pages!.length; i++) {
              final page = result.pages![i];
              responseContent += '**Page ${i + 1}: ${page.title}**\n';
              responseContent += '• ${page.blocks.length} blocks\n';
            }
          } else {
            responseContent += '📦 Generated **$blocksCount block(s)**\n';
          }

          if (result.tokensUsed != null) {
            responseContent += '\n_Tokens used: ${result.tokensUsed}_';
          }

          responseContent +=
              '\n\n💡 You can ask follow-up questions about this content!';

          _messages.add(
            ChatMessage(
              role: 'assistant',
              content: responseContent,
              generatedContent: result,
            ),
          );
        } else {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              content:
                  '❌ **Generation Failed**\n\n${result.error ?? "Unknown error occurred"}',
            ),
          );
        }
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e, stackTrace) {
      logger.e('AI processing error', error: e, stackTrace: stackTrace);
      setState(() {
        _messages.removeLast();
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content: '❌ **Error Processing Document**\n\n$e',
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: message));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Add loading message
    setState(() {
      _messages.add(
        ChatMessage(role: 'assistant', content: '', isLoading: true),
      );
    });
    _scrollToBottom();

    try {
      // Check if API is configured
      if (!DeepSeekConfig.isConfigured) {
        setState(() {
          _messages.removeLast();
          _messages.add(
            ChatMessage(
              role: 'assistant',
              content:
                  '❌ API Key Not Configured\n\nPlease add your AI API key to the .env file:\n\nDEEP_SEEK_API_KEY=your_api_key_here',
            ),
          );
          _isLoading = false;
        });
        return;
      }

      final aiService = ref.read(aiContentServiceProvider);

      // Get existing blocks from current page for context (to avoid content mixing)
      List<Block>? existingBlocks;
      String? contextInfo;

      if (widget.docDir != null &&
          (_selectedType == AIGenerationType.page ||
              _selectedType == AIGenerationType.block)) {
        try {
          // Read the state from StateNotifierProvider which gives us List<Block>
          existingBlocks = ref.read(
            editDocumentControllerProvider(widget.docDir!),
          );

          if (existingBlocks != null && existingBlocks.isNotEmpty) {
            // Create summary of existing content to avoid duplication
            final blockTypes = existingBlocks
                .map((b) => b.type.displayName)
                .toSet()
                .join(', ');
            contextInfo =
                'This page already has ${existingBlocks.length} blocks: $blockTypes. Please generate NEW content that complements (not duplicates) the existing content.';
          }
        } catch (e) {
          logger.w('Could not get existing blocks for context', error: e);
        }
      }

      // Determine if we should use fromDocument type (when we have extracted text)
      final effectiveType =
          (_extractedText != null && _extractedText!.isNotEmpty)
          ? AIGenerationType.fromDocument
          : _selectedType;

      final result = await aiService.generate(
        AIGenerationRequest(
          type: effectiveType,
          prompt: message,
          existingBlocks: existingBlocks,
          context: contextInfo,
          documentContent: _extractedText,
        ),
      );

      // Keep extracted text for follow-up questions
      // Don't clear it automatically - let user upload a new file to replace it

      setState(() {
        _messages.removeLast(); // Remove loading message

        if (result.success) {
          final blocksCount =
              result.blocks?.length ??
              (result.pages?.fold<int>(
                    0,
                    (sum, page) => sum + page.blocks.length,
                  ) ??
                  0);
          final pagesCount = result.pages?.length ?? 0;

          String responseContent = '✅ **Content Generated Successfully!**\n\n';

          if (pagesCount > 0) {
            responseContent +=
                '📄 Generated **$pagesCount page(s)** with **$blocksCount block(s)**\n\n';
            for (int i = 0; i < result.pages!.length; i++) {
              final page = result.pages![i];
              responseContent += '**Page ${i + 1}: ${page.title}**\n';
              responseContent += '• ${page.blocks.length} blocks\n';
            }
          } else {
            responseContent += '📦 Generated **$blocksCount block(s)**\n';
          }

          if (result.tokensUsed != null) {
            responseContent += '\n_Tokens used: ${result.tokensUsed}_';
          }

          _messages.add(
            ChatMessage(
              role: 'assistant',
              content: responseContent,
              generatedContent: result,
            ),
          );
        } else {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              content:
                  '❌ **Generation Failed**\n\n${result.error ?? "Unknown error occurred"}',
            ),
          );
        }
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      logger.e('AI chat error', error: e, stackTrace: stackTrace);
      setState(() {
        _messages.removeLast();

        // Extract user-friendly error message
        String errorMessage = e.toString();
        // Remove common exception prefixes for cleaner error messages
        if (errorMessage.contains('DeepSeekException:')) {
          errorMessage = errorMessage.replaceFirst('DeepSeekException: ', '');
        } else if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.replaceFirst(
            RegExp(r'\b\w+Exception:\s+'),
            '',
          );
        }

        _messages.add(
          ChatMessage(
            role: 'assistant',
            content:
                '❌ Error\n\n$errorMessage\n\nPlease try again or use a simpler prompt.',
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _addToDocument(AIGenerationResult result) async {
    if (widget.docDir == null) {
      UIUtils.showSnackBar(
        context,
        'No document selected. Please open a document first.',
        isError: true,
      );
      return;
    }

    try {
      int addedCount = 0;
      int pagesCreated = 0;
      List<String> pageNames = [];
      String? firstCreatedPageId; // Track first created page ID

      if (result.blocks != null && result.blocks!.isNotEmpty) {
        // Single page with blocks - add to current page
        final controller = ref.read(
          editDocumentControllerProvider(widget.docDir!).notifier,
        );
        for (final block in result.blocks!) {
          await controller.addBlockFromAI(block);
          addedCount++;
        }
      } else if (result.pages != null && result.pages!.isNotEmpty) {
        final documentService = ref.read(documentServiceProvider);

        if (result.pages!.length == 1) {
          // Single page - add to current page
          final controller = ref.read(
            editDocumentControllerProvider(widget.docDir!).notifier,
          );
          final page = result.pages!.first;
          for (final block in page.blocks) {
            await controller.addBlockFromAI(block);
            addedCount++;
          }
        } else {
          // Multiple pages - create new pages and add blocks
          final currentPageNotifier = ref.read(
            currentPageIdProvider(widget.docDir!.path).notifier,
          );

          for (int i = 0; i < result.pages!.length; i++) {
            final aiPage = result.pages![i];

            // Create new page
            final newPage = await documentService.createPage(
              widget.docDir!,
              aiPage.title,
            );
            if (newPage == null) {
              logger.w('Failed to create page: ${aiPage.title}');
              continue;
            }

            pagesCreated++;
            pageNames.add(aiPage.title);

            // Remember the first created page ID
            firstCreatedPageId ??= newPage.id;

            // Switch to the new page temporarily to add blocks
            currentPageNotifier.state = newPage.id;

            // Get controller for the new page
            final controller = ref.read(
              editDocumentControllerProvider(widget.docDir!).notifier,
            );

            // Add blocks to the new page
            for (final block in aiPage.blocks) {
              await controller.addBlockFromAI(block);
              addedCount++;
            }
          }

          // Switch back to first created page so user can see it
          if (firstCreatedPageId != null) {
            currentPageNotifier.state = firstCreatedPageId;
          }
        }
      }

      if (mounted) {
        String message;
        if (pagesCreated > 0) {
          message =
              'Created **$pagesCreated page(s)** with **$addedCount blocks** total';
          if (pageNames.isNotEmpty) {
            final pageList = pageNames.map((name) => '• $name').join('\n');
            message = '$message:\n\n$pageList';
          }
        } else {
          message = 'Added **$addedCount blocks** to current page';
        }

        UIUtils.showSnackBar(context, 'Content added successfully');

        // Add confirmation message
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', content: '✅ $message'));
        });
        _scrollToBottom();
      }
    } catch (e, stackTrace) {
      logger.e(
        'Failed to add content to document',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        UIUtils.showSnackBar(
          context,
          'Failed to add content: $e',
          isError: true,
        );

        setState(() {
          _messages.add(
            ChatMessage(
              role: 'assistant',
              content: '❌ Failed to add content: ${e.toString()}',
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTypeChip(
              AIGenerationType.page,
              'Page',
              IconsaxPlusLinear.note,
              'Single page with blocks',
              theme,
            ),
            const SizedBox(width: 8),
            _buildTypeChip(
              AIGenerationType.block,
              'Block',
              IconsaxPlusLinear.element_3,
              'Add one block',
              theme,
            ),
            const SizedBox(width: 8),
            _buildTypeChip(
              AIGenerationType.interactiveNotes,
              'Study Notes',
              IconsaxPlusLinear.lamp_on,
              'Notes with exercises',
              theme,
            ),
            const SizedBox(width: 8),
            _buildTypeChip(
              AIGenerationType.fullDocument,
              'Document',
              IconsaxPlusLinear.document,
              'Multi-page document',
              theme,
            ),
            const SizedBox(width: 8),
            _buildTypeChip(
              AIGenerationType.fromDocument,
              'From File',
              IconsaxPlusLinear.document_upload,
              'Upload & process file',
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(
    AIGenerationType type,
    String label,
    IconData icon,
    String tooltip,
    ThemeData theme,
  ) {
    final isSelected = _selectedType == type;
    return Tooltip(
      message: tooltip,
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedType = type),
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: theme.colorScheme.onPrimary,
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        showCheckmark: false,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 1.5 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }

  Color _getTextColor(bool isUser, ThemeData theme) {
    return isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
  }

  Color _getLinkColor(bool isUser, ThemeData theme) {
    return isUser
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
        : theme.colorScheme.primary;
  }

  Color _getBlockquoteColor(bool isUser, ThemeData theme) {
    return isUser
        ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
        : theme.colorScheme.onSurface.withValues(alpha: 0.8);
  }

  Widget _buildMessage(ChatMessage message, ThemeData theme) {
    final isUser = message.role == 'user';
    final isLoading = message.isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                IconsaxPlusLinear.magic_star,
                size: 20,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShimmerInlineLoading(
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Generating content...',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    )
                  else
                    MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 15,
                          height: 1.5,
                        ),
                        strong: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                        em: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 15,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                        a: TextStyle(
                          color: _getLinkColor(isUser, theme),
                          fontSize: 15,
                          height: 1.5,
                          decoration: TextDecoration.underline,
                        ),
                        listBullet: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 15,
                          height: 1.5,
                        ),
                        checkbox: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 15,
                          height: 1.5,
                        ),
                        tableHead: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        tableBody: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 15,
                          height: 1.5,
                        ),
                        tableBorder: TableBorder.all(
                          color: isUser
                              ? theme.colorScheme.onPrimary.withValues(
                                  alpha: 0.3,
                                )
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.5,
                                ),
                          width: 1,
                        ),
                        tableColumnWidth: const FlexColumnWidth(),
                        tableCellsPadding: const EdgeInsets.all(8),
                        h1: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h2: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h3: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h4: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h5: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        h6: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                        code: TextStyle(
                          color: _getTextColor(isUser, theme),
                          fontSize: 14,
                          fontFamily: 'monospace',
                          backgroundColor: isUser
                              ? theme.colorScheme.primary.withValues(alpha: 0.2)
                              : theme.colorScheme.surfaceContainerHighest,
                        ),
                        blockquote: TextStyle(
                          color: _getBlockquoteColor(isUser, theme),
                          fontSize: 15,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isUser
                                  ? theme.colorScheme.onPrimary.withValues(
                                      alpha: 0.5,
                                    )
                                  : theme.colorScheme.primary.withValues(
                                      alpha: 0.5,
                                    ),
                              width: 4,
                            ),
                          ),
                        ),
                        blockquotePadding: const EdgeInsets.only(
                          left: 12,
                          top: 4,
                          bottom: 4,
                        ),
                      ),
                      selectable: true,
                      onTapLink: (text, href, title) async {
                        if (href != null) {
                          await LinkUtils.launchURL(href);
                        }
                      },
                    ),
                  if (message.generatedContent != null &&
                      widget.docDir != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () =>
                          _addToDocument(message.generatedContent!),
                      icon: const Icon(IconsaxPlusLinear.add, size: 18),
                      label: const Text('Add to Document'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.tertiary,
              child: Icon(
                Icons.person,
                size: 20,
                color: theme.colorScheme.onTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypeSelector(theme),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 4,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // File upload button (only show when fromDocument is selected)
                if (_selectedType == AIGenerationType.fromDocument) ...[
                  IconButton(
                    onPressed: _isLoading ? null : _handleFileUpload,
                    icon: Icon(
                      _extractedText != null && _extractedText!.isNotEmpty
                          ? IconsaxPlusLinear.document_text_1
                          : IconsaxPlusLinear.document_upload,
                      color:
                          _extractedText != null && _extractedText!.isNotEmpty
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    tooltip:
                        _extractedText != null && _extractedText!.isNotEmpty
                        ? 'File uploaded — upload another'
                        : 'Upload text file (.txt)',
                  ),
                  // Clear button when document is uploaded
                  if (_extractedText != null && _extractedText!.isNotEmpty)
                    IconButton(
                      onPressed: _isLoading ? null : _clearUploadedDocument,
                      icon: Icon(
                        IconsaxPlusLinear.close_circle,
                        color: theme.colorScheme.error,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.errorContainer
                            .withValues(alpha: 0.3),
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      tooltip: 'Clear uploaded file',
                    ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      maxLines: 6,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _getPlaceholder(),
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  backgroundColor: _isLoading
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primary,
                  foregroundColor: _isLoading
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onPrimary,
                  elevation: 2,
                  child: _isLoading
                      ? ShimmerInlineLoading(
                          size: 24,
                          color: theme.colorScheme.primary,
                        )
                      : const Icon(IconsaxPlusLinear.send_1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPlaceholder() {
    switch (_selectedType) {
      case AIGenerationType.page:
        return 'e.g. "Spanish vocabulary for beginners" or "Notes on photosynthesis"';
      case AIGenerationType.block:
        return 'e.g. "A quiz question about gravity" or "A list of Python data types"';
      case AIGenerationType.interactiveNotes:
        return 'e.g. "English grammar — past tense" or "Cell biology basics"';
      case AIGenerationType.fullDocument:
        return 'e.g. "Complete JavaScript course with exercises"';
      case AIGenerationType.fromDocument:
        if (_extractedText != null && _extractedText!.isNotEmpty) {
          return 'What should I do with the uploaded document?';
        }
        return 'Upload a .txt file first, or describe what to generate...';
      default:
        return 'Describe what you want to create...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(IconsaxPlusLinear.arrow_left_2),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconsaxPlusLinear.magic_star,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'AI Assistant',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.docDir != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: Icon(
                  IconsaxPlusLinear.document,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                label: const Text('Document'),
                backgroundColor: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                labelStyle: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(IconsaxPlusLinear.trash),
            tooltip: 'Clear chat',
            onPressed: _messages.length > 1
                ? () {
                    setState(() {
                      _messages.clear();
                      _messages.add(
                        ChatMessage(
                          role: 'assistant',
                          content: '👋 Chat cleared! How can I help you?',
                        ),
                      );
                    });
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index], theme);
              },
            ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }
}
