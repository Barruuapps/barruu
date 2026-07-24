import 'dart:convert';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/services/ai/deepseek_api_service.dart';
import 'package:barruu/core/services/ai/deepseek_models.dart';
import 'package:barruu/core/services/ai/block_schema_documentation.dart';
import 'package:barruu/core/services/ai/ai_generation_request.dart';
import 'package:barruu/core/services/ai/ai_generation_result.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';

// Export for convenience
export 'package:barruu/core/services/ai/ai_generation_request.dart';
export 'package:barruu/core/services/ai/ai_generation_result.dart';

/// Service for AI-powered content generation in Barruu.
///
/// This service uses DeepSeek AI to generate professional documents, pages, and blocks
/// based on user prompts and existing content for knowledge sharing across all professions.
class AIContentService {
  final DeepSeekApiService _apiService;

  // Token limits for different request types (DeepSeek API max is 8192)
  // All set to max because different generation types may need varying amounts of tokens
  // fullDocument: May need full capacity for multiple pages
  // interactiveNotes: May need full capacity for detailed explanations
  // fromDocument: May need full capacity to process uploaded content
  // page: May need full capacity for complex layouts with many blocks
  // block: Reduced to 4096 as single blocks typically need less
  static const int _maxTokensFullDocument = 8192;
  static const int _maxTokensInteractiveNotes = 8192;
  static const int _maxTokensFromDocument = 8192;
  static const int _maxTokensPage = 8192;
  static const int _maxTokensBlock = 4096;

  AIContentService({DeepSeekApiService? apiService})
    : _apiService = apiService ?? DeepSeekApiService();

