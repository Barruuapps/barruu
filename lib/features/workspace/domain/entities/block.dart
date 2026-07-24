import 'dart:convert';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/constants/block_styles_constants.dart';
import 'package:barruu/features/workspace/constants/block_type_constants.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';


class Block {
  final String? id;
  final String content;
  final int position;
  final BlockType type;
  final BlockStyle style;

  Block({
    this.id,
    required this.content,
    required this.position,
    required this.type,
    required this.style,
  });

  Block copyWith({
    String? id,
    String? content,
    int? position,
    BlockType? type,
    BlockStyle? style,
  }) {
    return Block(
      id: id ?? this.id,
      content: content ?? this.content,
      position: position ?? this.position,
      type: type ?? this.type,
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        BlockConstants.idKey: id,
        BlockConstants.contentKey: content,
        BlockConstants.positionKey: position,
        BlockConstants.blockTypeKey: type.toJson(),
        BlockConstants.styleKey: style.toJson(),
      };
    } catch (e, stackTrace) {
      logger.e(
        'Failed to convert Block to JSON: ID $id, content $content',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        BlockConstants.idKey: id,
        BlockConstants.contentKey: content,
        BlockConstants.positionKey: position,
        BlockConstants.blockTypeKey: type.toJson(),
        BlockConstants.styleKey: {},
      };
    }
  }

  factory Block.fromJson(Map<String, dynamic> json) {
    try {
      return Block(
        id: json[BlockConstants.idKey] as String?,
        content: json[BlockConstants.contentKey] as String? ?? '',
        position: (json[BlockConstants.positionKey] as num?)?.toInt() ?? 0,
        type: BlockTypeExtension.fromJson(
          json[BlockConstants.blockTypeKey] as String? ?? 'paragraph',
        ),
        style: BlockStyle.fromJson(
          json[BlockConstants.styleKey] is Map<String, dynamic>
              ? json[BlockConstants.styleKey]
              : {},
        ),
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse Block from JSON: ${json[BlockConstants.idKey]}',
        error: e,
        stackTrace: stackTrace,
      );
      return Block(
        content: '',
        position: 0,
        type: BlockType.paragraph,
        style: const BlockStyle(),
      );
    }
  }

  /// Returns the block_type string to write to the SQLite `block_type` column.
  ///
  /// Uses the canonical display-name format (e.g. `'headers'`, `'paragraphs'`)
  /// so that .bipy files produced by Flutter can be read by the web app and
  /// vice-versa.  For [BlockType.unsupported] blocks the original type string
  /// is preserved from the content JSON so the block survives a round-trip.
  String get serialisedBlockType {
    if (type == BlockType.unsupported) {
      try {
        final contentMap = jsonDecode(content) as Map<String, dynamic>;
        final original = contentMap[BlockTypeConstants.originalBlockTypeKey];
        if (original is String && original.isNotEmpty) return original;
      } catch (_) {}
    }
    return type.displayName;
  }

  Map<String, dynamic> toDatabaseMap() {
    try {
      return {
        'id': id != null ? int.tryParse(id!) : null,
        'content': content,
        'block_type': serialisedBlockType,
        'style': jsonEncode(style.toJson()),
        'position': position,
      };
    } catch (e, stackTrace) {
      logger.e(
        'Failed to convert Block to database map: ID $id',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'content': content,
        'block_type': serialisedBlockType,
        'style': jsonEncode(style.toJson()),
        'position': position,
      };
    }
  }

  factory Block.fromDatabaseMap(Map<String, dynamic> map) {
    try {
      final rawType = map['block_type'] as String? ?? 'paragraph';
      final blockType = BlockTypeExtension.fromJson(rawType);

      // For block types this version does not recognise, embed the original
      // type string inside the content JSON so a future re-export can restore it.
      String resolvedContent = map['content'] as String? ?? '';
      if (blockType == BlockType.unsupported) {
        try {
          final contentMap = jsonDecode(resolvedContent) as Map<String, dynamic>;
          if (!contentMap.containsKey(BlockTypeConstants.originalBlockTypeKey)) {
            contentMap[BlockTypeConstants.originalBlockTypeKey] = rawType;
            resolvedContent = jsonEncode(contentMap);
          }
        } catch (_) {
          resolvedContent = jsonEncode({
            BlockTypeConstants.originalBlockTypeKey: rawType,
            'rawContent': resolvedContent,
          });
        }
      }

      return Block(
        id: map['id']?.toString(),
        content: resolvedContent,
        position: map['position'] as int? ?? 0,
        type: blockType,
        style: BlockStyle.fromJson(_parseStyle(map['style'] as String?)),
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse Block from database map',
        error: e,
        stackTrace: stackTrace,
      );
      return Block(
        content: '',
        position: 0,
        type: BlockType.paragraph,
        style: const BlockStyle(),
      );
    }
  }

  static Map<String, dynamic> _parseStyle(String? styleJson) {
    if (styleJson == null || styleJson.isEmpty) {
      return {};
    }
    try {
      return jsonDecode(styleJson);
    } catch (e, stackTrace) {
      logger.e('Failed to parse style JSON', error: e, stackTrace: stackTrace);
      return {};
    }
  }
}

