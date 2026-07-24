class BlockStylesConstants {
  static const String bold = 'bold';
  static const String italic = 'italic';
  static const String underline = 'underline';
  static const String strikethrough = 'strikethrough';
  static const String align = 'align';
  static const String color = 'color';
  static const String background = 'background';
  static const String borderColor = 'borderColor';
  static const String fontSize = 'fontSize';
  static const String fontFamily = 'fontFamily';
  static const String language = 'language';
  static const String listType = 'listType';
  static const String headerStyle = 'headerStyle';
  static const String customIcon = 'customIcon';
  static const String width = 'width';
  static const String height = 'height';
  static const String widthPercent = 'widthPercent';
  static const String heightPercent = 'heightPercent';
  static const String rotation = 'rotation';
  static const String useAppBackground = 'useAppBackground';
  static const String borderWidth = 'borderWidth';
  static const String gradientColors = 'gradientColors';
  static const String borderStyle = 'borderStyle';
  static const String displayStyle = 'displayStyle';
  static const String showIcon = 'showIcon';
  static const String quoteType = 'quoteType';
  static const String quoteTemplate = 'quoteTemplate';
  static const String authorName = 'authorName';
  static const String authorAvatar = 'authorAvatar';
  static const String imageSource = 'imageSource';
  static const String videoSource = 'videoSource';
  static const String checkboxTemplate = 'checkboxTemplate';
  static const String listTemplate = 'listTemplate';
  static const String tableTemplate = 'tableTemplate';
  static const String expandableTemplate = 'expandableTemplate';
  static const String expandableStyle = 'expandableStyle';
  static const String paragraphTemplate = 'paragraphTemplate';
  static const String questionTemplate = 'questionTemplate';
  static const String codeTemplate = 'codeTemplate';

  /// Header template types for header blocks
  static const List<String> headerStyleValues = [
    'normal',
    'underline',
    'dotted',
    'breakline',
    'boxed',
    'dotted_box',
    'gradient',
    'featured',
    'modern',
    'hero',
    'minimal',
    'accent',
    'badge',
    'ribbon',
    'callout',
  ];

  static const List<String> pageDisplayStyleValues = [
    'card', // Default card style with gradient
    'button', // Button-like appearance
    'compact', // Minimal compact style
    'minimal', // Text-only minimal style
    'banner', // Full-width banner
    'sidebar', // Left-border accent
    'floating', // Elevated card with shadow
    'gradient', // Full gradient background
    'outlined', // Border-only, transparent bg
    'hero', // Large icon, prominent title
  ];

  /// Quote/admonition types for blockquote blocks
  static const List<String> quoteTypeValues = [
    'quote', // Default quote style
    'note', // Information note
    'tip', // Helpful tip
    'warning', // Warning message
    'danger', // Danger/error message
    'success', // Success message
    'info', // General information
  ];

  /// Blockquote template types for blockquote blocks
  static const List<String> quoteTemplateValues = [
    'basic', // Simple quote with left border
    'bordered', // Fully bordered quote box
    'highlighted', // Quote with gradient background
    'modern', // Modern design with accent bar
    'testimonial', // Testimonial style with avatar space
    'callout', // Callout box style with icon
    'sidebar', // Sidebar style with thick left border
    'featured', // Featured quote with gradient and bold styling
    'card', // Card-style elevated quote
  ];

  /// Card template types for cards blocks
  static const List<String> cardTemplateValues = [
    'standard', // Vertical layout with image on top (default)
    'horizontal', // Image on left, content beside it
    'compact', // Minimal, space-efficient design
    'featured', // Large, prominent hero-style card
    'overlay', // Image background with text overlay
    'magazine', // Photo with prominent title underneath
    'split', // Image taking 60% with content on 40%
    'banner', // Wide card with full-width image and text overlay
  ];

  /// Card style types for cards blocks
  static const List<String> cardStyleValues = [
    'elevated', // Card with shadow
    'outlined', // Card with border
    'filled', // Card with solid background
  ];

  /// Checkbox template types for checkbox blocks
  static const List<String> checkboxTemplateValues = [
    'default', // Standard checkbox list
    'card', // Each item in a card container
    'minimal', // Clean minimal style
    'outlined', // Items with outlined borders
    'modern', // Modern with accent colors
    'gradient', // Gradient background container
    'progress', // Shows completion progress bar
    'priority', // Color-coded by item priority/position
    'split', // Completed items grouped below pending
    'compact', // Tight spacing, dense layout
  ];

  /// List template types for list blocks
  static const List<String> listTemplateValues = [
    'default', // Standard list
    'card', // Card container with items
    'minimal', // Clean minimal list
    'outlined', // Outlined container
    'gradient', // Gradient background
    'modern', // Modern with accent colors
    'timeline', // Vertical timeline with connecting dots
    'numbered_card', // Numbered circle badges per item
    'badge', // Pill/badge style per item
    'priority', // Color-coded left borders by position
  ];

  /// Table template types for table blocks
  static const List<String> tableTemplateValues = [
    'default', // Standard table with borders
    'striped', // Alternating row colors
    'minimal', // Minimal borders
    'bordered', // Full thick borders
    'modern', // Modern with colored header
    'card', // Card-like elevated table
  ];

  /// Expandable template types for expandable blocks
  static const List<String> expandableTemplateValues = [
    'default', // Standard expandable with border
    'filled', // Solid background color
    'minimal', // Clean minimal with just a divider
    'card', // Elevated card style with shadow
    'outlined', // Border-only, transparent background
    'accent', // Left accent border highlight
  ];

  /// Expandable icon-indicator style variants
  static const List<String> expandableStyleValues = [
    'arrow', // Filled right-pointing arrow (default)
    'plus', // Plus/minus toggle
    'chevron', // Chevron pointing right
    'caret', // Caret pointing down
  ];

  /// Paragraph template types for paragraph blocks
  static const List<String> paragraphTemplateValues = [
    'default', // Standard paragraph
    'drop_cap', // Large first letter spanning two lines
    'image_left', // Image on the left with text beside it (same row height)
    'image_right', // Image on the right with text beside it (same row height)
    'image_float_left', // Image top-left, text flows beside AND below (float-style)
    'image_float_right', // Image top-right, text flows beside AND below (float-style)
    'zigzag', // Decorative zigzag border
    'note', // Note/info box with accent icon
    'warning', // Warning box with amber accent
    'success', // Success/tip box with green accent
    'highlight', // Highlighted background paragraph
    'pull_quote', // Pull-quote style with large quotation marks
    'quote_card', // Elevated card quote with shadow
    'centered', // Centered text with decorative ornamental lines
  ];

  /// Multiple choice question template types
  static const List<String> multipleChoiceTemplateValues = [
    'default', // Standard vertical list with radio/checkbox
    'card', // Each option in elevated card with letter badge
    'grid', // 2-column grid layout
    'minimal', // Clean minimal with divider separators
    'pill', // Rounded pill-shaped option buttons
    'numbered', // Large numbered circle badges (1, 2, 3...) per option
    'highlight', // Full-row colored background when selected (Kahoot-style)
  ];

  /// True/False question template types
  static const List<String> trueFalseTemplateValues = [
    'default', // Standard horizontal True/False buttons
    'card', // Large prominent cards with icons
    'banner', // Full-width stacked banner buttons
    'minimal', // Simple text with dot indicator
    'toggle', // Segmented control / toggle bar
    'spotlight', // Selected choice glows, other fades
  ];

  /// Fill-in-blank question template types
  static const List<String> fillBlankTemplateValues = [
    'default', // Inline blanks embedded in flowing text
    'card', // Card container around sentence
    'exam', // Exam-style with numbered blank list below
    'boxed_blank', // Blanks shown with visible box outline
    'highlighted_blank', // Blanks with colored highlight background
  ];

  /// Matching question template types
  static const List<String> matchingTemplateValues = [
    'default', // Two-column tap-to-match layout
    'card', // Card-style items in each column
    'compact', // Compact tighter layout
    'numbered', // Left items with number badges, right with letter badges
    'list', // List-style items with colored left border accent
  ];

  /// Reorder / math equation order question template types
  static const List<String> reorderTemplateValues = [
    'default', // Standard minimal word pills with light border
    'card', // Elevated card-style chips with shadow
    'bubble', // Rounded bubble/pill chips with tinted background
    'tile', // Solid rectangular tiles with bold border
    'numbered', // Numbered position badges for math steps ordering
    'minimal', // Plain inline text — no box or border around each word
    'highlight', // Marker-highlight style — colored background, no border
  ];

  /// Code block template types
  static const List<String> codeTemplateValues = [
    'minimal', // Clean, no header bar — default
    'default', // Header bar with language label and copy button, subtle border
    'card', // Elevated card with shadow and accent header
    'terminal', // macOS-style terminal with colored traffic-light dots
    'github', // GitHub-inspired grey header with code badge
    'bordered', // Thick primary-color left-border accent style
    'dracula', // Dark purple Dracula-inspired theme
    'monokai', // Warm dark Monokai-inspired theme
    'vscode', // VS Code dark editor tab-style theme
  ];
}
