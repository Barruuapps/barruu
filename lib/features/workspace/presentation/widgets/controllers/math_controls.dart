
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barruu/core/utils/app_logger.dart';

/// Provides controls for inserting math symbols and common equations into the document.
class MathControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;
  final TextEditingController latexController; // Add this

  const MathControls({
    super.key,
    required this.controller,
    required this.block,
    required this.latexController, // Add this
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _MathSymbolsMenu(
          controller: controller,
          block: block,
          latexController: latexController, // Pass controller
        ),
        _CommonEquationsMenu(
          controller: controller,
          block: block,
          latexController: latexController, // Pass controller
        ),
      ],
    );
  }
}

/// A popup menu for selecting and inserting common math symbols and operators.
class _MathSymbolsMenu extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;
  final TextEditingController latexController; // Add this

  const _MathSymbolsMenu({
    required this.controller,
    required this.block,
    required this.latexController, // Add this
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.functions_rounded, color: theme.colorScheme.primary, size: 24),
      tooltip: 'Insert Math Symbols',
      itemBuilder: (_) => _getMathSymbolMenuItems(),
      onSelected: (latex) => _insertLatexExpression(latex, controller, block, latexController), // Pass controller
      elevation: 0.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(maxWidth: 320.0, maxHeight: 400.0),
    );
  }

  List<PopupMenuEntry<String>> _getMathSymbolMenuItems() {
    return [
      _buildCategoryHeader('Basic Symbols'),
      _buildSymbolItem(r'x^{2}', 'x²'),
      _buildSymbolItem(r'x^{n}', 'xⁿ'),
      _buildSymbolItem(r'x_{2}', 'x₂'),
      _buildSymbolItem(r'x_{n}', 'xₙ'),
      _buildSymbolItem(r'\frac{a}{b}', 'a/b'),
      _buildSymbolItem(r'\sqrt{x}', '√x'),
      _buildSymbolItem(r'\sqrt[n]{x}', 'ⁿ√x'),
      _buildSymbolItem(r'\left( \right)', '( )'),
      _buildSymbolItem(r'\left[ \right]', '[ ]'),
      _buildSymbolItem(r'\left\{ \right\}', '{ }'),
      _buildSymbolItem(r'\left| x \right|', '|x|'),
      _buildSymbolItem(r'\lfloor x \rfloor', '⌊x⌋'),
      _buildSymbolItem(r'\lceil x \rceil', '⌈x⌉'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Operators'),
      _buildSymbolItem(r'\cdot', '·'),
      _buildSymbolItem(r'\times', '×'),
      _buildSymbolItem(r'\div', '÷'),
      _buildSymbolItem(r'\pm', '±'),
      _buildSymbolItem(r'\mp', '∓'),
      _buildSymbolItem(r'\infty', '∞'),
      _buildSymbolItem(r'\partial', '∂'),
      _buildSymbolItem(r'\nabla', '∇'),
      _buildSymbolItem(r'\approx', '≈'),
      _buildSymbolItem(r'\neq', '≠'),
      _buildSymbolItem(r'\geq', '≥'),
      _buildSymbolItem(r'\leq', '≤'),
      _buildSymbolItem(r'\equiv', '≡'),
      _buildSymbolItem(r'\propto', '∝'),
      _buildSymbolItem(r'\forall', '∀'),
      _buildSymbolItem(r'\exists', '∃'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Calculus'),
      _buildSymbolItem(r'\sum_{i=1}^{n}', '∑₁ⁿ'),
      _buildSymbolItem(r'\prod_{i=1}^{n}', '∏₁ⁿ'),
      _buildSymbolItem(r'\int_a^b', '∫ₐᵇ'),
      _buildSymbolItem(r'\iint_D', '∬_D'),
      _buildSymbolItem(r'\iiint_D', '∭_D'),
      _buildSymbolItem(r'\lim_{x \to \infty}', 'limₓ→∞'),
      _buildSymbolItem(r'\frac{d}{dx}', 'd/dx'),
      _buildSymbolItem(r'\frac{\partial}{\partial x}', '∂/∂x'),
      _buildSymbolItem(r'\oint_C', '∮_C'),
      _buildSymbolItem(r'\frac{d^2}{dx^2}', 'd²/dx²'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Greek Letters (Lowercase)'),
      _buildSymbolItem(r'\alpha', 'α'),
      _buildSymbolItem(r'\beta', 'β'),
      _buildSymbolItem(r'\gamma', 'γ'),
      _buildSymbolItem(r'\delta', 'δ'),
      _buildSymbolItem(r'\epsilon', 'ε'),
      _buildSymbolItem(r'\zeta', 'ζ'),
      _buildSymbolItem(r'\eta', 'η'),
      _buildSymbolItem(r'\theta', 'θ'),
      _buildSymbolItem(r'\iota', 'ι'),
      _buildSymbolItem(r'\kappa', 'κ'),
      _buildSymbolItem(r'\lambda', 'λ'),
      _buildSymbolItem(r'\mu', 'μ'),
      _buildSymbolItem(r'\nu', 'ν'),
      _buildSymbolItem(r'\xi', 'ξ'),
      _buildSymbolItem(r'\pi', 'π'),
      _buildSymbolItem(r'\rho', 'ρ'),
      _buildSymbolItem(r'\sigma', 'σ'),
      _buildSymbolItem(r'\tau', 'τ'),
      _buildSymbolItem(r'\upsilon', 'υ'),
      _buildSymbolItem(r'\phi', 'φ'),
      _buildSymbolItem(r'\chi', 'χ'),
      _buildSymbolItem(r'\psi', 'ψ'),
      _buildSymbolItem(r'\omega', 'ω'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Greek Letters (Uppercase)'),
      _buildSymbolItem(r'\Gamma', 'Γ'),
      _buildSymbolItem(r'\Delta', 'Δ'),
      _buildSymbolItem(r'\Theta', 'Θ'),
      _buildSymbolItem(r'\Lambda', 'Λ'),
      _buildSymbolItem(r'\Xi', 'Ξ'),
      _buildSymbolItem(r'\Pi', 'Π'),
      _buildSymbolItem(r'\Sigma', 'Σ'),
      _buildSymbolItem(r'\Upsilon', 'Υ'),
      _buildSymbolItem(r'\Phi', 'Φ'),
      _buildSymbolItem(r'\Psi', 'Ψ'),
      _buildSymbolItem(r'\Omega', 'Ω'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Arrows'),
      _buildSymbolItem(r'\rightarrow', '→'),
      _buildSymbolItem(r'\leftarrow', '←'),
      _buildSymbolItem(r'\uparrow', '↑'),
      _buildSymbolItem(r'\downarrow', '↓'),
      _buildSymbolItem(r'\leftrightarrow', '↔'),
      _buildSymbolItem(r'\Rightarrow', '⇒'),
      _buildSymbolItem(r'\Leftarrow', '⇐'),
      _buildSymbolItem(r'\Leftrightarrow', '⇔'),
      _buildSymbolItem(r'\rightharpoonup', '⇀'),
      _buildSymbolItem(r'\leftharpoonup', '↼'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Relations'),
      _buildSymbolItem(r'\in', '∈'),
      _buildSymbolItem(r'\notin', '∉'),
      _buildSymbolItem(r'\subset', '⊂'),
      _buildSymbolItem(r'\supset', '⊃'),
      _buildSymbolItem(r'\subseteq', '⊆'),
      _buildSymbolItem(r'\supseteq', '⊇'),
      _buildSymbolItem(r'\perp', '⊥'),
      _buildSymbolItem(r'\parallel', '∥'),
    ];
  }

  PopupMenuItem<String> _buildSymbolItem(String latex, String symbol) {
    return PopupMenuItem<String>(
      value: latex,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              symbol,
              style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              latex,
              style: TextStyle(fontSize: 12.0, color: Colors.grey[700], fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildCategoryHeader(String text) {
    return PopupMenuItem<String>(
      enabled: false,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
            fontSize: 14.0,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// A popup menu for selecting and inserting common mathematical equations and formulas.
class _CommonEquationsMenu extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;
  final TextEditingController latexController; // Add this

  const _CommonEquationsMenu({
    required this.controller,
    required this.block,
    required this.latexController, // Add this
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      icon: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary, size: 24),
      tooltip: 'Insert Common Equations',
      itemBuilder: (_) => _getCommonEquationsMenuItems(),
      onSelected: (latex) => _insertLatexExpression(latex, controller, block, latexController), // Pass controller
      elevation: 0.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(maxWidth: 380.0, maxHeight: 450.0),
    );
  }

  List<PopupMenuEntry<String>> _getCommonEquationsMenuItems() {
    return [
      _buildCategoryHeader('Algebra'),
      _buildEquationItem(
        r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}',
        'Quadratic Formula',
        'x = (-b ± √(b²-4ac))/2a',
      ),
      _buildEquationItem(r'a^2 + b^2 = c^2', 'Pythagorean Theorem', 'a² + b² = c²'),
      _buildEquationItem(
        r'(a+b)^2 = a^2 + 2ab + b^2',
        'Binomial Expansion (Square)',
        '(a+b)² = a² + 2ab + b²',
      ),
      _buildEquationItem(
        r'(a-b)^2 = a^2 - 2ab + b^2',
        'Binomial Expansion (Difference Square)',
        '(a-b)² = a² - 2ab + b²',
      ),
      _buildEquationItem(
        r'a^3 + b^3 = (a+b)(a^2 - ab + b^2)',
        'Sum of Cubes',
        'a³ + b³ = (a+b)(a² - ab + b²)',
      ),
      _buildEquationItem(
        r'a^3 - b^3 = (a-b)(a^2 + ab + b^2)',
        'Difference of Cubes',
        'a³ - b³ = (a-b)(a² + ab + b²)',
      ),
      _buildEquationItem(
        r'(a+b)^3 = a^3 + 3a^2b + 3ab^2 + b^3',
        'Binomial Expansion (Cube)',
        '(a+b)³ = a³ + 3a²b + 3ab² + b³',
      ),
      _buildEquationItem(r'\log_b (xy) = \log_b x + \log_b y', 'Log Product Rule', 'log_b(xy) = log_b x + log_b y'),
      _buildEquationItem(r'\log_b (x/y) = \log_b x - \log_b y', 'Log Quotient Rule', 'log_b(x/y) = log_b x - log_b y'),
      _buildEquationItem(r'\log_b (x^y) = y \log_b x', 'Log Power Rule', 'log_b(x^y) = y log_b x'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Geometry'),
      _buildEquationItem(r'A = \pi r^2', 'Area of Circle', 'A = πr²'),
      _buildEquationItem(r'C = 2\pi r', 'Circumference of Circle', 'C = 2πr'),
      _buildEquationItem(r'V = \frac{4}{3} \pi r^3', 'Volume of Sphere', 'V = (4/3)πr³'),
      _buildEquationItem(r'S = 4 \pi r^2', 'Surface Area of Sphere', 'S = 4πr²'),
      _buildEquationItem(r'A = \frac{1}{2} b h', 'Area of Triangle', 'A = (1/2)bh'),
      _buildEquationItem(r'A = l w', 'Area of Rectangle', 'A = lw'),
      _buildEquationItem(r'V = l w h', 'Volume of Rectangular Prism', 'V = lwh'),
      _buildEquationItem(r'A = b h', 'Area of Parallelogram', 'A = bh'),
      _buildEquationItem(r'V = \frac{1}{3} \pi r^2 h', 'Volume of Cone', 'V = (1/3)πr²h'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Trigonometry'),
      _buildEquationItem(
        r'\sin^2 \theta + \cos^2 \theta = 1',
        'Pythagorean Identity',
        'sin²θ + cos²θ = 1',
      ),
      _buildEquationItem(
        r'\tan \theta = \frac{\sin \theta}{\cos \theta}',
        'Tangent Identity',
        'tanθ = sinθ / cosθ',
      ),
      _buildEquationItem(
        r'\sin(2\theta) = 2 \sin \theta \cos \theta',
        'Double Angle for Sine',
        'sin(2θ) = 2 sinθ cosθ',
      ),
      _buildEquationItem(
        r'\cos(2\theta) = \cos^2 \theta - \sin^2 \theta',
        'Double Angle for Cosine',
        'cos(2θ) = cos²θ - sin²θ',
      ),
      _buildEquationItem(
        r'\sin(\alpha \pm \beta) = \sin \alpha \cos \beta \pm \cos \alpha \sin \beta',
        'Sine Addition/Subtraction',
        'sin(α ± β) = sinα cosβ ± cosα sinβ',
      ),
      _buildEquationItem(
        r'\cos(\alpha \pm \beta) = \cos \alpha \cos \beta \mp \sin \alpha \sin \beta',
        'Cosine Addition/Subtraction',
        'cos(α ± β) = cosα cosβ ∓ sinα sinβ',
      ),
      _buildEquationItem(r'\csc \theta = \frac{1}{\sin \theta}', 'Cosecant Identity', 'cscθ = 1 / sinθ'),
      _buildEquationItem(r'\sec \theta = \frac{1}{\cos \theta}', 'Secant Identity', 'secθ = 1 / cosθ'),
      _buildEquationItem(r'\cot \theta = \frac{1}{\tan \theta}', 'Cotangent Identity', 'cotθ = 1 / tanθ'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Calculus'),
      _buildEquationItem(
        r'\frac{d}{dx} x^n = n x^{n-1}',
        'Power Rule (Derivative)',
        'd/dx [xⁿ] = n x^{n-1}',
      ),
      _buildEquationItem(
        r'\int x^n \, dx = \frac{x^{n+1}}{n+1} + C',
        'Power Rule (Integral)',
        '∫ xⁿ dx = x^{n+1}/(n+1) + C',
      ),
      _buildEquationItem(
        r'\frac{d}{dx} \sin x = \cos x',
        'Derivative of Sine',
        'd/dx [sin x] = cos x',
      ),
      _buildEquationItem(
        r'\frac{d}{dx} \cos x = -\sin x',
        'Derivative of Cosine',
        'd/dx [cos x] = -sin x',
      ),
      _buildEquationItem(
        r'\frac{d}{dx} e^x = e^x',
        'Derivative of Exponential',
        'd/dx [e^x] = e^x',
      ),
      _buildEquationItem(
        r'\frac{d}{dx} \ln x = \frac{1}{x}',
        'Derivative of Natural Log',
        'd/dx [ln x] = 1/x',
      ),
      _buildEquationItem(
        r'\frac{d}{dx} \tan x = \sec^2 x',
        'Derivative of Tangent',
        'd/dx [tan x] = sec² x',
      ),
      _buildEquationItem(
        r'\int e^x \, dx = e^x + C',
        'Integral of Exponential',
        '∫ e^x dx = e^x + C',
      ),
      _buildEquationItem(
        r'\int \frac{1}{x} \, dx = \ln |x| + C',
        'Integral of 1/x',
        '∫ (1/x) dx = ln |x| + C',
      ),
      _buildEquationItem(
        r'f^{\prime\prime}(x) = \lim_{h \to 0} \frac{f^{\prime}(x+h) - f^{\prime}(x)}{h}',
        'Second Derivative',
        'f′′(x) = lim_{h→0} (f′(x+h) - f′(x))/h',
      ),
      const PopupMenuDivider(),
      _buildCategoryHeader('Physics'),
      _buildEquationItem(r'F = m a', "Newton's Second Law", 'F = ma'),
      _buildEquationItem(r'E = m c^2', 'Mass-Energy Equivalence', 'E = mc²'),
      _buildEquationItem(r'V = I R', "Ohm's Law", 'V = IR'),
      _buildEquationItem(
        r's = u t + \frac{1}{2} a t^2',
        'Equation of Motion (Displacement)',
        's = ut + (1/2)at²',
      ),
      _buildEquationItem(r'v = u + a t', 'Equation of Motion (Velocity)', 'v = u + at'),
      _buildEquationItem(r'v^2 = u^2 + 2 a s', 'Equation of Motion (Velocity Squared)', 'v² = u² + 2as'),
      _buildEquationItem(r'p = m v', 'Momentum', 'p = mv'),
      _buildEquationItem(r'KE = \frac{1}{2} m v^2', 'Kinetic Energy', 'KE = (1/2)mv²'),
      _buildEquationItem(r'PE = m g h', 'Gravitational Potential Energy', 'PE = mgh'),
      _buildEquationItem(r'P = \frac{W}{t}', 'Power', 'P = W/t'),
      const PopupMenuDivider(),
      _buildCategoryHeader('Statistics'),
      _buildEquationItem(
        r'\bar{x} = \frac{\sum x_i}{n}',
        'Mean (Arithmetic)',
        'x̄ = (∑ x_i) / n',
      ),
      _buildEquationItem(
        r'\sigma^2 = \frac{\sum (x_i - \bar{x})^2}{n}',
        'Variance (Population)',
        'σ² = ∑(x_i - x̄)² / n',
      ),
      _buildEquationItem(
        r's^2 = \frac{\sum (x_i - \bar{x})^2}{n-1}',
        'Variance (Sample)',
        's² = ∑(x_i - x̄)² / (n-1)',
      ),
      _buildEquationItem(
        r'\sigma = \sqrt{\sigma^2}',
        'Standard Deviation (Population)',
        'σ = √(σ²)',
      ),
      _buildEquationItem(
        r'P(A \cup B) = P(A) + P(B) - P(A \cap B)',
        'Probability Union',
        'P(A ∪ B) = P(A) + P(B) - P(A ∩ B)',
      ),
      _buildEquationItem(
        r'P(A \cap B) = P(A) P(B)',
        'Probability Intersection (Independent)',
        'P(A ∩ B) = P(A) P(B)',
      ),
      const PopupMenuDivider(),
      _buildCategoryHeader('Linear Algebra'),
      _buildEquationItem(
        r'\det \begin{pmatrix} a & b \\ c & d \end{pmatrix} = ad - bc',
        'Determinant (2x2 Matrix)',
        'det |a b; c d| = ad - bc',
      ),
      _buildEquationItem(
        r'A \mathbf{x} = \mathbf{b}',
        'Linear System',
        'A x = b',
      ),
      _buildEquationItem(
        r'\mathbf{u} \cdot \mathbf{v} = u_1 v_1 + u_2 v_2 + \dots',
        'Dot Product',
        'u · v = u₁v₁ + u₂v₂ + …',
      ),
      _buildEquationItem(
        r'\|\mathbf{u}\| = \sqrt{\mathbf{u} \cdot \mathbf{u}}',
        'Vector Magnitude',
        '||u|| = √(u · u)',
      ),
    ];
  }

  PopupMenuItem<String> _buildEquationItem(String latex, String name, String preview) {
    return PopupMenuItem<String>(
      value: latex,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              preview,
              style: TextStyle(fontSize: 13.0, color: Colors.grey[800]),
            ),
            const SizedBox(height: 4.0),
            Text(
              latex,
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildCategoryHeader(String text) {
    return PopupMenuItem<String>(
      enabled: false,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
            fontSize: 14.0,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Inserts the selected LaTeX expression into the block's content at the cursor position.
void _insertLatexExpression(String latex, EditDocumentController controller, Block block, TextEditingController latexController,) {
  Map<String, dynamic> content = {'latex': '', 'caption': ''};

  if (block.content.isNotEmpty) {
    try {
      content = JsonStringConverter().convertFromJsonString(block.content);
    } catch (e, stackTrace) {
      logger.e(
        'Failed to enter math equation $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Get the current LaTeX text and cursor position
  final currentLatex = latexController.text;
  final cursorPosition = latexController.selection.start;

  // Insert the LaTeX at the cursor position
  String newLatex;
  if (cursorPosition >= 0 && cursorPosition <= currentLatex.length) {
    newLatex = currentLatex.substring(0, cursorPosition) +
        latex +
        (cursorPosition < currentLatex.length ? ' ' : '') +
        currentLatex.substring(cursorPosition);
  } else {
    // Fallback: append if cursor position is invalid
    newLatex = currentLatex.isEmpty ? latex : '$currentLatex $latex';
  }

  // Update the controller's text and move cursor after the inserted LaTeX
  latexController.text = newLatex;
  latexController.selection = TextSelection.collapsed(
    offset: cursorPosition + latex.length + (cursorPosition < currentLatex.length ? 1 : 0),
  );

  // Update the block content
  content['latex'] = newLatex;
  final newContent = JsonStringConverter().convertToJsonString(content);
  final updatedBlock = block.copyWith(content: newContent);
  controller.saveBlock(updatedBlock);
}