  /// Get the system prompt for content generation
  String _getSystemPrompt() {
    return '''You are an expert AI agent for Barruu, a professional knowledge-sharing platform. You generate structured content using a block-based system. Your output must always be valid JSON.

${BlockSchemaDocumentation.getFullSchemaDocumentation()}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 1 — UNDERSTAND WHAT IS BEING CREATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Before choosing blocks, identify the content category from the prompt:

A) EDUCATIONAL / COURSE CONTENT (language course, math lesson, quiz, exam prep, subject study)
   → Prioritize interactive blocks: multipleChoice, trueFalse, fillInBlank, matching, wordOrder
   → Also use: header, paragraph, list, blockquote, divider, table
   → Avoid: checkbox (not a quiz tool), cards (not educational by default)

B) NOTES / REFERENCE MATERIAL (notes, summary, reference guide, cheat sheet, documentation)
   → Use: header, paragraph, list, blockquote, divider, table, code (if technical), math (if math)
   → Avoid: checkbox (unless explicitly a to-do note), interactive question blocks

C) STORY / ARTICLE / NEWS / BLOG (story, news, article, essay, blog post, narrative)
   → Use: header, paragraph, blockquote, list, divider
   → Avoid: checkbox, interactive question blocks, code, math (unless content-specific)

D) TECHNICAL DOCUMENT (programming tutorial, API docs, setup guide, code walkthrough)
   → Use: header, paragraph, code, list, table, blockquote, math (if equations), stepper
   → Avoid: checkbox, interactive question blocks (unless it's a quiz section)

E) TASK / CHECKLIST / TO-DO (project plan, to-do list, checklist, workflow)
   → Use: header, checkbox, list, paragraph, divider
   → Interactive question blocks are NOT appropriate here

F) PRESENTATION / APP SCREEN (slides, overview, landing page, showcase)
   → Use: header, paragraph, cards, tabs, columns, stepper, expandable
   → Use interactive blocks only if content is educational

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 2 — CHOOSE BLOCKS PRECISELY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BLOCK SELECTION RULES (apply based on content category above):

"header"          → Section titles. Use sparingly — one per major section.
"paragraph"       → Plain explanatory text. Keep SHORT (1-3 sentences, max 150 words).
"list"            → Bullet or numbered lists. Items must be plain text (no code, no markdown tables).
"blockquote"      → Callouts: quoteType "tip", "note", "warning", "success", "info". Use for key points.
"divider"         → Visual separator between major sections.
"table"           → Structured data in rows/columns. NEVER use markdown tables inside paragraph blocks.
"code"            → ONLY for actual programming code, scripts, or terminal commands.
"math"            → ONLY for LaTeX mathematical formulas. NEVER embed equations in paragraphs.
"checkbox"        → ONLY for to-do lists, checklists, task lists. NOT for notes or quizzes.
"cards"           → Visual highlight cards. Use for showcasing concepts, features, or items.
"tabs"            → Tabbed interface for organizing related sections.
"columns"         → Side-by-side layout (2-3 columns). Use for comparisons or parallel content.
"stepper"         → Step-by-step processes or procedures.
"expandable"      → Collapsible sections for FAQs or optional detail.
"multipleChoice"  → ONLY for educational quizzes/assessments. NOT for general lists.
"trueFalse"       → ONLY for true/false questions in educational context.
"fillInBlank"     → ONLY for fill-in-the-blank exercises.
"matching"        → ONLY for matching exercises (concept ↔ definition, word ↔ translation).
"wordOrder" → For ANY exercise where items must be placed in the correct order: math/algebra steps, chemical equation balancing steps, sentence word-ordering, historical timeline events, grammar construction, recipe steps, logical sequences. NOT limited to math — use whenever the learner must order items.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 3 — FORMATTING RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MARKDOWN (use inside block content text only):
- **bold** — for key terms and important phrases
- *italic* — for subtle emphasis or terminology
- [link text](https://url.com) — for references and external links (NEVER bare URLs)

EMOJIS:
- Use emojis ONLY if the user's prompt suggests it (e.g., "make it fun", "with emojis", "engaging")
- For professional/academic content: NO emojis in headers or list items by default
- If emojis are appropriate, use them sparingly and contextually — not on every block

STYLING:
- NEVER set color or background in style properties — let the app handle theming
- Headers: fontSize 24-32, bold: true
- Paragraphs: fontSize 16-18
- Code: language field must match the code type (javascript, python, dart, etc.)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ABSOLUTE RULES — NEVER BREAK THESE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. ALWAYS respond with valid JSON only — no explanatory text outside JSON
2. Use EXACT block type names (e.g., "multipleChoice" not "multiple_choice")
3. NEVER leave content fields empty — every block must have real content
4. Position blocks starting from 0, incrementing by 1
5. NEVER put code inside list items — use separate "code" blocks
6. NEVER use markdown tables inside paragraph or list blocks — use "table" block type
7. NEVER embed math equations in paragraph text — use "math" block type
8. NEVER use "checkbox" for notes, study content, or quiz answers
9. NEVER use "multipleChoice", "trueFalse", "fillInBlank", "matching" for non-educational content
10. Keep paragraphs SHORT — split long content into multiple paragraph blocks
11. NEVER set color or background style properties
12. QUANTITY — when generating exercises, quizzes, or interactive blocks: create at LEAST 5 items/questions per block type. Aim for 6-10 for thorough coverage. NEVER generate only 1 or 2 questions.
13. "wordOrder" is NOT limited to math — use it for any ordering task: word order in sentences, chemistry balancing steps, timelines, logical sequences, grammar construction exercises.
''';
  }

  /// Generate content based on the request
  Future<AIGenerationResult> generate(AIGenerationRequest request) async {
    try {
      logger.i('Starting AI content generation: ${request.type}');

      final messages = <DeepSeekMessage>[
        DeepSeekMessage.system(_getSystemPrompt()),
        _buildUserMessage(request),
      ];

      // Determine max tokens based on request type (larger for full documents/notes)
      final maxTokens = _getMaxTokensForRequest(request);

      final response = await _apiService.chatCompletion(
        messages: messages,
        temperature: 0.7,
        maxTokens: maxTokens,
      );

      return _parseResponse(response, request.type);
    } catch (e, stackTrace) {
      logger.e(
        'AI content generation failed',
        error: e,
        stackTrace: stackTrace,
      );
      return AIGenerationResult.failure('Content generation failed: $e');
    }
  }

