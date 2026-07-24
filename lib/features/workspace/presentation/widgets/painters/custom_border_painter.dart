import 'package:flutter/material.dart';

class CustomBorderPainter extends CustomPainter {
  final Color color;
  final String style;
  final String position;
  final double strokeWidth;

  CustomBorderPainter({
    required this.color,
    required this.style,
    this.position = 'all',
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (position == 'bottom') {
      final path = Path()..moveTo(0, size.height - strokeWidth / 2)..lineTo(size.width, size.height - strokeWidth / 2);

      if (style == 'dashed') {
        final dashedPath = _dashPath(path, [6.0, 4.0]);
        canvas.drawPath(dashedPath, paint);
      } else if (style == 'dotted') {
        final dottedPath = _dashPath(path, [2.0, 4.0]);
        canvas.drawPath(dottedPath, paint);
      } else {
        canvas.drawPath(path, paint);
      }
    } else {
      final path = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
          const Radius.circular(4),
        ));

      if (style == 'dashed') {
        final dashedPath = _dashPath(path, [6.0, 4.0]);
        canvas.drawPath(dashedPath, paint);
      } else if (style == 'dotted') {
        final dottedPath = _dashPath(path, [2.0, 4.0]);
        canvas.drawPath(dottedPath, paint);
      } else {
        canvas.drawPath(path, paint);
      }
    }
  }

  Path _dashPath(Path source, List<double> dashPattern) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final len = dashPattern[draw ? 0 : 1];
        if (draw) {
          dashedPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}