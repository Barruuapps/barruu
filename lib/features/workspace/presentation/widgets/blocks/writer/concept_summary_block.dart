import 'dart:io';
import 'package:flutter/material.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/stem_json_block.dart';

class ConceptSummaryBlock extends StatelessWidget {
  final Block block;
  final bool isEditing;
  final Directory docDir;

  const ConceptSummaryBlock({
    super.key,
    required this.block,
    required this.isEditing,
    required this.docDir,
  });

  @override
  Widget build(BuildContext context) {
    return StemJsonBlock(block: block, isEditing: isEditing, docDir: docDir);
  }
}
