import 'package:barruu/features/workspace/constants/block_type_constants.dart';
import 'package:barruu/features/workspace/constants/block_styles_constants.dart';

/// Comprehensive schema documentation for all block types.
/// This provides the AI with detailed knowledge about block structures.
class BlockSchemaDocumentation {
  BlockSchemaDocumentation._();

  /// Get full documentation for AI context
  static String getFullSchemaDocumentation() {
    return '''
# Barruu Block System Documentation

## Overview
Barruu is a professional knowledge sharing platform that uses a block-based content system. Documents contain pages, and pages contain blocks.
Each block has a type, content (JSON string), position, and style.

## Block Structure
Each block has the following structure:
```json
{
  "id": "string",
  "content": "JSON string with block-specific data",
  "position": number,
  "block_type": "string (one of the block types)",
  "style": {
    // Style properties
  }
}
```

## Block Types and Their Content Formats

### 1. ${BlockTypeConstants.header} (headers)
Content format:
```json
{"content": "Header text here"}
```
Style options:
- headerStyle: "normal", "underline", "dotted", "breakline", "boxed", "gradient"
- fontSize: typically 24-48
- bold: true/false

### 2. ${BlockTypeConstants.paragraph} (paragraphs)
Content format:
```json
{"content": "Paragraph text here"}
```
Style options:
- fontSize: typically 14-20
- bold, italic, underline, strikethrough: true/false
- align: "left", "center", "right"

### 3. ${BlockTypeConstants.blockquote} (blockquotes)
Content format:
```json
{"content": "Quote text here", "author": "Optional author name"}
```
Style options:
- quoteType: "quote", "note", "tip", "warning", "danger", "success", "info"
- authorName: string
- authorAvatar: URL or local path
- borderColor: hex color

### 4. ${BlockTypeConstants.code} (code blocks)
Content format:
```json
{"content": "console.log('Hello World');"}
```
Style options:
- language: "javascript", "python", "dart", "java", "c", "cpp", "go", "rust", "html", "css", "sql", "json", "yaml", "markdown", "text"

### 5. ${BlockTypeConstants.list} (lists)
Content format:
```json
{"items": ["Item 1", "Item 2", "Item 3"]}
```
Style options:
- listType: "bullet", "numbered", "checkbox"
- fontSize, bold, italic as usual

### 6. ${BlockTypeConstants.image} (images)
Content format:
```json
{
  "path": "relative/path/to/image.jpg",
  "caption": "Image caption",
  "cropTop": 0.0,
  "cropBottom": 0.0,
  "fit": "cover",
  "fileName": "original_name.jpg"
}
```
Style options:
- imageSource: "local" or "network"
- width, height: pixels
- widthPercent, heightPercent: 0.0-1.0

### 7. ${BlockTypeConstants.video} (videos)
Content format:
```json
{
  "path": "relative/path/to/video.mp4",
  "caption": "Video caption",
  "fileName": "original_name.mp4"
}
```
Style options:
- videoSource: "local", "network", or "youtube"
- width, height: pixels

### 8. ${BlockTypeConstants.audio} (audio)
Content format:
```json
{
  "path": "relative/path/to/audio.mp3",
  "customTitle": "Custom audio title",
  "caption": "Audio caption",
  "fileName": "original_name.mp3"
}
```

### 9. ${BlockTypeConstants.divider} (dividers)
Content format:
```json
{"style": "solid"}
```
Style options:
- borderStyle: "solid", "dashed", "dotted"
- borderColor: hex color
- borderWidth: number

### 10. ${BlockTypeConstants.table} (tables)
Content format:
```json
{
  "header": "Optional table header",
  "rows": [
    ["Cell 1", "Cell 2", "Cell 3"],
    ["Cell 4", "Cell 5", "Cell 6"]
  ]
}
```
Style options:
- borderColor, fontSize

### 11. ${BlockTypeConstants.box} (box)
Content format:
```json
{"content": "Text inside the box"}
```
Style options:
- borderColor, borderWidth, borderStyle
- gradientColors: list of hex colors for gradient effects

### 12. ${BlockTypeConstants.math} (math)
Content format:
```json
{
  "latex": "\\\\frac{a}{b} = c",
  "caption": "Math equation caption"
}
```

### 13. ${BlockTypeConstants.chat} (chat)
Content format:
```json
{
  "messages": [
    {"role": "user", "content": "Hello"},
    {"role": "assistant", "content": "Hi there!"}
  ]
}
```

### 15. ${BlockTypeConstants.checkbox} (checkbox)
Content format:
```json
{
  "items": [
    {"text": "Task 1", "checked": false},
    {"text": "Task 2", "checked": true}
  ]
}
```

### 16. ${BlockTypeConstants.graph} (graph)
Content format:
```json
{
  "type": "line",
  "expression": "x^2",
  "caption": "Quadratic function",
  "min_x": "-10",
  "max_x": "10",
  "color_scheme": "default"
}
```
Graph types: "line", "parametric", "polar", "bar", "scatter"

### 17. ${BlockTypeConstants.evaluationButton} (evaluation_button)
Content format:
```json
{"label": "Check Answers", "action": "evaluate"}
```

### 18. ${BlockTypeConstants.page} (page)
Content format:
```json
{
  "pageId": "page_2",
  "title": "Chapter 2",
  "description": "Optional description"
}
```
Style options:
- displayStyle: "card", "button", "compact", "minimal"

### 19. ${BlockTypeConstants.wordOrder} (word_order)
**Special Interactive Block**: For sentence/equation construction and reordering exercises
Content format:
```json
{
  "equations": ["x + 2 = 5", "x = 3"],
  "correctOrder": [0, 1],
  "explanation": "First isolate x, then solve",
  "sentence": "The quick brown fox jumps over the lazy dog",
  "words": ["The", "quick", "brown", "fox", "jumps", "over", "the", "lazy", "dog"],
  "correctOrder": [0, 1, 2, 3, 4, 5, 6, 7, 8]
}
```
**Use Cases:**
- Mathematical equation ordering (step-by-step problem solving)
- Sentence construction exercises (language learning, grammar)
- Process/procedure ordering (algorithms, workflows)
- Timeline/chronological ordering (history, events)

**How It Works:**
- User drags and drops equations/words/items to reorder them
- System checks if the order matches correctOrder array
- Provides explanation when complete
- Excellent for teaching logical thinking and sequencing

### 20. ${BlockTypeConstants.cards} (cards)
Content format:
```json
{
  "cards": [
    {
      "title": "Card Title",
      "description": "Card description text",
      "emoji": "📝",
      "imagePath": "path/to/image.jpg",
      "imageType": "local"
    }
  ],
  "cardStyle": "elevated",
  "cardTemplate": "standard"
}
```
Card styles: "elevated" (shadow), "outlined" (border), "filled" (solid background)
Card templates:
- "standard": Vertical layout with image on top (default)
- "horizontal": Image on left, content beside it
- "compact": Minimal, space-efficient design
- "featured": Large, prominent hero-style card
- "overlay": Image background with text overlay on top
- "magazine": Photo with prominent title underneath (editorial style)
- "split": Image taking 60% with content on 40%
- "banner": Wide card with full-width image and centered text overlay

### 22. ${BlockTypeConstants.tabs} (tabs)
Content format:
```json
{
  "tabs": [
    {"title": "Tab 1", "icon": "document", "content": "Content for first tab..."},
    {"title": "Tab 2", "icon": "folder", "content": "Content for second tab..."}
  ],
  "activeTab": 0,
  "tabTemplate": "standard"
}
```
Use tabs to organize related content in a tabbed interface. Each tab can have a title, icon, and markdown content.

### 23. ${BlockTypeConstants.columns} (columns)
Content format:
```json
{
  "columns": [
    {"width": 0.5, "content": "Left column content with markdown support..."},
    {"width": 0.5, "content": "Right column content..."}
  ],
  "gap": 16.0,
  "columnStyle": "elevated",
  "columnTemplate": "standard"
}
```
Column styles: "elevated", "outlined", "filled"
Column templates: "standard", "split", "sidebar"
Use columns for side-by-side content layout. Width is a ratio (0.0-1.0) that should sum to 1.0 for all columns.

### 24. ${BlockTypeConstants.rows} (rows)
Content format:
```json
{
  "rows": [
    {"height": 100.0, "content": "First row content..."},
    {"height": 150.0, "content": "Second row content..."}
  ],
  "gap": 16.0,
  "rowStyle": "elevated",
  "rowTemplate": "standard"
}
```
Row styles: "elevated", "outlined", "filled"
Row templates: "standard", "feature", "hero"
Use rows for stacked horizontal sections with defined heights.

### 25. ${BlockTypeConstants.stepper} (stepper)
Content format:
```json
{
  "steps": [
    {"title": "Step 1", "description": "First step description with details..."},
    {"title": "Step 2", "description": "Second step description..."}
  ],
  "orientation": "vertical",
  "stepperTemplate": "standard"
}
```
Orientation: "vertical" or "horizontal"
Stepper templates: "standard", "numbered", "minimal"
Use stepper for step-by-step instructions, tutorials, or processes.

### 26. ${BlockTypeConstants.expandable} (expandable)
Content format:
```json
{
  "title": "Click to expand",
  "content": "Hidden content that appears when expanded..."
}
```
Use expandable blocks for FAQs, collapsible sections, or content that users can choose to reveal.

## Common Style Properties
All blocks can have these style properties:
- ${BlockStylesConstants.bold}: true/false
- ${BlockStylesConstants.italic}: true/false
- ${BlockStylesConstants.underline}: true/false
- ${BlockStylesConstants.strikethrough}: true/false
- ${BlockStylesConstants.align}: "left", "center", "right"
- ${BlockStylesConstants.fontSize}: number (typically 12-48)
- ${BlockStylesConstants.fontFamily}: string (default: "Times New Roman")
- ${BlockStylesConstants.borderColor}: hex color string (for borders only)
- ${BlockStylesConstants.borderWidth}: number
- ${BlockStylesConstants.borderStyle}: "solid", "dashed", "dotted"
- ${BlockStylesConstants.useAppBackground}: true/false

⚠️ IMPORTANT: DO NOT set ${BlockStylesConstants.color} or ${BlockStylesConstants.background} properties.
The app handles text and background colors automatically for consistent theming and accessibility.

## Document Structure
A document contains:
- meta.json: Document metadata (name, description, tags, cover, author, timestamps)
- pages.json: List of pages with IDs, titles, and order
- page_[id].db: SQLite database for each page containing blocks

## Page Structure
```json
{
  "id": "page_1",
  "title": "Page Title",
  "order": 0,
  "createdAt": "ISO 8601 timestamp",
  "parentPageId": null
}
```

## Generation Guidelines
1. Always use valid JSON for content
2. Position blocks starting from 0 and incrementing
3. Use appropriate block types for the content
4. Apply consistent styling
5. Use headers to organize content hierarchically
6. Use dividers to separate sections
7. Use blockquotes with different quote types for callouts
8. Use question blocks (multipleChoice, trueFalse, fillInBlank, matching) for educational content and assessments

## Question Blocks for Educational Content

### Multiple Choice Questions
Content format:
```json
{
  "questionType": "multipleChoice",
  "question": "What is the capital of France?",
  "options": [
    {"id": "a", "text": "London", "isCorrect": false},
    {"id": "b", "text": "Paris", "isCorrect": true},
    {"id": "c", "text": "Berlin", "isCorrect": false}
  ],
  "allowMultiple": false,
  "shuffleOptions": true,
  "explanation": "Paris is the capital of France.",
  "points": 1,
  "difficulty": "easy"
}
```

### True/False Questions
Content format:
```json
{
  "questionType": "trueFalse",
  "statement": "The Earth orbits around the Sun.",
  "correctAnswer": true,
  "explanation": "The Earth takes approximately 365.25 days to orbit the Sun.",
  "points": 1,
  "difficulty": "easy"
}
```

### Fill-in-the-Blank Questions
Content format:
```json
{
  "questionType": "fillInBlank",
  "template": "The _____ is the largest planet in our solar system.",
  "blanks": [
    {
      "id": "blank_1",
      "position": 0,
      "correctAnswers": ["Jupiter"],
      "caseSensitive": false,
      "acceptTypos": true,
      "maxLevenshteinDistance": 2
    }
  ],
  "explanation": "Jupiter is the largest planet.",
  "points": 1,
  "difficulty": "medium"
}
```

### Matching Questions
Content format:
```json
{
  "questionType": "matching",
  "instruction": "Match each programming language with its use:",
  "leftColumn": [
    {"id": "l1", "text": "Python"},
    {"id": "l2", "text": "JavaScript"}
  ],
  "rightColumn": [
    {"id": "r1", "text": "Web interactivity"},
    {"id": "r2", "text": "Data science"}
  ],
  "correctPairs": [
    {"left": "l1", "right": "r2"},
    {"left": "l2", "right": "r1"}
  ],
  "shuffleItems": true,
  "allowPartialCredit": true,
  "explanation": "Python excels in data science, JavaScript in web development.",
  "points": 2,
  "difficulty": "medium"
}
```
''';
  }

