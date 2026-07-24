class BlockTypeConstants {
  static const String header = 'headers';
  static const String paragraph = 'paragraphs';
  static const String blockquote = 'blockquotes';
  static const String code = 'code blocks';
  static const String list = 'lists';
  static const String image = 'images';
  static const String video = 'videos';
  static const String audio = 'audio';
  static const String divider = 'dividers';
  static const String spacer = 'spacer';
  static const String table = 'tables';
  static const String box = 'box';
  static const String math = 'math';
  static const String chat = 'chat';
  static const String checkbox = 'checkbox';
  static const String graph = 'graph';
  static const String evaluationButton = 'evaluation_button';
  static const String page = 'page';
  static const String wordOrder = 'wordOrder';
  static const String mathWorkpad = 'mathWorkpad';

  /// Internal sentinel used to represent block types this version of the app
  /// does not recognise (e.g. STEM blocks added in the web app).
  /// The original block_type string is stored inside the content JSON so the
  /// block can be round-tripped through export/import without data loss.
  static const String unsupported = 'unsupported';

  /// Key inside the content JSON where the original block type string is kept
  /// for [unsupported] blocks.
  static const String originalBlockTypeKey = 'originalBlockType';
  static const String tabs = 'tabs';
  static const String cards = 'cards';
  static const String expandable = 'expandable';
  static const String stepper = 'stepper';
  static const String columns = 'columns';
  static const String rows = 'rows';
  static const String multipleChoice = 'multiple_choice';
  static const String trueFalse = 'true_false';
  static const String fillInBlank = 'fill_in_blank';
  static const String matching = 'matching';
  static const String theorem = 'theorem';
  static const String proof = 'proof';
  static const String definition = 'definition';
  static const String example = 'example';
  static const String learningObjective = 'learningObjective';
  static const String conceptSummary = 'conceptSummary';
  static const String numericalQuestion = 'numericalQuestion';
  static const String glossary = 'glossary';
  static const String parametricGraph = 'parametricGraph';
  static const String citation = 'citation';
  static const String toc = 'toc';
  static const String faq = 'faq';
  static const String keyPoint = 'keyPoint';
}
