/// Utility class for converting mathematical expressions to LaTeX format.
///
/// This formatter handles conversion of common mathematical expressions
/// into LaTeX notation for rendering with flutter_math.
///
/// Supported conversions:
/// - Trigonometric functions (sin, cos, tan, etc.)
/// - Logarithmic functions (ln, log)
/// - Powers and exponents
/// - Fractions
/// - Special symbols (pi, theta)
/// - Greek letters and mathematical operators
///
/// Example usage:
/// ```dart
/// final latex = LatexExpressionFormatter.formatExpression(
///   'sin(x) + x^2',
///   GraphType.line,
/// );
/// // Returns: 'y = \sin{x} + x^{2}'
/// ```
class LatexExpressionFormatter {
  /// Splits a raw expression string on `;` and returns non-empty trimmed parts.
  static List<String> splitExpressions(String expression) =>
      expression
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

  /// Converts a mathematical expression to LaTeX format.
  ///
  /// [expression] is the input mathematical expression as a string.
  /// [graphType] determines the output format (y =, r(θ) =, or parametric).
  ///
  /// Returns a LaTeX-formatted string ready for rendering.
  static String formatExpression(String expression, String graphType) {
    if (expression.isEmpty) return r'\text{[Empty graph block]}';

    try {
      // Handle special graph types
      if (graphType == 'bar') {
        return r'\text{Bar Chart Data}';
      } else if (graphType == 'scatter') {
        return r'\text{Scatter Plot Data}';
      }

      // For line graphs with multiple expressions, format each separately.
      if (graphType == 'line' && expression.contains(';')) {
        return formatMultipleExpressions(expression);
      }

      final latex = _rawExpressionToLatex(expression);

      // Format based on graph type
      return switch (graphType) {
        'parametric' => _formatParametric(latex),
        'polar' => 'r(\\theta) = $latex',
        _ => 'y = $latex',
      };
    } catch (e) {
      return r'\text{Invalid expression}';
    }
  }

  /// Formats multiple `;`-separated expressions as a LaTeX `cases` block.
  ///
  /// Example: `"x^2; sin(x)"` →
  /// ```
  /// \begin{cases} y_1 = x^{2} \\ y_2 = \sin{x} \end{cases}
  /// ```
  static String formatMultipleExpressions(String expression) {
    final parts = splitExpressions(expression);
    if (parts.isEmpty) return r'\text{[Empty graph block]}';
    if (parts.length == 1) return formatExpression(parts.first, 'line');

    final lines = parts.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final singleLatex = _rawExpressionToLatex(entry.value);
      return 'y_{$index} = $singleLatex';
    }).join(' \\\\ ');

    return '\\begin{cases} $lines \\end{cases}';
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Converts a single raw expression string to its LaTeX body (no prefix).
  ///
  /// This is the shared conversion core used by both [formatExpression] and
  /// [formatMultipleExpressions].
  static String _rawExpressionToLatex(String expression) {
    return expression
        // Convert powers: x^2 -> x^{2}
        .replaceAllMapped(
            RegExp(r'\^(\w+|\d+|\(.+?\))'),
            (match) => '^{${match.group(1)}}')
        // Convert function calls to LaTeX
        .replaceAllMapped(RegExp(r'(\w+)\((.*?)\)'), (match) {
          final funcName = match.group(1)!;
          final arg = match.group(2)!;
          return switch (funcName.toLowerCase()) {
            'sin' => '\\sin{$arg}',
            'cos' => '\\cos{$arg}',
            'tan' => '\\tan{$arg}',
            'asin' => '\\arcsin{$arg}',
            'acos' => '\\arccos{$arg}',
            'atan' => '\\arctan{$arg}',
            'ln' => '\\ln{$arg}',
            'log' => '\\log{$arg}',
            'sqrt' => '\\sqrt{$arg}',
            'abs' => '\\left|$arg\\right|',
            'exp' => 'e^{$arg}',
            _ => '$funcName($arg)',
          };
        })
        // Convert special symbols
        .replaceAll('pi', '\\pi')
        .replaceAll('theta', '\\theta')
        // Convert fractions: a/b -> \frac{a}{b}
        .replaceAllMapped(
            RegExp(r'(\w+|\d+\.?\d*)/(\w+|\d+\.?\d*)'),
            (match) => '\\frac{${match.group(1)}}{${match.group(2)}}')
        // Convert special operators
        .replaceAll('+-', '\\pm')
        .replaceAll('-+', '\\mp')
        .replaceAll('*', '\\cdot');
  }

  /// Formats a parametric expression into LaTeX cases format.
  static String _formatParametric(String latex) {
    try {
      final parts = latex.split(',');
      if (parts.length >= 2) {
        final xPart = parts[0].split('=')[1].trim();
        final yPart = parts[1].split('=')[1].trim();
        return '\\begin{cases} x(t) = $xPart \\\\ y(t) = $yPart \\end{cases}';
      }
      return latex;
    } catch (e) {
      return latex;
    }
  }
}