  /// Get a compact schema summary for shorter prompts
  static String getCompactSchemaDescription() {
    return '''
Block types: header ({"content":"text"}), paragraph ({"content":"text"}), 
blockquote ({"content":"text","author":"name"}), code ({"content":"code"}),
list ({"items":["item1","item2"]}), image, video, audio, divider,
table ({"header":"","rows":[["cell1","cell2"]]}), box, 
math ({"latex":"formula","caption":""}),
chat, checkbox ({"items":[{"text":"","checked":bool}]}),
graph ({"type":"line","expression":"x^2","min_x":"-10","max_x":"10"}),
evaluationButton, page, wordOrder,
cards ({"cards":[{"title":"","description":"","emoji":"📝"}],"cardTemplate":"standard"}),
tabs ({"tabs":[{"title":"Tab 1","content":"content..."}],"tabTemplate":"standard"}),
columns ({"columns":[{"width":0.5,"content":"text"}],"columnTemplate":"standard"}),
rows ({"rows":[{"height":100,"content":"text"}],"rowTemplate":"standard"}),
stepper ({"steps":[{"title":"Step 1","description":"details"}],"stepperTemplate":"standard"}),
expandable ({"title":"Click to expand","content":"hidden content"}),
multipleChoice ({"question":"","options":[{"id":"a","text":"","isCorrect":bool}]}),
trueFalse ({"statement":"","correctAnswer":bool}),
fillInBlank ({"template":"The _____ is...","blanks":[{"id":"blank_1","correctAnswers":[""]}]}),
matching ({"leftColumn":[{"id":"l1","text":""}],"rightColumn":[{"id":"r1","text":""}],"correctPairs":[{"left":"l1","right":"r1"}]}).

Style: bold, italic, underline, strikethrough, align, 
fontSize, fontFamily, borderColor, borderWidth, borderStyle.
⚠️ DO NOT use color or background - app handles theming automatically.
''';
  }

