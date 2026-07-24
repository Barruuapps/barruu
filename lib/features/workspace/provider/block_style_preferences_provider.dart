import 'package:flutter_riverpod/legacy.dart';

/// Session-based block style preferences (resets when app/page closes)
/// Stores user preferences like whether they prefer bulk import during the current session
class BlockStylePreferences {
  final bool listUseBulkImport;
  final bool checkboxUseBulkImport;
  final bool multipleChoiceUseBulkImport;
  final String? chatProfileName;
  final String? chatAlignment;
  final String? chatLeftProfileName;  // Remember name for left-aligned messages
  final String? chatRightProfileName; // Remember name for right-aligned messages
  // Quiz/Multiple Choice preferences
  final bool? quizAnswerOnce;
  final bool? quizShowFeedbackInstantly;
  final double? quizMarksPerQuestion;
  final String? quizQuestionGroup;

  const BlockStylePreferences({
    this.listUseBulkImport = false,
    this.checkboxUseBulkImport = false,
    this.multipleChoiceUseBulkImport = false,
    this.chatProfileName,
    this.chatAlignment,
    this.chatLeftProfileName,
    this.chatRightProfileName,
    this.quizAnswerOnce,
    this.quizShowFeedbackInstantly,
    this.quizMarksPerQuestion,
    this.quizQuestionGroup,
  });

  BlockStylePreferences copyWith({
    bool? listUseBulkImport,
    bool? checkboxUseBulkImport,
    bool? multipleChoiceUseBulkImport,
    String? chatProfileName,
    String? chatAlignment,
    String? chatLeftProfileName,
    String? chatRightProfileName,
    bool? quizAnswerOnce,
    bool? quizShowFeedbackInstantly,
    double? quizMarksPerQuestion,
    String? quizQuestionGroup,
  }) {
    return BlockStylePreferences(
      listUseBulkImport: listUseBulkImport ?? this.listUseBulkImport,
      checkboxUseBulkImport: checkboxUseBulkImport ?? this.checkboxUseBulkImport,
      multipleChoiceUseBulkImport: multipleChoiceUseBulkImport ?? this.multipleChoiceUseBulkImport,
      chatProfileName: chatProfileName ?? this.chatProfileName,
      chatAlignment: chatAlignment ?? this.chatAlignment,
      chatLeftProfileName: chatLeftProfileName ?? this.chatLeftProfileName,
      chatRightProfileName: chatRightProfileName ?? this.chatRightProfileName,
      quizAnswerOnce: quizAnswerOnce ?? this.quizAnswerOnce,
      quizShowFeedbackInstantly: quizShowFeedbackInstantly ?? this.quizShowFeedbackInstantly,
      quizMarksPerQuestion: quizMarksPerQuestion ?? this.quizMarksPerQuestion,
      quizQuestionGroup: quizQuestionGroup ?? this.quizQuestionGroup,
    );
  }
}

/// State notifier for managing block style preferences during the session
class BlockStylePreferencesNotifier extends StateNotifier<BlockStylePreferences> {
  BlockStylePreferencesNotifier() : super(const BlockStylePreferences());

  void setListBulkImport(bool value) {
    state = state.copyWith(listUseBulkImport: value);
  }

  void setCheckboxBulkImport(bool value) {
    state = state.copyWith(checkboxUseBulkImport: value);
  }

  void setMultipleChoiceBulkImport(bool value) {
    state = state.copyWith(multipleChoiceUseBulkImport: value);
  }

  void setChatProfileName(String name) {
    state = state.copyWith(chatProfileName: name);
  }

  void setChatAlignment(String alignment) {
    state = state.copyWith(chatAlignment: alignment);
  }

  void setChatLeftProfileName(String name) {
    state = state.copyWith(chatLeftProfileName: name);
  }

  void setChatRightProfileName(String name) {
    state = state.copyWith(chatRightProfileName: name);
  }

  void setQuizAnswerOnce(bool value) {
    state = state.copyWith(quizAnswerOnce: value);
  }

  void setQuizShowFeedbackInstantly(bool value) {
    state = state.copyWith(quizShowFeedbackInstantly: value);
  }

  void setQuizMarksPerQuestion(double value) {
    state = state.copyWith(quizMarksPerQuestion: value);
  }

  void setQuizQuestionGroup(String value) {
    state = state.copyWith(quizQuestionGroup: value);
  }
}

/// Provider for block style preferences (session-based, resets on app close)
final blockStylePreferencesProvider =
    StateNotifierProvider<BlockStylePreferencesNotifier, BlockStylePreferences>(
  (ref) => BlockStylePreferencesNotifier(),
);