  /// Get max tokens based on request type
  int _getMaxTokensForRequest(AIGenerationRequest request) {
    switch (request.type) {
      case AIGenerationType.fullDocument:
        // Full documents can be very large (300+ blocks)
        return _maxTokensFullDocument;
      case AIGenerationType.interactiveNotes:
        return _maxTokensInteractiveNotes;
      case AIGenerationType.fromDocument:
        // From document also needs substantial output
        return _maxTokensFromDocument;
      case AIGenerationType.page:
        // Single page with multiple blocks
        return _maxTokensPage;
      case AIGenerationType.block:
      case AIGenerationType.editBlocks:
        // Single block operations
        return _maxTokensBlock;
    }
  }

  /// Build the user message based on request type
  DeepSeekMessage _buildUserMessage(AIGenerationRequest request) {
    String prompt;

    switch (request.type) {
      case AIGenerationType.fullDocument:
        prompt = _buildDocumentPrompt(request);
        break;
      case AIGenerationType.page:
        prompt = _buildPagePrompt(request);
        break;
      case AIGenerationType.block:
        prompt = _buildBlockPrompt(request);
        break;
      case AIGenerationType.editBlocks:
        prompt = _buildEditPrompt(request);
        break;
      case AIGenerationType.fromDocument:
        prompt = _buildFromDocumentPrompt(request);
        break;
      case AIGenerationType.interactiveNotes:
        prompt = _buildInteractiveNotesPrompt(request);
        break;
    }

    return DeepSeekMessage.user(prompt);
  }

  /// Returns a shared block selection guidance text based on the content purpose.
  /// Used by all prompt builders to keep content-type rules consistent.
  static String _contentTypeGuidance() {
    return '''CONTENT TYPE ANALYSIS — apply BEFORE choosing blocks:
Identify which category the prompt falls into, then use ONLY appropriate blocks:

EDUCATIONAL / COURSE content (lesson, quiz, exam prep, language course, subject study):
  - Use interactive blocks where appropriate: multipleChoice, trueFalse, fillInBlank, matching, wordOrder
  - wordOrder is for ANY ordering exercise: math/algebra steps, chemistry balancing steps, word-order in sentences, historical timelines, grammar construction, recipe steps, logical sequences — NOT limited to math
  - Distribute interactive blocks naturally — not forced onto every section
  - QUANTITY: Create at least 5 questions/items per exercise block. Aim for 6-10. NEVER only 1 or 2.
  - Also use: header, paragraph, list, blockquote, divider, table, math (for formulas)
  - Do NOT use: checkbox (not a quiz tool)

NOTES / REFERENCE content (notes, summary, cheat sheet, reference guide, documentation):
  - Use: header, paragraph, list, blockquote, table, divider
  - Use code blocks ONLY for technical/programming content
  - Use math blocks ONLY for actual formulas
  - Do NOT use: checkbox, multipleChoice, trueFalse, fillInBlank, matching, wordOrder

STORY / ARTICLE / NEWS / BLOG content (story, article, essay, news, narrative, blog post):
  - Use: header, paragraph, blockquote, list, divider
  - Do NOT use: checkbox, interactive question blocks, code, math (unless content-specific)

TECHNICAL content (programming tutorial, API docs, code walkthrough, setup guide):
  - Use: header, paragraph, code, list, table, blockquote, stepper, math (if equations)
  - Do NOT use: checkbox, interactive question blocks

TASK / CHECKLIST content (to-do list, project plan, checklist, workflow):
  - Use: header, checkbox, list, paragraph, divider
  - Do NOT use: interactive question blocks

BLOCK STRUCTURE RULES (always apply):
- Paragraphs: SHORT (1-3 sentences, max 150 words) — split longer content into multiple blocks
- Math equations: ALWAYS use "math" block — never inside paragraph text
- Tables: ALWAYS use "table" block — never markdown tables inside paragraph/list blocks
- Code: ONLY for actual programming code, scripts, or terminal commands
- checkbox: ONLY for to-do/task lists — NOT for notes or quiz answers
- Interactive question blocks: ONLY for educational/quiz content

FORMATTING:
- Use **bold** and *italic* markdown inside text when it adds clarity
- Use [link text](https://url.com) for references — never bare URLs
- Use emojis ONLY if the prompt suggests an informal or engaging style; omit for professional/academic content
- NEVER set color or background in style properties''';
  }

