
import 'package:barruu/core/widgets/blocks/base_editable_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/reader/divider_reader_block.dart';
import 'package:barruu/features/workspace/presentation/widgets/painters/divider_painter.dart';
import 'package:barruu/features/workspace/presentation/widgets/utils/toolbar.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class DividerBlock extends BaseEditableBlock {
  const DividerBlock({
    required super.block,
    required super.isEditing,
    required super.docDir,
    super.key,
  });

  @override
  ConsumerState<DividerBlock> createState() => _DividerBlockState();
}

class _DividerBlockState extends BaseEditableBlockState<DividerBlock> {
  late DividerStyle _dividerStyle;
  late double _thickness;
  late String? _align;
  late Color _color;
  late Color? _backgroundColor;

  @override
  Map<String, dynamic> getDefaultContent() => {
    'style': 'solid',
    'thickness': 2.0,
  };

  @override
  void initializeBlockSpecifics() {
    final styleUtils = ref.read(styleUtilsProvider);
    _align = widget.block.style.align;
    _color = styleUtils.parseHex(widget.block.style.color) ?? Colors.grey;
    _backgroundColor = styleUtils.parseHex(widget.block.style.background);
    _parseDividerContent();
  }

  @override
  void onContentChanged() {
    _parseDividerContent();
  }

  void _parseDividerContent() {
    // Parse divider style
    try {
      _dividerStyle = DividerStyle.values.firstWhere(
        (e) => e.toString().split('.').last == content['style'],
        orElse: () => DividerStyle.solid,
      );
    } catch (e) {
      _dividerStyle = DividerStyle.solid;
    }

    // Parse thickness
    try {
      _thickness = (content['thickness'] as num?)?.toDouble() ?? 2.0;
    } catch (e) {
      _thickness = 2.0;
    }
  }

  void _saveContentLocal() {
    content['style'] = _dividerStyle.toString().split('.').last;
    content['thickness'] = _thickness;
    saveContent();
  }

  void _updateStyle() {
    final styleUtils = ref.read(styleUtilsProvider);
    final updatedStyle = widget.block.style.copyWith(
      align: _align,
      color: styleUtils.toHex(_color),
      background: _backgroundColor != null
          ? styleUtils.toHex(_backgroundColor!)
          : null,
    );
    final updatedBlock = widget.block.copyWith(style: updatedStyle);
    ref.read(editDocumentControllerProvider(widget.docDir).notifier).saveBlock(updatedBlock);
  }

  @override
  Widget buildReader(BuildContext context) {
    return DividerReaderBlock(block: widget.block);
  }

  @override
  Widget buildEditor(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        FadeTransition(
          opacity: toolbarOpacity,
          child: Toolbar(block: widget.block, docDir: widget.docDir),
        ),
        // Preview of the divider
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: _backgroundColor,
          child: Align(
            alignment: _dividerStyle == DividerStyle.threeDot
                ? Alignment.center
                : _getAlignment(_align),
            child: CustomPaint(
              size: Size(double.infinity, _thickness),
              painter: DividerPainter(
                style: _dividerStyle,
                color: _color.withValues(alpha: 0.7),
                thickness: _thickness,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Divider Style: '),
            const SizedBox(width: 8),
            DropdownButton<DividerStyle>(
              value: _dividerStyle,
              items: const [
                DropdownMenuItem(value: DividerStyle.solid, child: Text('───────')),
                DropdownMenuItem(value: DividerStyle.dashed, child:Text('--------------')),
                DropdownMenuItem(value: DividerStyle.dotted, child:Text('.................')),
                DropdownMenuItem(value: DividerStyle.double, child:Text('═══════')),
                DropdownMenuItem(value: DividerStyle.threeDot, child: Text('         ...')),
              ],
              onChanged: (DividerStyle? newValue) {
                if (newValue != null) {
                  setState(() {
                    _dividerStyle = newValue;
                    _saveContentLocal();
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text('Thickness'),
                  Slider(
                    value: _thickness,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _thickness.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _thickness = value;
                        _saveContentLocal();
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const Text('Alignment'),
                  DropdownButton<String>(
                    value: _align ?? 'center',
                    items: const [
                      DropdownMenuItem(value: 'left', child: Text('Left')),
                      DropdownMenuItem(value: 'center', child: Text('Center')),
                      DropdownMenuItem(value: 'right', child: Text('Right')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _align = newValue;
                          _updateStyle();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Alignment _getAlignment(String? align) {
    switch (align) {
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}