enum BorderStyle {
  solid,
  dashed,
  dotted,
}

class BlockStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final String align;
  final String? color;
  final String? background;
  final double fontSize;
  final String fontFamily;
  final String? borderColor;
  final String? language;
  final String? listType;
  final String? headerStyle;
  final String? customIcon;
  final double? width;
  final double? height;
  final double? widthPercent;  // Responsive width as percentage (0.0 - 1.0)
  final double? heightPercent; // Responsive height as percentage (0.0 - 1.0)
  final double? rotation;
  final bool useAppBackground;
  final double borderWidth;
  final List<String>? gradientColors;
  final String? borderStyle;
  final String? displayStyle;
  final bool showIcon;
  final String? quoteType;     // For admonitions: quote, note, tip, warning, danger, success, info
  final String? quoteTemplate; // For blockquote template styles: basic, bordered, highlighted, modern, etc.
  final String? authorName;    // For blockquote with author
  final String? authorAvatar;  // For blockquote with avatar (local path or network URL)
  final String? imageSource;   // 'local' or 'network' for image blocks
  final String? videoSource;   // 'local', 'network', or 'youtube' for video blocks
  final String? checkboxTemplate; // For checkbox block template styles
  final String? listTemplate;     // For list block template styles
  final String? tableTemplate;    // For table block template styles
  final String? expandableTemplate; // For expandable block template styles
  final String? paragraphTemplate;  // For paragraph block template styles
  final String? questionTemplate;   // For question block template styles (multiple choice, true/false, fill-in-blank, matching)
  final String? codeTemplate;       // For code block template styles

  const BlockStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.align = 'left',
    this.color,
    this.background,
    this.fontSize = 18.0,
    this.fontFamily = 'Times New Roman',
    this.borderColor,
    this.language,
    this.listType,
    this.headerStyle,
    this.customIcon,
    this.width,
    this.height,
    this.widthPercent,
    this.heightPercent,
    this.rotation,
    this.useAppBackground = true,
    this.borderWidth = 2.0,
    this.gradientColors,
    this.borderStyle,
    this.displayStyle,
    this.showIcon = true,
    this.quoteType,
    this.quoteTemplate,
    this.authorName,
    this.authorAvatar,
    this.imageSource,
    this.videoSource,
    this.checkboxTemplate,
    this.listTemplate,
    this.tableTemplate,
    this.expandableTemplate,
    this.paragraphTemplate,
    this.questionTemplate,
    this.codeTemplate,
  });

  BlockStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    String? align,
    String? color,
    String? background,
    double? fontSize,
    String? fontFamily,
    String? borderColor,
    String? language,
    String? listType,
    String? headerStyle,
    String? customIcon,
    double? width,
    double? height,
    double? widthPercent,
    double? heightPercent,
    double? rotation,
    bool? useAppBackground,
    double? borderWidth,
    List<String>? gradientColors,
    String? borderStyle,
    String? displayStyle,
    bool? showIcon,
    String? quoteType,
    String? quoteTemplate,
    String? authorName,
    String? authorAvatar,
    String? imageSource,
    String? videoSource,
    String? checkboxTemplate,
    String? listTemplate,
    String? tableTemplate,
    String? expandableTemplate,
    String? paragraphTemplate,
    String? questionTemplate,
    String? codeTemplate,
  }) {
    return BlockStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      align: align ?? this.align,
      color: color ?? this.color,
      background: background ?? this.background,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      borderColor: borderColor ?? this.borderColor,
      language: language ?? this.language,
      listType: listType ?? this.listType,
      headerStyle: headerStyle ?? this.headerStyle,
      customIcon: customIcon ?? this.customIcon,
      width: width ?? this.width,
      height: height ?? this.height,
      widthPercent: widthPercent ?? this.widthPercent,
      heightPercent: heightPercent ?? this.heightPercent,
      rotation: rotation ?? this.rotation,
      useAppBackground: useAppBackground ?? this.useAppBackground,
      borderWidth: borderWidth ?? this.borderWidth,
      gradientColors: gradientColors ?? this.gradientColors,
      borderStyle: borderStyle ?? this.borderStyle ?? this.language,
      displayStyle: displayStyle ?? this.displayStyle,
      showIcon: showIcon ?? this.showIcon,
      quoteType: quoteType ?? this.quoteType,
      quoteTemplate: quoteTemplate ?? this.quoteTemplate,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      imageSource: imageSource ?? this.imageSource,
      videoSource: videoSource ?? this.videoSource,
      checkboxTemplate: checkboxTemplate ?? this.checkboxTemplate,
      listTemplate: listTemplate ?? this.listTemplate,
      tableTemplate: tableTemplate ?? this.tableTemplate,
      expandableTemplate: expandableTemplate ?? this.expandableTemplate,
      paragraphTemplate: paragraphTemplate ?? this.paragraphTemplate,
      questionTemplate: questionTemplate ?? this.questionTemplate,
      codeTemplate: codeTemplate ?? this.codeTemplate,
    );
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        BlockStylesConstants.bold: bold,
        BlockStylesConstants.italic: italic,
        BlockStylesConstants.underline: underline,
        BlockStylesConstants.strikethrough: strikethrough,
        BlockStylesConstants.align: align,
        BlockStylesConstants.color: color,
        BlockStylesConstants.background: background,
        BlockStylesConstants.fontSize: fontSize,
        BlockStylesConstants.fontFamily: fontFamily,
        BlockStylesConstants.borderColor: borderColor,
        BlockStylesConstants.language: language,
        BlockStylesConstants.listType: listType,
        BlockStylesConstants.headerStyle: headerStyle,
        BlockStylesConstants.customIcon: customIcon,
        BlockStylesConstants.width: width,
        BlockStylesConstants.height: height,
        BlockStylesConstants.widthPercent: widthPercent,
        BlockStylesConstants.heightPercent: heightPercent,
        BlockStylesConstants.rotation: rotation,
        BlockStylesConstants.useAppBackground: useAppBackground,
        BlockStylesConstants.borderWidth: borderWidth,
        BlockStylesConstants.gradientColors: gradientColors,
        BlockStylesConstants.borderStyle: borderStyle,
        BlockStylesConstants.displayStyle: displayStyle,
        BlockStylesConstants.showIcon: showIcon,
        BlockStylesConstants.quoteType: quoteType,
        BlockStylesConstants.quoteTemplate: quoteTemplate,
        BlockStylesConstants.authorName: authorName,
        BlockStylesConstants.authorAvatar: authorAvatar,
        BlockStylesConstants.imageSource: imageSource,
        BlockStylesConstants.videoSource: videoSource,
        BlockStylesConstants.checkboxTemplate: checkboxTemplate,
        BlockStylesConstants.listTemplate: listTemplate,
        BlockStylesConstants.tableTemplate: tableTemplate,
        BlockStylesConstants.expandableTemplate: expandableTemplate,
        BlockStylesConstants.paragraphTemplate: paragraphTemplate,
        BlockStylesConstants.questionTemplate: questionTemplate,
        BlockStylesConstants.codeTemplate: codeTemplate,
      };
    } catch (e, stackTrace) {
      logger.e(
        'Failed to convert BlockStyle to JSON: fontSize $fontSize, fontFamily $fontFamily',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  factory BlockStyle.fromJson(Map<String, dynamic> json) {
    try {
      return BlockStyle(
        bold: json[BlockStylesConstants.bold] as bool? ?? false,
        italic: json[BlockStylesConstants.italic] as bool? ?? false,
        underline: json[BlockStylesConstants.underline] as bool? ?? false,
        strikethrough: json[BlockStylesConstants.strikethrough] as bool? ?? false,
        align: json[BlockStylesConstants.align] as String? ?? 'left',
        color: json[BlockStylesConstants.color] as String?,
        background: json[BlockStylesConstants.background] as String?,
        fontSize: (json[BlockStylesConstants.fontSize] as num?)?.toDouble() ?? 18.0,
        fontFamily: json[BlockStylesConstants.fontFamily] as String? ?? 'Times New Roman',
        borderColor: json[BlockStylesConstants.borderColor] as String?,
        language: json[BlockStylesConstants.language] as String?,
        listType: json[BlockStylesConstants.listType] as String?,
        headerStyle: json[BlockStylesConstants.headerStyle] as String?,
        customIcon: json[BlockStylesConstants.customIcon] as String?,
        width: (json[BlockStylesConstants.width] as num?)?.toDouble(),
        height: (json[BlockStylesConstants.height] as num?)?.toDouble(),
        widthPercent: (json[BlockStylesConstants.widthPercent] as num?)?.toDouble(),
        heightPercent: (json[BlockStylesConstants.heightPercent] as num?)?.toDouble(),
        rotation: (json[BlockStylesConstants.rotation] as num?)?.toDouble(),
        useAppBackground: json[BlockStylesConstants.useAppBackground] as bool? ?? true,
        borderWidth: (json[BlockStylesConstants.borderWidth] as num?)?.toDouble() ?? 2.0,
        gradientColors: (json[BlockStylesConstants.gradientColors] as List<dynamic>?)?.cast<String>(),
        borderStyle: json[BlockStylesConstants.borderStyle] as String? ?? json[BlockStylesConstants.language] as String?,
        displayStyle: json[BlockStylesConstants.displayStyle] as String?,
        showIcon: json[BlockStylesConstants.showIcon] as bool? ?? true,
        quoteType: json[BlockStylesConstants.quoteType] as String?,
        quoteTemplate: json[BlockStylesConstants.quoteTemplate] as String?,
        authorName: json[BlockStylesConstants.authorName] as String?,
        authorAvatar: json[BlockStylesConstants.authorAvatar] as String?,
        imageSource: json[BlockStylesConstants.imageSource] as String?,
        videoSource: json[BlockStylesConstants.videoSource] as String?,
        checkboxTemplate: json[BlockStylesConstants.checkboxTemplate] as String?,
        listTemplate: json[BlockStylesConstants.listTemplate] as String?,
        tableTemplate: json[BlockStylesConstants.tableTemplate] as String?,
        expandableTemplate: json[BlockStylesConstants.expandableTemplate] as String?,
        paragraphTemplate: json[BlockStylesConstants.paragraphTemplate] as String?,
        questionTemplate: json[BlockStylesConstants.questionTemplate] as String?,
        codeTemplate: json[BlockStylesConstants.codeTemplate] as String?,
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse BlockStyle from JSON: ${json[BlockStylesConstants.fontFamily]}',
        error: e,
        stackTrace: stackTrace,
      );
      return const BlockStyle();
    }
  }
}