  String _buildDocumentPrompt(AIGenerationRequest request) {
    final pageCount = request.pageCount ?? 3;
    return '''Create a complete professional multi-page document with $pageCount pages about: ${request.prompt}

${request.context != null ? 'Additional context: ${request.context}' : ''}

${_contentTypeGuidance()}

Respond with a JSON object in this exact format:
{
  "pages": [
    {
      "title": "Page Title",
      "blocks": [
        {
          "type": "block_type_name",
          "content": "JSON content string with real content",
          "position": 0,
          "style": {
            "fontSize": 18,
            "bold": false
          }
        }
      ]
    }
  ]
}

Create well-structured, professional content. Choose block types based on the content category identified above.''';
  }

  String _buildPagePrompt(AIGenerationRequest request) {
    final blockTypes =
        request.preferredBlockTypes?.join(', ') ?? 'any appropriate types';

    // Add context about existing blocks to avoid duplication
    String existingContentNote = '';
    if (request.existingBlocks != null && request.existingBlocks!.isNotEmpty) {
      final existingTypes = request.existingBlocks!
          .map((b) => b.type.displayName)
          .toSet()
          .join(', ');
      existingContentNote =
          '''

IMPORTANT — AVOID DUPLICATION:
This page already has ${request.existingBlocks!.length} blocks of types: $existingTypes
Generate NEW, COMPLEMENTARY content that doesn't duplicate what's already there.
''';
    }

    return '''Create a single professional page with content about: ${request.prompt}

${request.context != null ? 'Additional context: ${request.context}' : ''}
$existingContentNote
Preferred block types: $blockTypes

${_contentTypeGuidance()}

Respond with a JSON object in this exact format:
{
  "title": "Page Title",
  "blocks": [
    {
      "type": "block_type_name",
      "content": "JSON content string with real content",
      "position": 0,
      "style": {
        "fontSize": 18,
        "bold": false
      }
    }
  ]
}

Create professional, well-structured content using block types appropriate to the content category.''';
  }

  String _buildBlockPrompt(AIGenerationRequest request) {
    final blockTypes = request.preferredBlockTypes;
    final typeHint = blockTypes != null && blockTypes.isNotEmpty
        ? 'Create a ${blockTypes.first} block'
        : 'Create an appropriate block';

    // Add context about existing blocks
    String existingContentNote = '';
    if (request.existingBlocks != null && request.existingBlocks!.isNotEmpty) {
      existingContentNote = '''

Note: This page already has ${request.existingBlocks!.length} blocks. Create complementary content that adds value.''';
    }

    return '''$typeHint with content about: ${request.prompt}

${request.context != null ? 'Context: ${request.context}' : ''}$existingContentNote

Choose the MOST APPROPRIATE single block type for this content:
- Quiz or assessment question → multipleChoice, trueFalse, fillInBlank, or matching
- Step-ordering exercise → wordOrder
- To-do or task list → checkbox
- Programming code → code
- Math formula → math
- Structured data (rows/columns) → table
- Plain explanation → paragraph
- List of items → list
- Section title → header
- Callout/tip/note → blockquote

NEVER use checkbox for quiz answers. NEVER use question blocks for non-educational content.
NEVER set color or background in style properties.

Respond with a JSON object in this exact format:
{
  "blocks": [
    {
      "type": "block_type_name",
      "content": "JSON content string",
      "position": 0,
      "style": {
        "fontSize": 18
      }
    }
  ]
}

Create high-quality content with the most appropriate block type for the content.''';
  }

