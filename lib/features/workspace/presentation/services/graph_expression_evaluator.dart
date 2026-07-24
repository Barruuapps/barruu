import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:math_expressions/math_expressions.dart';

/// Service for evaluating mathematical expressions for graph plotting
///
/// This service provides methods to evaluate different types of mathematical
/// expressions and convert them into plottable data points.
class GraphExpressionEvaluator {
  /// Evaluates a line graph expression (y = f(x))
  ///
  /// Parameters:
  /// - [expression]: The mathematical expression as a string (e.g., "x^2 + 2*x + 1")
  /// - [minX]: Minimum x value for the domain
  /// - [maxX]: Maximum x value for the domain
  /// - [steps]: Number of points to evaluate (default: 1000)
  ///
  /// Returns a [GraphEvaluationResult] containing the plotted points and bounds
  static GraphEvaluationResult evaluateLineExpression(
    String expression,
    double minX,
    double maxX, {
    int steps = 1000,
  }) {
    final parser = Parser();
    final exp = parser.parse(expression);
    final cm = ContextModel();

    final spots = <FlSpot>[];
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (int i = 0; i <= steps; i++) {
      final x = minX + i * (maxX - minX) / steps;
      cm.bindVariable(Variable('x'), Number(x));
      final y = exp.evaluate(EvaluationType.REAL, cm);
      if (y.isFinite && !y.isNaN) {
        spots.add(FlSpot(x, y));
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
    }

    return GraphEvaluationResult(
      spots: spots,
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
    );
  }

  /// Evaluates a parametric graph expression (x(t), y(t))
  ///
  /// Parameters:
  /// - [expression]: Comma-separated parametric equations (e.g., "x(t)=cos(t), y(t)=sin(t)")
  /// - [tMin]: Minimum parameter value
  /// - [tMax]: Maximum parameter value
  /// - [steps]: Number of points to evaluate (default: 1000)
  ///
  /// Returns a [GraphEvaluationResult] with the parametric curve points
  ///
  /// Throws [FormatException] if the expression format is invalid
  static GraphEvaluationResult evaluateParametricExpression(
    String expression,
    double tMin,
    double tMax, {
    int steps = 1000,
  }) {
    final parts = expression.split(',');
    if (parts.length < 2) {
      throw const FormatException(
        'Invalid parametric equation: must have x(t) and y(t)',
      );
    }

    String xExpression = '';
    String yExpression = '';
    for (final part in parts) {
      final trimmedPart = part.trim();
      if (trimmedPart.toLowerCase().contains('x(t)')) {
        xExpression = trimmedPart.split('=').last.trim();
      } else if (trimmedPart.toLowerCase().contains('y(t)')) {
        yExpression = trimmedPart.split('=').last.trim();
      }
    }

    if (xExpression.isEmpty || yExpression.isEmpty) {
      throw const FormatException(
        'Invalid parametric equations: x(t) or y(t) missing',
      );
    }

    final parser = Parser();
    final xExp = parser.parse(xExpression);
    final yExp = parser.parse(yExpression);
    final cm = ContextModel();

    final spots = <FlSpot>[];
    double minXVal = double.infinity;
    double maxXVal = -double.infinity;
    double minYVal = double.infinity;
    double maxYVal = -double.infinity;

    for (int i = 0; i <= steps; i++) {
      final t = tMin + i * (tMax - tMin) / steps;
      cm.bindVariable(Variable('t'), Number(t));
      final x = xExp.evaluate(EvaluationType.REAL, cm);
      final y = yExp.evaluate(EvaluationType.REAL, cm);
      if (x.isFinite && y.isFinite && !x.isNaN && !y.isNaN) {
        spots.add(FlSpot(x, y));
        minXVal = math.min(minXVal, x);
        maxXVal = math.max(maxXVal, x);
        minYVal = math.min(minYVal, y);
        maxYVal = math.max(maxYVal, y);
      }
    }

    return GraphEvaluationResult(
      spots: spots,
      minX: minXVal,
      maxX: maxXVal,
      minY: minYVal,
      maxY: maxYVal,
    );
  }

  /// Evaluates a polar graph expression (r = f(theta))
  ///
  /// Parameters:
  /// - [expression]: The polar expression (e.g., "2*cos(theta)")
  /// - [thetaMin]: Minimum theta value (default: 0)
  /// - [thetaMax]: Maximum theta value (default: 2*pi)
  /// - [steps]: Number of points to evaluate (default: 1000)
  ///
  /// Returns a [GraphEvaluationResult] with Cartesian coordinates
  static GraphEvaluationResult evaluatePolarExpression(
    String expression,
    double thetaMin,
    double thetaMax, {
    int steps = 1000,
  }) {
    final parser = Parser();
    final exp = parser.parse(expression);
    final cm = ContextModel();

    final spots = <FlSpot>[];
    double minXVal = double.infinity;
    double maxXVal = -double.infinity;
    double minYVal = double.infinity;
    double maxYVal = -double.infinity;

    for (int i = 0; i <= steps; i++) {
      final theta = thetaMin + i * (thetaMax - thetaMin) / steps;
      cm.bindVariable(Variable('theta'), Number(theta));
      final r = exp.evaluate(EvaluationType.REAL, cm);
      if (r.isFinite && !r.isNaN) {
        final x = r * math.cos(theta);
        final y = r * math.sin(theta);
        if (x.isFinite && y.isFinite) {
          spots.add(FlSpot(x, y));
          minXVal = math.min(minXVal, x);
          maxXVal = math.max(maxXVal, x);
          minYVal = math.min(minYVal, y);
          maxYVal = math.max(maxYVal, y);
        }
      }
    }

    return GraphEvaluationResult(
      spots: spots,
      minX: minXVal,
      maxX: maxXVal,
      minY: minYVal,
      maxY: maxYVal,
    );
  }

  /// Parses comma-separated numeric values for bar charts and scatter plots
  ///
  /// Parameters:
  /// - [expression]: Comma-separated numeric values (e.g., "1,2,3,4,5")
  ///
  /// Returns a list of double values
  ///
  /// Throws [FormatException] if no valid values are found
  static List<double> parseNumericValues(String expression) {
    final values = expression
        .split(',')
        .map((e) => double.tryParse(e.trim()))
        .where((e) => e != null)
        .cast<double>()
        .toList();

    if (values.isEmpty) {
      throw const FormatException(
        'Invalid data format: no valid numeric values',
      );
    }

    return values;
  }

  /// Calculates key points (intercepts and vertex) for a function
  ///
  /// Parameters:
  /// - [spots]: The list of plotted points
  ///
  /// Returns a [GraphKeyPoints] object containing intercepts and vertex
  static GraphKeyPoints calculateKeyPoints(List<FlSpot> spots) {
    final xIntercepts = <FlSpot>[];
    FlSpot? yIntercept;
    FlSpot? vertex;

    if (spots.isEmpty) {
      return GraphKeyPoints(
        xIntercepts: xIntercepts,
        yIntercept: yIntercept,
        vertex: vertex,
      );
    }

    // Find y-intercept (where x = 0)
    final yInterceptSpot = spots.firstWhere(
      (spot) => (spot.x - 0).abs() < 0.5,
      orElse: () => const FlSpot(double.infinity, double.infinity),
    );
    if (yInterceptSpot.x.isFinite) {
      yIntercept = yInterceptSpot;
    }

    // Find x-intercepts (where y crosses 0)
    for (int i = 0; i < spots.length - 1; i++) {
      final current = spots[i];
      final next = spots[i + 1];

      // Check if y crosses zero between current and next
      if ((current.y <= 0 && next.y >= 0) || (current.y >= 0 && next.y <= 0)) {
        // Linear interpolation to find more precise x-intercept
        final t = -current.y / (next.y - current.y);
        final interceptX = current.x + t * (next.x - current.x);
        xIntercepts.add(FlSpot(interceptX, 0));
      }
    }

    // Find vertex/extrema (local min/max)
    if (spots.length >= 3) {
      FlSpot extremeSpot = spots[0];

      for (int i = 1; i < spots.length - 1; i++) {
        final prev = spots[i - 1];
        final current = spots[i];
        final next = spots[i + 1];

        // Check for local extrema
        if ((current.y <= prev.y && current.y <= next.y) ||
            (current.y >= prev.y && current.y >= next.y)) {
          // This is a local extremum
          extremeSpot = current;
          break;
        }
      }

      // Set vertex if we found an extremum
      if (extremeSpot != spots[0] || spots[0].y != spots[spots.length - 1].y) {
        vertex = extremeSpot;
      }
    }

    return GraphKeyPoints(
      xIntercepts: xIntercepts,
      yIntercept: yIntercept,
      vertex: vertex,
    );
  }
}

/// Result of evaluating a mathematical expression for graphing
class GraphEvaluationResult {
  /// The plotted points
  final List<FlSpot> spots;

  /// Minimum x value in the data
  final double minX;

  /// Maximum x value in the data
  final double maxX;

  /// Minimum y value in the data
  final double minY;

  /// Maximum y value in the data
  final double maxY;

  const GraphEvaluationResult({
    required this.spots,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
}

/// Key points on a graph (intercepts and vertex)
class GraphKeyPoints {
  /// X-intercepts (where the graph crosses the x-axis)
  final List<FlSpot> xIntercepts;

  /// Y-intercept (where the graph crosses the y-axis)
  final FlSpot? yIntercept;

  /// Vertex or critical point (local extremum)
  final FlSpot? vertex;

  const GraphKeyPoints({
    required this.xIntercepts,
    this.yIntercept,
    this.vertex,
  });
}
