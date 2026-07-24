import 'package:barruu/core/utils/app_logger.dart';

/// Service for validating question answers
class AnswerValidationService {
  /// Try to parse [expr] as an arithmetic expression and return its value.
  ///
  /// Supports integers, decimals, +, -, *, /, parentheses, and unary minus.
  /// Returns `null` when the string is not a valid expression.
  double? _tryEvaluateMath(String expr) {
    try {
      final result = _MathParser(expr).parse();
      return result.isFinite ? result : null;
    } catch (_) {
      return null;
    }
  }

  // Validation thresholds
  static const double multipleChoicePassingScore = 0.7; // 70% correct selections required
  static const double matchingPassingScore = 0.6; // 60% correct matches required
  static const double rearrangementPassingScore = 0.7; // 70% items in correct position
  
  /// Validate multiple choice answer
  ValidationResult validateMultipleChoice({
    required List<String> userAnswers,
    required List<Map<String, dynamic>> options,
    required bool allowMultiple,
  }) {
    try {
      final correctIds = options
          .where((opt) => opt['isCorrect'] == true)
          .map((opt) => opt['id'] as String)
          .toSet();
      
      final userSet = userAnswers.toSet();
      
      if (allowMultiple) {
        final correctSelections = userSet.intersection(correctIds).length;
        final wrongSelections = userSet.difference(correctIds).length;
        final totalCorrect = correctIds.length;
        
        if (correctSelections == 0) {
          return ValidationResult(
            isCorrect: false,
            score: 0.0,
            feedback: 'No correct options selected.',
          );
        }
        
        final score = ((correctSelections - wrongSelections) / totalCorrect)
            .clamp(0.0, 1.0);
        
        return ValidationResult(
          isCorrect: score >= multipleChoicePassingScore,
          score: score,
          feedback: score >= multipleChoicePassingScore
              ? 'Good job! You selected $correctSelections out of $totalCorrect correct options.'
              : 'Not quite. You have some incorrect selections.',
        );
      } else {
        final isCorrect = userSet.length == 1 && 
                         correctIds.contains(userAnswers.first);
        
        return ValidationResult(
          isCorrect: isCorrect,
          score: isCorrect ? 1.0 : 0.0,
          feedback: isCorrect ? 'Correct!' : 'Incorrect. Try again.',
        );
      }
    } catch (e, stackTrace) {
      logger.e('Error validating multiple choice', error: e, stackTrace: stackTrace);
      return ValidationResult(
        isCorrect: false,
        score: 0.0,
        feedback: 'Error validating answer.',
      );
    }
  }
  
  /// Validate true/false answer
  ValidationResult validateTrueFalse({
    required bool userAnswer,
    required bool correctAnswer,
  }) {
    final isCorrect = userAnswer == correctAnswer;
    return ValidationResult(
      isCorrect: isCorrect,
      score: isCorrect ? 1.0 : 0.0,
      feedback: isCorrect ? 'Correct!' : 'Incorrect.',
    );
  }
  
  /// Validate fill-in-blank answer
  ValidationResult validateFillInBlank({
    required Map<String, String> userAnswers,
    required List<Map<String, dynamic>> blanks,
  }) {
    try {
      int correctCount = 0;
      final totalBlanks = blanks.length;
      final Map<String, bool> blankResults = {};
      
      for (final blank in blanks) {
        final blankId = blank['id'] as String;
        final userAnswer = userAnswers[blankId]?.trim() ?? '';
        final correctAnswers = (blank['correctAnswers'] as List)
            .map((e) => e.toString())
            .toList();
        final caseSensitive = blank['caseSensitive'] as bool? ?? false;
        final acceptTypos = blank['acceptTypos'] as bool? ?? false;
        final maxDistance = blank['maxLevenshteinDistance'] as int? ?? 2;
        
        bool isBlankCorrect = false;
        
        for (final correctAnswer in correctAnswers) {
          final target = caseSensitive 
              ? correctAnswer 
              : correctAnswer.toLowerCase();
          final answer = caseSensitive 
              ? userAnswer 
              : userAnswer.toLowerCase();
          
          if (acceptTypos) {
            final distance = _levenshteinDistance(answer, target);
            if (distance <= maxDistance) {
              isBlankCorrect = true;
              break;
            }
          } else {
            if (answer == target) {
              isBlankCorrect = true;
              break;
            }
          }
        }

        // If string comparison failed, try evaluating both sides as arithmetic
        // expressions so that equivalent forms such as "1+2+1" and "4" are
        // treated as the same answer.
        if (!isBlankCorrect) {
          final userVal = _tryEvaluateMath(userAnswer);
          if (userVal != null) {
            for (final correctAnswer in correctAnswers) {
              final correctVal = _tryEvaluateMath(correctAnswer);
              if (correctVal != null && (userVal - correctVal).abs() < 1e-9) {
                isBlankCorrect = true;
                break;
              }
            }
          }
        }
        
        blankResults[blankId] = isBlankCorrect;
        if (isBlankCorrect) correctCount++;
      }
      
      final score = correctCount / totalBlanks;
      final isCorrect = correctCount == totalBlanks;
      
      return ValidationResult(
        isCorrect: isCorrect,
        score: score,
        feedback: isCorrect
            ? 'Perfect! All blanks filled correctly.'
            : 'You got $correctCount out of $totalBlanks correct.',
        detailedFeedback: blankResults,
      );
    } catch (e, stackTrace) {
      logger.e('Error validating fill in blank', error: e, stackTrace: stackTrace);
      return ValidationResult(
        isCorrect: false,
        score: 0.0,
        feedback: 'Error validating answer.',
      );
    }
  }
  
