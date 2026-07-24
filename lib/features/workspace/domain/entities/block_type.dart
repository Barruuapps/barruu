import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/constants/block_type_constants.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

enum BlockType {
  header,
  paragraph,
  blockquote,
  code,
  list,
  image,
  video,
  audio,
  divider,
  spacer,
  table,
  box,
  math,
  chat,
  checkbox,
  graph,
  evaluationButton,
  page,
  wordOrder,
  mathWorkpad,
  tabs,
  cards,
  expandable,
  stepper,
  columns,
  rows,
  multipleChoice,
  trueFalse,
  fillInBlank,
  matching,
  theorem,
  proof,
  definition,
  example,
  learningObjective,
  conceptSummary,
  numericalQuestion,
  glossary,
  parametricGraph,
  citation,
  toc,
  faq,
  keyPoint,

  /// Placeholder for block types introduced in newer app versions (e.g. web).
  /// The original type string is preserved in the block content JSON under the
  /// key "originalBlockType" so it survives a round-trip export without data
  /// loss.
  unsupported,
}

extension BlockTypeExtension on BlockType {
  String get displayName {
    switch (this) {
      case BlockType.header:
        return BlockTypeConstants.header;
      case BlockType.paragraph:
        return BlockTypeConstants.paragraph;
      case BlockType.blockquote:
        return BlockTypeConstants.blockquote;
      case BlockType.code:
        return BlockTypeConstants.code;
      case BlockType.list:
        return BlockTypeConstants.list;
      case BlockType.image:
        return BlockTypeConstants.image;
      case BlockType.video:
        return BlockTypeConstants.video;
      case BlockType.audio:
        return BlockTypeConstants.audio;
      case BlockType.divider:
        return BlockTypeConstants.divider;
      case BlockType.spacer:
        return BlockTypeConstants.spacer;
      case BlockType.table:
        return BlockTypeConstants.table;
      case BlockType.box:
        return BlockTypeConstants.box;
      case BlockType.math:
        return BlockTypeConstants.math;
      case BlockType.chat:
        return BlockTypeConstants.chat;
      case BlockType.checkbox:
        return BlockTypeConstants.checkbox;
      case BlockType.graph:
        return BlockTypeConstants.graph;
      case BlockType.evaluationButton:
        return BlockTypeConstants.evaluationButton;
      case BlockType.page:
        return BlockTypeConstants.page;
      case BlockType.wordOrder:
        return BlockTypeConstants.wordOrder;
      case BlockType.mathWorkpad:
        return BlockTypeConstants.mathWorkpad;
      case BlockType.tabs:
        return BlockTypeConstants.tabs;
      case BlockType.cards:
        return BlockTypeConstants.cards;
      case BlockType.expandable:
        return BlockTypeConstants.expandable;
      case BlockType.stepper:
        return BlockTypeConstants.stepper;
      case BlockType.columns:
        return BlockTypeConstants.columns;
      case BlockType.rows:
        return BlockTypeConstants.rows;
      case BlockType.multipleChoice:
        return BlockTypeConstants.multipleChoice;
      case BlockType.trueFalse:
        return BlockTypeConstants.trueFalse;
      case BlockType.fillInBlank:
        return BlockTypeConstants.fillInBlank;
      case BlockType.matching:
        return BlockTypeConstants.matching;
      case BlockType.theorem:
        return BlockTypeConstants.theorem;
      case BlockType.proof:
        return BlockTypeConstants.proof;
      case BlockType.definition:
        return BlockTypeConstants.definition;
      case BlockType.example:
        return BlockTypeConstants.example;
      case BlockType.learningObjective:
        return BlockTypeConstants.learningObjective;
      case BlockType.conceptSummary:
        return BlockTypeConstants.conceptSummary;
      case BlockType.numericalQuestion:
        return BlockTypeConstants.numericalQuestion;
      case BlockType.glossary:
        return BlockTypeConstants.glossary;
      case BlockType.parametricGraph:
        return BlockTypeConstants.parametricGraph;
      case BlockType.citation:
        return BlockTypeConstants.citation;
      case BlockType.toc:
        return BlockTypeConstants.toc;
      case BlockType.faq:
        return BlockTypeConstants.faq;
      case BlockType.keyPoint:
        return BlockTypeConstants.keyPoint;
      case BlockType.unsupported:
        return BlockTypeConstants.unsupported;
    }
  }

