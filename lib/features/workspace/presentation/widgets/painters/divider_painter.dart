import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/divider_reader_block.dart';
import 'package:flutter/material.dart';

class DividerPainter extends CustomPainter {
  final DividerStyle style;
  final Color color;
  final double thickness;

  DividerPainter({
    required this.style,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    switch (style) {
      case DividerStyle.solid:
        canvas.drawLine(
          Offset(0, thickness / 2),
          Offset(size.width, thickness / 2),
          paint,
        );
        break;
      case DividerStyle.dashed:
        const dashWidth = 10;
        const dashSpace = 5;
        double startX = 0;
        while (startX < size.width) {
          canvas.drawLine(
            Offset(startX, thickness / 2),
            Offset(startX + dashWidth, thickness / 2),
            paint,
          );
          startX += dashWidth + dashSpace;
        }
        break;
      case DividerStyle.dotted:
        double dotRadius = 2;
        const dotSpace = 6;
        double startX = 0;
        while (startX < size.width) {
          canvas.drawCircle(
            Offset(startX, thickness / 2),
            dotRadius,
            paint..style = PaintingStyle.fill,
          );
          startX += dotSpace * 2;
        }
        break;
      case DividerStyle.double:
        final offsetY = thickness * 2;
        canvas.drawLine(
          Offset(0, thickness / 2),
          Offset(size.width, thickness / 2),
          paint,
        );
        canvas.drawLine(
          Offset(0, thickness / 2 + offsetY),
          Offset(size.width, thickness / 2 + offsetY),
          paint,
        );
        break;
      case DividerStyle.threeDot:
        final dotRadius = thickness * 1.5;
        final centerX = size.width / 2;
        const dotSpacing = 10.0;
        canvas.drawCircle(
          Offset(centerX - dotSpacing, thickness / 2),
          dotRadius,
          paint..style = PaintingStyle.fill,
        );
        canvas.drawCircle(Offset(centerX, thickness / 2), dotRadius, paint);
        canvas.drawCircle(
          Offset(centerX + dotSpacing, thickness / 2),
          dotRadius,
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant DividerPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.color != color ||
        oldDelegate.thickness != thickness;
  }
}