  /// Get block-specific schema for a given type
  static String getBlockTypeSchema(String blockType) {
    switch (blockType) {
      case BlockTypeConstants.header:
        return '{"content": "Header text"}';
      case BlockTypeConstants.paragraph:
        return '{"content": "Paragraph text"}';
      case BlockTypeConstants.blockquote:
        return '{"content": "Quote text", "author": "Optional author"}';
      case BlockTypeConstants.code:
        return '{"content": "code here"}';
      case BlockTypeConstants.list:
        return '{"items": ["Item 1", "Item 2"]}';
      case BlockTypeConstants.table:
        return '{"header": "Table header", "rows": [["Cell1", "Cell2"]]}';
      case BlockTypeConstants.math:
        return '{"latex": "\\\\frac{a}{b}", "caption": "Caption"}';
      case BlockTypeConstants.graph:
        return '{"type": "line", "expression": "x^2", "caption": "", "min_x": "-10", "max_x": "10"}';
      case BlockTypeConstants.checkbox:
        return '{"items": [{"text": "Task", "checked": false}]}';
      case BlockTypeConstants.divider:
        return '{"style": "solid"}';
      case BlockTypeConstants.box:
        return '{"content": "Box content"}';
      case BlockTypeConstants.cards:
        return '{"cards": [{"title": "Card Title", "description": "Description", "emoji": "📝", "imagePath": "", "imageType": "local"}], "cardStyle": "elevated", "cardTemplate": "standard"}';
      case BlockTypeConstants.multipleChoice:
        return '{"questionType": "multipleChoice", "question": "What is 2+2?", "options": [{"id": "a", "text": "3", "isCorrect": false}, {"id": "b", "text": "4", "isCorrect": true}], "allowMultiple": false, "explanation": "2+2=4", "points": 1}';
      case BlockTypeConstants.trueFalse:
        return '{"questionType": "trueFalse", "statement": "The Earth is flat.", "correctAnswer": false, "explanation": "The Earth is approximately spherical.", "points": 1}';
      case BlockTypeConstants.fillInBlank:
        return '{"questionType": "fillInBlank", "template": "The _____ is the capital of France.", "blanks": [{"id": "blank_1", "position": 0, "correctAnswers": ["Paris"], "caseSensitive": false, "acceptTypos": true, "maxLevenshteinDistance": 2}], "explanation": "Paris is the capital of France.", "points": 1}';
      case BlockTypeConstants.matching:
        return '{"questionType": "matching", "instruction": "Match items:", "leftColumn": [{"id": "l1", "text": "Item 1"}], "rightColumn": [{"id": "r1", "text": "Match 1"}], "correctPairs": [{"left": "l1", "right": "r1"}], "shuffleItems": true, "allowPartialCredit": true, "explanation": "Explanation here", "points": 1}';
      case BlockTypeConstants.tabs:
        return '{"tabs": [{"title": "Tab 1", "icon": "document", "content": "Content here..."}, {"title": "Tab 2", "icon": "folder", "content": "More content..."}], "activeTab": 0, "tabTemplate": "standard"}';
      case BlockTypeConstants.columns:
        return '{"columns": [{"width": 0.5, "content": "Left column"}, {"width": 0.5, "content": "Right column"}], "gap": 16.0, "columnStyle": "elevated", "columnTemplate": "standard"}';
      case BlockTypeConstants.rows:
        return '{"rows": [{"height": 100.0, "content": "First row"}, {"height": 100.0, "content": "Second row"}], "gap": 16.0, "rowStyle": "elevated", "rowTemplate": "standard"}';
      case BlockTypeConstants.stepper:
        return '{"steps": [{"title": "Step 1", "description": "First step"}, {"title": "Step 2", "description": "Second step"}], "orientation": "vertical", "stepperTemplate": "standard"}';
      case BlockTypeConstants.expandable:
        return '{"title": "Click to expand", "content": "Hidden content goes here"}';
      default:
        return '{}';
    }
  }
}