  /// Returns the text of a right-column item by its ID, or null if not found.
  ///
  /// [rightColumn] is the list of right-column items, each expected to be a
  /// map with at least `'id'` (String) and `'text'` (String) keys.
  /// [rightId] is the ID of the item whose text should be retrieved.
  String? _getRightTextById(
      List<Map<String, dynamic>> rightColumn, String rightId) {
    for (final item in rightColumn) {
      if (item['id'] == rightId) return item['text'] as String?;
    }
    return null;
  }

  /// Returns true when two right-column text values are semantically equivalent.
  ///
  /// The check is two-phase:
  /// 1. **String phase** – trims whitespace and compares case-insensitively.
  ///    "Apple" and "apple" are considered equal.
  /// 2. **Math phase** – if the string phase fails, both values are evaluated
  ///    as arithmetic expressions. "2+1" and "3" resolve to the same number and
  ///    are therefore considered equivalent.
  ///
  /// Returns false when the values differ in both phases, or when only one of
  /// them can be evaluated as a math expression.
  bool _rightTextsEquivalent(String a, String b) {
    final aNorm = a.trim().toLowerCase();
    final bNorm = b.trim().toLowerCase();
    if (aNorm == bNorm) return true;
    // Try arithmetic equivalence (e.g. "2+1" == "3").
    final aVal = _tryEvaluateMath(a.trim());
    final bVal = _tryEvaluateMath(b.trim());
    if (aVal != null && bVal != null) {
      return (aVal - bVal).abs() < 1e-9;
    }
    return false;
  }

  /// Validate matching answer.
  ///
  /// When [rightColumn] is provided the validator also accepts a user pairing
  /// whose selected right item has text (or a mathematically equivalent value)
  /// identical to the correct right item, even if the IDs differ. This handles
  /// the common case where the right column intentionally contains duplicate
  /// text values (e.g. multiple rows whose answer is "3").
  ValidationResult validateMatching({
    required Map<String, String> userPairs,
    required List<Map<String, dynamic>> correctPairs,
    required bool allowPartialCredit,
    List<Map<String, dynamic>>? rightColumn,
  }) {
    try {
      int correctMatches = 0;
      final Map<String, bool> pairResults = {};
      
      for (final pair in correctPairs) {
        final leftId = pair['left'] as String;
        final rightId = pair['right'] as String;
        bool isCorrect = userPairs[leftId] == rightId;

        // When the IDs don't match but right column text is provided, check
        // whether the user's selected right item is textually / mathematically
        // equivalent to the correct right item.
        if (!isCorrect && rightColumn != null && userPairs[leftId] != null) {
          final userText =
              _getRightTextById(rightColumn, userPairs[leftId]!) ?? '';
          final correctText = _getRightTextById(rightColumn, rightId) ?? '';
          if (userText.isNotEmpty &&
              correctText.isNotEmpty &&
              _rightTextsEquivalent(userText, correctText)) {
            isCorrect = true;
          }
        }

        pairResults[leftId] = isCorrect;
        if (isCorrect) correctMatches++;
      }
      
      final totalPairs = correctPairs.length;
      final score = correctMatches / totalPairs;
      
      if (allowPartialCredit) {
        return ValidationResult(
          isCorrect: score >= matchingPassingScore,
          score: score,
          feedback: 'You matched $correctMatches out of $totalPairs pairs correctly.',
          detailedFeedback: pairResults,
        );
      } else {
        final isCorrect = correctMatches == totalPairs;
        return ValidationResult(
          isCorrect: isCorrect,
          score: isCorrect ? 1.0 : 0.0,
          feedback: isCorrect 
              ? 'Perfect! All pairs matched correctly.' 
              : 'Not all pairs are correct. Try again.',
          detailedFeedback: pairResults,
        );
      }
    } catch (e, stackTrace) {
      logger.e('Error validating matching', error: e, stackTrace: stackTrace);
      return ValidationResult(
        isCorrect: false,
        score: 0.0,
        feedback: 'Error validating answer.',
      );
    }
  }
  
