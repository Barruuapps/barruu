
import 'package:barruu/features/workspace/data/repositories/workspace_repository_impl.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/domain/entities/block_type.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// Controls for picking text, background, and border colors
class ColorPickerControls extends ConsumerWidget {
  final EditDocumentController controller;
  final Block block;
  final StyleUtils styleUtils;

  const ColorPickerControls({super.key,
    required this.controller,
    required this.block,
    required this.styleUtils,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = block.style;
    final buttons = [
      _buildColorButton(
        ref: ref,
        context: context,
        icon: Icons.format_color_text,
        tooltip: 'Text Color',
        initialColor: styleUtils.parseHex(style.color) ?? Colors.black,
        onPicked: (color) =>
            controller.updateStyle(block, style.copyWith(color: styleUtils.toHex(color))),
      ),
      _buildColorButton(
        ref: ref,
        context: context,
        icon: Icons.format_color_fill,
        tooltip: 'Background Color',
        initialColor: styleUtils.parseHex(style.background) ?? Colors.transparent,
        onPicked: (color) =>
            controller.updateStyle(block, style.copyWith(background: styleUtils.toHex(color))),
      ),
    ];

    if (block.type == BlockType.blockquote || block.type == BlockType.box || block.type == BlockType.page) {
      buttons.add(
        _buildColorButton(
          ref: ref,
          context: context,
          icon: Icons.border_left,
          tooltip: 'Border Color',
          initialColor: styleUtils.parseHex(style.borderColor) ?? Colors.blueGrey,
          onPicked: (color) => controller.updateStyle(block, style.copyWith(borderColor: styleUtils.toHex(color))),
        ),
      );
    }

    return Row(children: buttons);
  }

  Widget _buildColorButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required Color initialColor,
    required WidgetRef ref,
    required void Function(Color) onPicked,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showColorPickerDialog(
            context: context,
            title: tooltip,
            initialColor: initialColor,
            onPicked: onPicked,
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 3,
                    decoration: BoxDecoration(
                      color: initialColor.alpha == 0
                        ? Colors.red.withValues(alpha: 0.8)
                        : initialColor,
                      borderRadius: BorderRadius.circular(2),
                      border: initialColor.alpha == 0
                        ? Border.all(color: Colors.red, width: 0.5)
                        : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showColorPickerDialog({
    required BuildContext context,
    required String title,
    required Color initialColor,
    required void Function(Color) onPicked,
  }) async {
    Color pickedColor = initialColor;
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 600;
    
    final materialColors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple, Colors.indigo,
      Colors.blue, Colors.lightBlue, Colors.cyan, Colors.teal, Colors.green,
      Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber, Colors.orange,
      Colors.deepOrange,
    ];
    final accentColors = [
      Colors.brown, ...List.generate(9, (i) => Colors.grey[900 - i * 100]!),
      Colors.white, Colors.black, Colors.blueGrey,
    ];
    final colorShades = materialColors
        .map((color) => [
      color[900]!, color[800]!, color[700]!, color[600]!, color[500]!,
      color[400]!, color[300]!, color[200]!, color[100]!, color[50]!
    ])
        .toList();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: theme.colorScheme.surface,
          elevation: 24,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.palette,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 24 : 20,
            vertical: 20,
          ),
          content: SizedBox(
            width: isWideScreen ? 500 : screenSize.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Color preview
                  Container(
                    height: 72,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: pickedColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: (pickedColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${pickedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                          style: TextStyle(
                            color: pickedColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TabBar(
                          tabs: const [
                            Tab(text: 'Palette', icon: Icon(Icons.grid_view, size: 20)),
                            Tab(text: 'Custom', icon: Icon(Icons.tune, size: 20)),
                          ],
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                          indicatorColor: theme.colorScheme.primary,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicatorWeight: 3,
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          dividerColor: theme.colorScheme.outline.withValues(alpha: 0.1),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: isWideScreen ? 400 : 350,
                          child: TabBarView(
                            children: [
                              SingleChildScrollView(
                                child: Column(
                                  children: [
                                    // Quick colors
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Quick Colors',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _colorBoxButton(Colors.transparent, pickedColor,
                                                      (color) => setState(() => pickedColor = color)),
                                              _colorBoxButton(Colors.white, pickedColor,
                                                      (color) => setState(() => pickedColor = color)),
                                              _colorBoxButton(Colors.black, pickedColor,
                                                      (color) => setState(() => pickedColor = color)),
                                              _colorBoxButton(Colors.grey, pickedColor,
                                                      (color) => setState(() => pickedColor = color)),
                                              _colorBoxButton(Colors.red, pickedColor,
                                                      (color) => setState(() => pickedColor = color)),
                                              _colorBoxButton(Colors.blue, pickedColor,
                                                      (color) => setState(() => pickedColor = color)),
                                              _colorBoxButton(Colors.green, pickedColor,
                                                      (color) => setState(() => pickedColor = color)),
                                              _colorBoxButton(Colors.yellow, pickedColor,
                                                      (color) => setState(() => pickedColor = color)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Accent colors
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Neutral & Accent Colors',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: accentColors
                                                .map((color) => _colorBoxButton(
                                              color,
                                              pickedColor,
                                                  (c) => setState(() => pickedColor = c),
                                            ))
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Color shades
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Material Colors',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: colorShades.length,
                                            itemBuilder: (context, i) => Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: Row(
                                                children: colorShades[i]
                                                    .map((color) => Expanded(
                                                  child: _colorBoxButton(
                                                    color,
                                                    pickedColor,
                                                        (c) => setState(() => pickedColor = c),
                                                  ),
                                                ))
                                                    .toList(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: ColorPicker(
                                    pickerColor: pickedColor,
                                    onColorChanged: (color) => setState(() => pickedColor = color),
                                    portraitOnly: true,
                                    hexInputBar: true,
                                    displayThumbColor: true,
                                    pickerAreaHeightPercent: 0.7,
                                    labelTypes: const [],
                                    paletteType: PaletteType.hueWheel,
                                    colorPickerWidth: isWideScreen ? 280 : screenSize.width * 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.all(20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                onPicked(pickedColor);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 2,
                shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
  Widget _colorBoxButton(Color color, Color selectedColor, Function(Color) onSelect) {
    final isSelected = color.toARGB32() == selectedColor.toARGB32();
    final isTransparent = color.alpha == 0 || color == Colors.transparent;

    return GestureDetector(
      onTap: () => onSelect(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(2),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected 
              ? Colors.blue.shade700 
              : Colors.grey.shade300,
            width: isSelected ? 3 : 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
              spreadRadius: 1,
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: isTransparent
            ? Stack(
                children: [
                  // Checkerboard pattern for transparency
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey.shade200,
                          Colors.grey.shade300,
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.block,
                      size: 20,
                      color: Colors.red.shade700,
                    ),
                  ),
                  if (isSelected)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                ],
              )
            : isSelected
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: Colors.black.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 22,
                    color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}