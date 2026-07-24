import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:flutter/material.dart';

class SpacerReaderBlock extends StatelessWidget {
  final Block block;

  const SpacerReaderBlock({super.key, required this.block});

  double _resolveHeight() {
    if (block.style.height != null && block.style.height! > 0) {
      return block.style.height!;
    }
    try {
      final content = JsonStringConverter().convertFromJsonString(
        block.content,
      );
      final contentHeight = (content['height'] as num?)?.toDouble();
      if (contentHeight != null && contentHeight > 0) return contentHeight;
    } catch (_) {}
    return 24.0;
  }

  @override
  Widget build(BuildContext context) {
    final height = _resolveHeight();
    return SizedBox(
      height: height,
      child: Semantics(
        label: 'Spacer block',
        child: SizedBox(height: ResponsiveUtils.getBlockSpacing(context) * 0.1),
      ),
    );
  }
}