  /// Validate rearrangement answer
  ValidationResult validateRearrangement({
    required List<String> userOrder,
    required List<String> correctOrder,
    required bool allowPartialCredit,
  }) {
    try {
      if (userOrder.length != correctOrder.length) {
        return ValidationResult(
          isCorrect: false,
          score: 0.0,
          feedback: 'Incomplete arrangement.',
        );
      }
      
      int correctPositions = 0;
      for (int i = 0; i < userOrder.length; i++) {
        if (userOrder[i] == correctOrder[i]) {
          correctPositions++;
        }
      }
      
      final score = correctPositions / correctOrder.length;
      
      if (allowPartialCredit) {
        return ValidationResult(
          isCorrect: score >= rearrangementPassingScore,
          score: score,
          feedback: '$correctPositions out of ${correctOrder.length} items in correct position.',
        );
      } else {
        final isCorrect = score == 1.0;
        return ValidationResult(
          isCorrect: isCorrect,
          score: isCorrect ? 1.0 : 0.0,
          feedback: isCorrect 
              ? 'Perfect arrangement!' 
              : 'Not all items are in the correct order.',
        );
      }
    } catch (e, stackTrace) {
      logger.e('Error validating rearrangement', error: e, stackTrace: stackTrace);
      return ValidationResult(
        isCorrect: false,
        score: 0.0,
        feedback: 'Error validating answer.',
      );
    }
  }
  
  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    List<int> previousRow = List.generate(s2.length + 1, (i) => i);
    
    for (int i = 0; i < s1.length; i++) {
      List<int> currentRow = [i + 1];
      
      for (int j = 0; j < s2.length; j++) {
        int insertCost = currentRow[j] + 1;
        int deleteCost = previousRow[j + 1] + 1;
        int replaceCost = previousRow[j] + (s1[i] != s2[j] ? 1 : 0);
        
        currentRow.add([insertCost, deleteCost, replaceCost]
            .reduce((a, b) => a < b ? a : b));
      }
      
      previousRow = currentRow;
    }
    
    return previousRow[s2.length];
  }
}

/// Result of answer validation
class ValidationResult {
  final bool isCorrect;
  final double score;
  final String feedback;
  final Map<String, dynamic>? detailedFeedback;
  final List<String>? hints;
  final String? explanation;
  
  const ValidationResult({
    required this.isCorrect,
    required this.score,
    required this.feedback,
    this.detailedFeedback,
    this.hints,
    this.explanation,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'isCorrect': isCorrect,
      'score': score,
      'feedback': feedback,
      'detailedFeedback': detailedFeedback,
      'hints': hints,
      'explanation': explanation,
    };
  }
}

// ---------------------------------------------------------------------------
// Lightweight arithmetic expression parser
// ---------------------------------------------------------------------------
//
// Grammar (standard operator precedence):
//   expr   = term   (( '+' | '-' ) term)*
//   term   = factor (( '*' | '/' ) factor)*
//   factor = '(' expr ')' | '-' factor | number
//   number = [0-9]+ ( '.' [0-9]+ )?
//
// Throws [FormatException] on invalid input; callers should catch it.
// ---------------------------------------------------------------------------

class _MathParser {
  final String _src;
  int _pos = 0;

  _MathParser(String expr) : _src = expr.replaceAll(' ', '');

  /// Parse the full expression and return its value.
  /// Throws [FormatException] if the string is not a valid expression.
  double parse() {
    if (_src.isEmpty) throw const FormatException('Empty expression');
    final result = _parseExpr();
    if (_pos != _src.length) {
      throw FormatException('Unexpected character at position $_pos');
    }
    return result;
  }

  double _parseExpr() {
    var value = _parseTerm();
    while (_pos < _src.length && (_src[_pos] == '+' || _src[_pos] == '-')) {
      final op = _src[_pos++];
      final right = _parseTerm();
      value = op == '+' ? value + right : value - right;
    }
    return value;
  }

  double _parseTerm() {
    var value = _parseFactor();
    while (_pos < _src.length && (_src[_pos] == '*' || _src[_pos] == '/')) {
      final op = _src[_pos++];
      final right = _parseFactor();
      if (op == '/') {
        if (right == 0) throw FormatException('Division by zero at position $_pos');
        value /= right;
      } else {
        value *= right;
      }
    }
    return value;
  }

  double _parseFactor() {
    if (_pos >= _src.length) throw const FormatException('Unexpected end of expression');

    // Parenthesised sub-expression
    if (_src[_pos] == '(') {
      _pos++; // consume '('
      final value = _parseExpr();
      if (_pos >= _src.length || _src[_pos] != ')') {
        throw const FormatException('Missing closing parenthesis');
      }
      _pos++; // consume ')'
      return value;
    }

    // Unary minus
    if (_src[_pos] == '-') {
      _pos++;
      return -_parseFactor();
    }

    // Number: digits with optional decimal point
    final start = _pos;
    while (_pos < _src.length && _isDigitOrDot(_src[_pos])) {
      _pos++;
    }
    if (_pos == start) {
      throw FormatException('Expected number at position $_pos, got "${_src[_pos]}"');
    }
    return double.parse(_src.substring(start, _pos));
  }

  static bool _isDigitOrDot(String ch) {
    return (ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0) || ch == '.';
  }
}
