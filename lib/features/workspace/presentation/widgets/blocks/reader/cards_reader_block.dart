import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/utils/responsive_utils.dart';
import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/utils/json_string_converter.dart';
import 'package:barruu/features/workspace/utils/style_utils.dart';
import 'package:barruu/features/workspace/presentation/widgets/blocks/writer/card_templates.dart';

/// Read-only display of cards block with horizontal scrolling.
class CardsReaderBlock extends ConsumerWidget {
  final Block block;
  final Directory? docDir;

  const CardsReaderBlock({required this.block, this.docDir, super.key});

  Map<String, dynamic> _parseContent() {
    final converter = JsonStringConverter();
    try {
      return converter.convertFromJsonString(block.content);
    } catch (e) {
      return {'cards': [], 'cardStyle': 'elevated', 'cardTemplate': 'standard'};
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final styleUtils = ref.read(styleUtilsProvider);
    final theme = Theme.of(context);
    final content = _parseContent();
    final cards = content['cards'] as List? ?? [];
    final cardStyle = content['cardStyle']?.toString() ?? 'elevated';
    final cardTemplate = content['cardTemplate']?.toString() ?? 'standard';

    // Apply block styles
    final fontSize = block.style.fontSize;
    final parsedColor = styleUtils.parseHex(block.style.color);
    final color = parsedColor ?? theme.colorScheme.onSurface;
    final parsedBackground = styleUtils.parseHex(block.style.background);
    final textMultiplier = ResponsiveUtils.getTextSizeMultiplier(context);
    final baseTextStyle = styleUtils
        .applyStyle(block.style)
        .copyWith(fontSize: fontSize * textMultiplier, color: color);

    if (cards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: parsedBackground != null
            ? BoxDecoration(
                color: parsedBackground,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Text(
          'No cards available',
          style: baseTextStyle.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return DefaultTextStyle(
      style: baseTextStyle,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: parsedBackground != null ? const EdgeInsets.all(8) : null,
        decoration: parsedBackground != null
            ? BoxDecoration(
                color: parsedBackground,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        height: _getCardHeightForTemplate(cardTemplate),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final card = cards[index] as Map<String, dynamic>;
            return _buildCard(context, theme, card, cardStyle, cardTemplate);
          },
        ),
      ),
    );
  }

  double _getCardHeightForTemplate(String template) {
    switch (template) {
      case 'horizontal':
        return 200;
      case 'compact':
        return 200;
      case 'featured':
        return 420;
      case 'overlay':
        return 220;
      case 'magazine':
        return 400;
      case 'split':
        return 200;
      case 'banner':
        return 160;
      case 'avatar':
        return 220;
      case 'imageRight':
        return 200;
      case 'icon':
        return 220;
      case 'social':
        return 320;
      case 'product':
        return 280;
      case 'standard':
      default:
        return 260;
    }
  }

  Widget _buildCard(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> card,
    String cardStyle,
    String cardTemplate,
  ) {
    // Build card content based on template
    Widget cardContent;

    switch (cardTemplate) {
      case 'horizontal':
        cardContent = buildHorizontalCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'compact':
        cardContent = buildCompactCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'featured':
        cardContent = buildFeaturedCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'overlay':
        cardContent = buildOverlayCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'magazine':
        cardContent = buildMagazineCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'split':
        cardContent = buildSplitCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'banner':
        cardContent = buildBannerCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'avatar':
        cardContent = buildAvatarCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'imageRight':
        cardContent = buildImageRightCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'icon':
        cardContent = buildIconCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'social':
        cardContent = buildSocialCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'product':
        cardContent = buildProductCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
      case 'standard':
      default:
        cardContent = buildStandardCardTemplate(
          theme: theme,
          card: card,
          cardStyle: cardStyle,
          docDir: docDir,
        );
        break;
    }

    // Wrap card content in appropriate card style
    switch (cardStyle) {
      case 'elevated':
        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: cardContent,
        );
      case 'outlined':
        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.colorScheme.outline, width: 1),
          ),
          child: cardContent,
        );
      case 'filled':
        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surfaceContainerHighest,
          child: cardContent,
        );
      default:
        return Card(clipBehavior: Clip.antiAlias, child: cardContent);
    }
  }
}