  String _buildEditPrompt(AIGenerationRequest request) {
    final existingBlocksJson = request.existingBlocks
        ?.map(
          (b) => {
            'type': b.type.name,
            'content': b.content,
            'position': b.position,
          },
        )
        .toList();

    return '''Edit the following blocks based on this instruction: ${request.prompt}

Existing blocks:
${jsonEncode(existingBlocksJson)}

${request.context != null ? 'Additional context: ${request.context}' : ''}

Respond with a JSON object containing the edited blocks in this format:
{
  "blocks": [
    {
      "type": "block_type_name",
      "content": "JSON content string",
      "position": 0,
      "style": {
        "fontSize": 18
      }
    }
  ]
}

Preserve the original structure where appropriate while making the requested changes.''';
  }

  String _buildFromDocumentPrompt(AIGenerationRequest request) {
    return '''Analyze the following document and convert it into structured content:

Document content:
${request.documentContent}

User request: ${request.prompt}

${request.context != null ? 'Additional context: ${request.context}' : ''}

${_contentTypeGuidance()}

ADDITIONAL RULES FOR DOCUMENT CONVERSION:
- If the document contains exam/quiz questions: use multipleChoice, trueFalse, fillInBlank, or matching blocks for each question. Use blockquote with quoteType "success" for correct answers and "tip" for explanations.
- If the document is lecture notes or study material: use header, paragraph, list, blockquote, table — no interactive question blocks.
- Number/title each question section clearly using header blocks.
- Do NOT use "checkbox" for quiz answers.

Respond with a JSON object in this format:
{
  "pages": [
    {
      "title": "Page Title",
      "blocks": [...]
    }
  ]
}''';
  }

  String _buildInteractiveNotesPrompt(AIGenerationRequest request) {
    return '''Create professional study notes about: ${request.prompt}

${request.context != null ? 'Additional context: ${request.context}' : ''}

${_contentTypeGuidance()}

STUDY NOTES STRUCTURE — for each concept/section:
1. A header with the section title
2. 1–2 short paragraphs (1–3 sentences each) explaining the concept
3. A blockquote (quoteType "tip" or "note") with the key takeaway
4. A list to summarize key points
5. For educational topics: add interactive blocks where they fit naturally:
   - Language course → matching (word ↔ translation), fillInBlank (vocabulary), multipleChoice
   - Math / Science → math blocks for formulas, multipleChoice or trueFalse for concept checks
   - History / Humanities → multipleChoice or trueFalse for factual checks
   - Literature → expandable for summaries
6. Table blocks for comparisons or structured data (when appropriate)
7. Math blocks for any formulas (never inside paragraph text)
8. Dividers between major sections

Respond with a JSON object in this format:
{
  "pages": [
    {
      "title": "Topic Title",
      "blocks": [
        {"type": "header", "content": "{\\"content\\": \\"Section Title\\"}", "position": 0, "style": {"fontSize": 28, "bold": true}},
        {"type": "paragraph", "content": "{\\"content\\": \\"Explanation with **key terms** highlighted.\\"}", "position": 1, "style": {"fontSize": 16}},
        {"type": "blockquote", "content": "{\\"content\\": \\"Key takeaway here\\", \\"author\\": \\"\\"}", "position": 2, "style": {"quoteType": "tip"}},
        {"type": "list", "content": "{\\"items\\": [\\"Point 1\\", \\"Point 2\\"]}", "position": 3, "style": {"fontSize": 16}}
      ]
    }
  ]
}

Generate comprehensive, well-structured study notes using the block types appropriate for the subject matter.''';
  }