  /// Returns the icon for this block type.
  ///
  /// Uses a hybrid approach for optimal user experience:
  /// - IconsaxPlusBold: Modern, consistent icons for most block types
  /// - Material Icons: Used for specific cases where Material Icons provide
  ///   better semantic clarity and universal recognition (quotes, tables)
  IconData get icon {
    switch (this) {
      case BlockType.header:
        return IconsaxPlusBold.text;
      case BlockType.paragraph:
        return IconsaxPlusBold.document_text;
      case BlockType.blockquote:
        return Icons.format_quote; // Material Icons for universal recognition
      case BlockType.code:
        return IconsaxPlusBold.code;
      case BlockType.list:
        return IconsaxPlusBold.task;
      case BlockType.image:
        return IconsaxPlusBold.image;
      case BlockType.video:
        return IconsaxPlusBold.video;
      case BlockType.audio:
        return IconsaxPlusBold.music;
      case BlockType.divider:
        return IconsaxPlusBold
            .minus_cirlce; // Note: 'cirlce' typo exists in the iconsax_plus package itself
      case BlockType.spacer:
        return IconsaxPlusBold.maximize_4;
      case BlockType.table:
        return Icons
            .table_chart; // Material Icons for clear table representation
      case BlockType.box:
        return IconsaxPlusBold.box;
      case BlockType.math:
        return IconsaxPlusBold.math;
      case BlockType.chat:
        return IconsaxPlusBold.message;
      case BlockType.checkbox:
        return IconsaxPlusBold.tick_square;
      case BlockType.graph:
        return IconsaxPlusBold.chart;
      case BlockType.evaluationButton:
        return IconsaxPlusBold.calculator;
      case BlockType.page:
        return IconsaxPlusBold.document_text;
      case BlockType.wordOrder:
        return IconsaxPlusBold.math;
      case BlockType.mathWorkpad:
        return IconsaxPlusBold.calculator;
      case BlockType.tabs:
        return IconsaxPlusBold.task_square;
      case BlockType.cards:
        return IconsaxPlusBold.card;
      case BlockType.expandable:
        return IconsaxPlusBold.arrow_down_1;
      case BlockType.stepper:
        return IconsaxPlusBold.document_forward;
      case BlockType.columns:
        return IconsaxPlusBold.row_vertical;
      case BlockType.rows:
        return IconsaxPlusBold.row_horizontal;
      case BlockType.multipleChoice:
        return IconsaxPlusBold.task_square;
      case BlockType.trueFalse:
        return IconsaxPlusBold.tick_circle;
      case BlockType.fillInBlank:
        return IconsaxPlusBold.edit;
      case BlockType.matching:
        return IconsaxPlusBold.link_21;
      case BlockType.theorem:
        return Icons.menu_book_rounded;
      case BlockType.proof:
        return Icons.rule_folder_rounded;
      case BlockType.definition:
        return Icons.book_rounded;
      case BlockType.example:
        return Icons.lightbulb_outline_rounded;
      case BlockType.learningObjective:
        return Icons.flag_rounded;
      case BlockType.conceptSummary:
        return Icons.summarize_rounded;
      case BlockType.numericalQuestion:
        return Icons.pin_rounded;
      case BlockType.glossary:
        return Icons.auto_stories_rounded;
      case BlockType.parametricGraph:
        return Icons.show_chart_rounded;
      case BlockType.citation:
        return Icons.format_quote_rounded;
      case BlockType.toc:
        return Icons.list_alt_rounded;
      case BlockType.faq:
        return Icons.help_center_rounded;
      case BlockType.keyPoint:
        return Icons.key_rounded;
      case BlockType.unsupported:
        return Icons.block;
    }
  }

  /// Serialises the block type to its JSON string.
  ///
  /// For [BlockType.unsupported] blocks the original type string is stored
  /// inside the content JSON under [BlockTypeConstants.originalBlockTypeKey];
  /// this getter therefore returns the Dart name "unsupported" only for blocks
  /// that were genuinely unsupported — the Block.toDatabaseMap / toJson callers
  /// are responsible for writing the originalBlockType key from the content.
  String toJson() => name;

  static BlockType fromJson(String json) {
    try {
      // Legacy aliases
      if (json == 'mathEquationOrder' || json == 'reorder') {
        return BlockType.wordOrder;
      }
      // Try displayName first — this is the canonical .bipy format used by
      // the web app (e.g. 'headers', 'paragraphs', 'code blocks').
      for (final type in BlockType.values) {
        if (type != BlockType.unsupported && type.displayName == json) {
          return type;
        }
      }
      // Fall back to Dart enum name for blocks written by older Flutter builds
      // (e.g. 'header', 'paragraph') before the canonical format was adopted.
      for (final type in BlockType.values) {
        if (type != BlockType.unsupported && type.name == json) {
          return type;
        }
      }
      logger.w(
        'Unknown block type: "$json" — stored as unsupported, original type preserved',
      );
      return BlockType.unsupported;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to parse block type: $json',
        error: e,
        stackTrace: stackTrace,
      );
      return BlockType.unsupported;
    }
  }
}
