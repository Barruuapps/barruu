import 'package:flutter/material.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/stem_json_reader_block.dart';

class TheoremReaderBlock extends StatelessWidget {
  final Block block;

  const TheoremReaderBlock({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return StemJsonReaderBlock(block: block);
  }
}