  /// Parse the AI response into structured content
  AIGenerationResult _parseResponse(
    DeepSeekChatResponse response,
    AIGenerationType type,
  ) {
    try {
      final content = response.content.trim();

      // Try to extract JSON from the response
      String jsonContent = content;

      // Handle markdown code blocks with ```json
      if (content.contains('```json')) {
        // Find the start after ```json (including any whitespace/newlines)
        final codeBlockStart = content.indexOf('```json');
        final jsonStart = codeBlockStart + 7;
        // Skip any whitespace/newlines after ```json
        int actualStart = jsonStart;
        while (actualStart < content.length &&
            (content[actualStart] == ' ' ||
                content[actualStart] == '\n' ||
                content[actualStart] == '\r')) {
          actualStart++;
        }

        // Find the closing ```
        final end = content.lastIndexOf('```');
        if (actualStart < content.length && end > actualStart) {
          jsonContent = content.substring(actualStart, end).trim();
        }
      }
      // Handle plain ``` code blocks
      else if (content.contains('```')) {
        final codeBlockStart = content.indexOf('```');
        int actualStart = codeBlockStart + 3;
        // Skip any whitespace/newlines after ```
        while (actualStart < content.length &&
            (content[actualStart] == ' ' ||
                content[actualStart] == '\n' ||
                content[actualStart] == '\r')) {
          actualStart++;
        }

        final end = content.lastIndexOf('```');
        if (actualStart < content.length && end > actualStart) {
          jsonContent = content.substring(actualStart, end).trim();
        }
      }
      // Try to find JSON object directly
      else if (content.contains('{')) {
        final start = content.indexOf('{');
        final end = content.lastIndexOf('}');
        if (start >= 0 && end > start) {
          jsonContent = content.substring(start, end + 1).trim();
        }
      }

      // Log for debugging
      logger.d(
        'Extracted JSON content (first 200 chars): ${jsonContent.length > 200 ? jsonContent.substring(0, 200) : jsonContent}',
      );

      final json = jsonDecode(jsonContent) as Map<String, dynamic>;

      if (type == AIGenerationType.fullDocument ||
          type == AIGenerationType.fromDocument ||
          type == AIGenerationType.interactiveNotes) {
        return _parseDocumentResponse(
          json,
          response.usage.totalTokens,
          content,
        );
      } else if (type == AIGenerationType.page) {
        return _parsePageResponse(json, response.usage.totalTokens, content);
      } else {
        return _parseBlocksResponse(json, response.usage.totalTokens, content);
      }
    } catch (e, stackTrace) {
      logger.e('Failed to parse AI response', error: e, stackTrace: stackTrace);
      // Log the raw content for debugging
      logger.d(
        'Raw response content (first 500 chars): ${response.content.length > 500 ? response.content.substring(0, 500) : response.content}',
      );
      return AIGenerationResult(
        success: false,
        error:
            'Failed to parse AI response. The AI returned an invalid format. Please try again.',
        rawResponse: response.content,
      );
    }
  }

  AIGenerationResult _parseDocumentResponse(
    Map<String, dynamic> json,
    int tokensUsed,
    String rawResponse,
  ) {
    final pagesJson = json['pages'] as List<dynamic>?;
    if (pagesJson == null || pagesJson.isEmpty) {
      return AIGenerationResult.failure('No pages found in response');
    }

    final pages = <AIGeneratedPage>[];
    for (final pageJson in pagesJson) {
      final page = pageJson as Map<String, dynamic>;
      final title = page['title'] as String? ?? 'Untitled Page';
      final blocksJson = page['blocks'] as List<dynamic>? ?? [];

      final blocks = _parseBlocks(blocksJson);
      pages.add(AIGeneratedPage(title: title, blocks: blocks));
    }

    return AIGenerationResult.successWithPages(
      pages,
      tokensUsed: tokensUsed,
      rawResponse: rawResponse,
    );
  }

  AIGenerationResult _parsePageResponse(
    Map<String, dynamic> json,
    int tokensUsed,
    String rawResponse,
  ) {
    final title = json['title'] as String? ?? 'Untitled Page';
    final blocksJson = json['blocks'] as List<dynamic>? ?? [];

    final blocks = _parseBlocks(blocksJson);
    final page = AIGeneratedPage(title: title, blocks: blocks);

    return AIGenerationResult.successWithPages(
      [page],
      tokensUsed: tokensUsed,
      rawResponse: rawResponse,
    );
  }

  AIGenerationResult _parseBlocksResponse(
    Map<String, dynamic> json,
    int tokensUsed,
    String rawResponse,
  ) {
    final blocksJson = json['blocks'] as List<dynamic>? ?? [];
    final blocks = _parseBlocks(blocksJson);

    return AIGenerationResult.successWithBlocks(
      blocks,
      tokensUsed: tokensUsed,
      rawResponse: rawResponse,
    );
  }

  List<Block> _parseBlocks(List<dynamic> blocksJson) {
    final blocks = <Block>[];

    for (int i = 0; i < blocksJson.length; i++) {
      try {
        final blockJson = blocksJson[i] as Map<String, dynamic>;
        final block = _parseBlock(blockJson, i);
        if (block != null) {
          blocks.add(block);
        }
      } catch (e, stackTrace) {
        logger.w(
          'Failed to parse block at index $i',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }

    return blocks;
  }

  Block? _parseBlock(Map<String, dynamic> json, int defaultPosition) {
    try {
      final typeStr = json['type'] as String? ?? 'paragraph';
      final type = BlockTypeExtension.fromJson(typeStr);

      // Get content - ensure it's a JSON string
      dynamic rawContent = json['content'];
      String content;

      if (rawContent is String) {
        // Check if it's already a JSON string
        try {
          jsonDecode(rawContent);
          content = rawContent;
        } catch (_) {
          // It's plain text, wrap it in appropriate JSON
          content = _wrapContentForBlockType(type, rawContent);
        }
      } else if (rawContent is Map) {
        content = jsonEncode(rawContent);
      } else {
        content = _getDefaultContentForBlockType(type);
      }

      final position = (json['position'] as num?)?.toInt() ?? defaultPosition;

      // Parse style
      final styleJson = json['style'] as Map<String, dynamic>? ?? {};
      final style = BlockStyle.fromJson(styleJson);

      return Block(
        content: content,
        position: position,
        type: type,
        style: style,
      );
    } catch (e, stackTrace) {
      logger.e('Failed to parse block', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  String _wrapContentForBlockType(BlockType type, String text) {
    switch (type) {
      case BlockType.header:
      case BlockType.paragraph:
      case BlockType.box:
        return jsonEncode({'content': text});
      case BlockType.blockquote:
        return jsonEncode({'content': text, 'author': ''});
      case BlockType.code:
        return jsonEncode({'content': text});
      case BlockType.list:
        return jsonEncode({
          'items': [text],
        });
      case BlockType.math:
        return jsonEncode({'latex': text, 'caption': ''});
      case BlockType.divider:
        return jsonEncode({'style': 'solid'});
      default:
        return jsonEncode({'content': text});
    }
  }

  String _getDefaultContentForBlockType(BlockType type) {
    switch (type) {
      case BlockType.header:
      case BlockType.paragraph:
      case BlockType.box:
        return jsonEncode({'content': ''});
      case BlockType.blockquote:
        return jsonEncode({'content': '', 'author': ''});
      case BlockType.code:
        return jsonEncode({'content': ''});
      case BlockType.list:
        return jsonEncode({'items': []});
      case BlockType.table:
        return jsonEncode({'header': '', 'rows': []});
      case BlockType.math:
        return jsonEncode({'latex': '', 'caption': ''});
      case BlockType.graph:
        return jsonEncode({
          'type': 'line',
          'expression': '',
          'caption': '',
          'min_x': '-10',
          'max_x': '10',
        });
      case BlockType.checkbox:
        return jsonEncode({'items': []});
      case BlockType.divider:
        return jsonEncode({'style': 'solid'});
      default:
        return jsonEncode({});
    }
  }

  /// Generate a quick summary of content
  Future<String> generateSummary(String content) async {
    try {
      final response = await _apiService.simplePrompt(
        prompt: 'Summarize the following content in 2-3 sentences:\n\n$content',
        systemPrompt:
            'You are a helpful assistant that creates concise, accurate summaries.',
        maxTokens: 256,
        temperature: 0.3,
      );
      return response;
    } catch (e) {
      logger.e('Failed to generate summary', error: e);
      return '';
    }
  }

  /// Maximum blocks to process for improvement suggestions
  static const int _maxBlocksForAnalysis = 50;

  /// Maximum content length per block for analysis
  static const int _maxContentLengthPerBlock = 500;

  /// Suggest improvements for content
  Future<String> suggestImprovements(List<Block> blocks) async {
    try {
      // Limit the number of blocks processed
      final limitedBlocks = blocks.take(_maxBlocksForAnalysis).toList();

      // Truncate content to avoid exceeding API limits
      final blocksDescription = limitedBlocks
          .map((b) {
            final content = b.content.length > _maxContentLengthPerBlock
                ? '${b.content.substring(0, _maxContentLengthPerBlock)}...'
                : b.content;
            return '${b.type.displayName}: $content';
          })
          .join('\n');

      final response = await _apiService.simplePrompt(
        prompt:
            '''Analyze the following document content and suggest 3-5 specific improvements:

$blocksDescription

Provide actionable suggestions for:
1. Content organization
2. Visual appeal (styling)
3. Engagement (adding interactive elements)
4. Completeness''',
        systemPrompt:
            'You are an expert document analyst providing constructive feedback.',
        maxTokens: 512,
        temperature: 0.5,
      );
      return response;
    } catch (e) {
      logger.e('Failed to suggest improvements', error: e);
      return '';
    }
  }

  /// Generate an AI explanation for a question the user answered incorrectly.
  ///
  /// Returns a short, student-focused explanation that helps the student
  /// understand why their answer was wrong and why the correct one makes sense.
  Future<String> generateQuestionExplanation({
    required String question,
    String correctAnswer = '',
    String studentAnswer = '',
    String teacherExplanation = '',
    String questionType = 'question',
  }) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('$questionType question:');
      buffer.writeln(question);
      if (studentAnswer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Student answered: $studentAnswer');
      }
      if (correctAnswer.isNotEmpty) {
        buffer.writeln('Right answer: $correctAnswer');
      }
      if (teacherExplanation.isNotEmpty) {
        buffer.writeln('Context: $teacherExplanation');
      }
      buffer.writeln();
      buffer.writeln(
        'Write 2–3 short sentences to help the student understand:',
      );
      if (studentAnswer.isNotEmpty) {
        buffer.writeln('1. Why their answer is not correct.');
      }
      buffer.writeln(
        '${studentAnswer.isNotEmpty ? "2" : "1"}. Why the right answer makes sense, using the context if provided.',
      );
      buffer.writeln(
        'Keep it under 60 words. Do not mention any teacher or hint source.',
      );

      final response = await _apiService.simplePrompt(
        prompt: buffer.toString(),
        systemPrompt:
            'You are a helpful tutor. Explain concepts clearly and concisely. '
            'Never mention a teacher, hint, or explanation source. '
            'Never say "the correct answer is right". Be warm and direct.',
        maxTokens: 200,
        temperature: 0.4,
      );
      return response;
    } catch (e) {
      logger.e('Failed to generate question explanation', error: e);
      return '';
    }
  }

  /// Dispose resources
  void dispose() {
    _apiService.dispose();
  }
}
