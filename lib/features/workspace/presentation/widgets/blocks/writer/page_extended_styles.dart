import 'package:barruu/features/workspace/domain/entities/block.dart';
import 'package:barruu/features/workspace/presentation/services/page_icon_utils.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

TextDecoration? _buildDecoration(BlockStyle blockStyle) {
  if (blockStyle.underline && blockStyle.strikethrough) {
    return TextDecoration.combine([
      TextDecoration.underline,
      TextDecoration.lineThrough,
    ]);
  } else if (blockStyle.underline) {
    return TextDecoration.underline;
  } else if (blockStyle.strikethrough) {
    return TextDecoration.lineThrough;
  }
  return null;
}

// ---------------------------------------------------------------------------
// Banner style
// ---------------------------------------------------------------------------

/// Full-width banner with centred title on a solid primary-colour background.
Widget buildPageBlockBannerStyle({
  required ThemeData theme,
  required dynamic styleUtils,
  required BlockStyle blockStyle,
  required String title,
  required bool hasPage,
  required bool isEditing,
  required bool showIcon,
  required VoidCallback onNavigate,
  required VoidCallback onLinkPage,
  required TextEditingController titleController,
  required ValueChanged<String> onTitleChanged,
}) {
  final bg =
      styleUtils.parseHex(blockStyle.background) ?? theme.colorScheme.primary;
  final fg =
      styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.onPrimary;

  final titleStyle = theme.textTheme.titleMedium?.copyWith(
    color: fg,
    fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w700,
    fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
    fontSize: blockStyle.fontSize,
    fontFamily: blockStyle.fontFamily,
    decoration: _buildDecoration(blockStyle),
    decorationColor: fg,
  );

  final bannerWidget = Container(
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showIcon) ...[
              Icon(getPageIcon(blockStyle.customIcon), color: fg, size: 22),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: isEditing
                  ? TextField(
                      controller: titleController,
                      onChanged: onTitleChanged,
                      textAlign: styleUtils.textAlignFromStyle(blockStyle),
                      style: titleStyle,
                      decoration: InputDecoration(
                        hintText: 'Untitled',
                        hintStyle: titleStyle?.copyWith(
                          color: fg.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : Text(
                      title,
                      style: titleStyle,
                      textAlign: styleUtils.textAlignFromStyle(blockStyle),
                    ),
            ),
            if (!isEditing && hasPage) ...[
              const SizedBox(width: 8),
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 16,
                color: fg.withOpacity(0.8),
              ),
            ],
          ],
        ),
        if (isEditing) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  size: 14,
                  color: fg,
                ),
                label: Text('Go', style: TextStyle(color: fg, fontSize: 13)),
                onPressed: hasPage ? onNavigate : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: Icon(IconsaxPlusLinear.link, size: 14, color: fg),
                label: Text('Link', style: TextStyle(color: fg, fontSize: 13)),
                onPressed: onLinkPage,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  if (!isEditing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPage ? onNavigate : null,
        borderRadius: BorderRadius.circular(12),
        child: bannerWidget,
      ),
    );
  }
  return bannerWidget;
}

// ---------------------------------------------------------------------------
// Sidebar style
// ---------------------------------------------------------------------------

/// Left accent border with icon and text – like a document reference.
Widget buildPageBlockSidebarStyle({
  required ThemeData theme,
  required dynamic styleUtils,
  required BlockStyle blockStyle,
  required String title,
  required bool hasPage,
  required bool isEditing,
  required bool showIcon,
  required VoidCallback onNavigate,
  required VoidCallback onLinkPage,
  required TextEditingController titleController,
  required ValueChanged<String> onTitleChanged,
}) {
  final accentColor =
      styleUtils.parseHex(blockStyle.borderColor) ?? theme.colorScheme.primary;
  final titleStyle = theme.textTheme.bodyLarge?.copyWith(
    color: styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.onSurface,
    fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
    fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
    fontSize: blockStyle.fontSize,
    fontFamily: blockStyle.fontFamily,
    decoration: _buildDecoration(blockStyle),
  );

  final sidebarWidget = IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 4,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showIcon) ...[
                    Icon(
                      getPageIcon(blockStyle.customIcon),
                      color: accentColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: isEditing
                        ? TextField(
                            controller: titleController,
                            onChanged: onTitleChanged,
                            style: titleStyle,
                            textAlign: styleUtils.textAlignFromStyle(
                              blockStyle,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Untitled',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        : Text(
                            title,
                            style: titleStyle,
                            textAlign: styleUtils.textAlignFromStyle(
                              blockStyle,
                            ),
                          ),
                  ),
                  if (!isEditing && hasPage)
                    Icon(
                      IconsaxPlusLinear.arrow_right_3,
                      size: 14,
                      color: accentColor.withOpacity(0.7),
                    ),
                ],
              ),
              if (isEditing) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(
                        IconsaxPlusLinear.arrow_right_3,
                        size: 13,
                      ),
                      label: const Text('Go', style: TextStyle(fontSize: 12)),
                      onPressed: hasPage ? onNavigate : null,
                      style: TextButton.styleFrom(
                        foregroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      icon: const Icon(IconsaxPlusLinear.link, size: 13),
                      label: const Text('Link', style: TextStyle(fontSize: 12)),
                      onPressed: onLinkPage,
                      style: TextButton.styleFrom(
                        foregroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  if (!isEditing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPage ? onNavigate : null,
        borderRadius: BorderRadius.circular(4),
        child: sidebarWidget,
      ),
    );
  }
  return sidebarWidget;
}

// ---------------------------------------------------------------------------
// Floating style
// ---------------------------------------------------------------------------

/// Elevated card with drop shadow and no border – "floating" on the surface.
Widget buildPageBlockFloatingStyle({
  required ThemeData theme,
  required dynamic styleUtils,
  required BlockStyle blockStyle,
  required String title,
  required bool hasPage,
  required bool isEditing,
  required bool showIcon,
  required VoidCallback onNavigate,
  required VoidCallback onLinkPage,
  required TextEditingController titleController,
  required ValueChanged<String> onTitleChanged,
}) {
  final titleStyle = theme.textTheme.bodyLarge?.copyWith(
    fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
    fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
    color: styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.onSurface,
    fontSize: blockStyle.fontSize,
    fontFamily: blockStyle.fontFamily,
    decoration: _buildDecoration(blockStyle),
  );

  final floatingWidget = Container(
    decoration: BoxDecoration(
      color:
          styleUtils.parseHex(blockStyle.background) ??
          theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showIcon) ...[
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  getPageIcon(blockStyle.customIcon),
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: titleController,
                      onChanged: onTitleChanged,
                      style: titleStyle,
                      textAlign: styleUtils.textAlignFromStyle(blockStyle),
                      decoration: const InputDecoration(
                        hintText: 'Untitled',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : Text(
                      title,
                      style: titleStyle,
                      textAlign: styleUtils.textAlignFromStyle(blockStyle),
                    ),
            ),
            if (!isEditing && hasPage)
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
        if (isEditing) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(IconsaxPlusLinear.arrow_right_3, size: 16),
                  label: const Text('Open'),
                  onPressed: hasPage ? onNavigate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(IconsaxPlusLinear.link, size: 16),
                  label: const Text('Link'),
                  onPressed: onLinkPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  if (!isEditing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPage ? onNavigate : null,
        borderRadius: BorderRadius.circular(14),
        child: floatingWidget,
      ),
    );
  }
  return floatingWidget;
}

// ---------------------------------------------------------------------------
// Gradient style
// ---------------------------------------------------------------------------

/// Full gradient background spanning the width, white text.
Widget buildPageBlockGradientStyle({
  required ThemeData theme,
  required dynamic styleUtils,
  required BlockStyle blockStyle,
  required String title,
  required bool hasPage,
  required bool isEditing,
  required bool showIcon,
  required VoidCallback onNavigate,
  required VoidCallback onLinkPage,
  required TextEditingController titleController,
  required ValueChanged<String> onTitleChanged,
}) {
  final List<Color> gradientColors =
      (blockStyle.gradientColors?.isNotEmpty == true)
      ? blockStyle.gradientColors!
            .map(
              (h) =>
                  styleUtils.parseHex(h) as Color? ?? theme.colorScheme.primary,
            )
            .toList()
      : [theme.colorScheme.primary, theme.colorScheme.tertiary];

  const fg = Colors.white;

  final titleStyle = theme.textTheme.titleMedium?.copyWith(
    color: fg,
    fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
    fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
    fontSize: blockStyle.fontSize,
    fontFamily: blockStyle.fontFamily,
    decoration: _buildDecoration(blockStyle),
    decorationColor: fg,
  );

  final gradientWidget = Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showIcon) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  getPageIcon(blockStyle.customIcon),
                  color: fg,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: titleController,
                      onChanged: onTitleChanged,
                      style: titleStyle,
                      textAlign: styleUtils.textAlignFromStyle(blockStyle),
                      decoration: InputDecoration(
                        hintText: 'Untitled',
                        hintStyle: titleStyle?.copyWith(
                          color: fg.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : Text(
                      title,
                      style: titleStyle,
                      textAlign: styleUtils.textAlignFromStyle(blockStyle),
                    ),
            ),
            if (!isEditing && hasPage) ...[
              const SizedBox(width: 8),
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 18,
                color: fg.withValues(alpha: 0.8),
              ),
            ],
          ],
        ),
        if (isEditing) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(IconsaxPlusLinear.arrow_right_3, size: 16),
                  label: const Text('Go to Page'),
                  onPressed: hasPage ? onNavigate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    foregroundColor: fg,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(IconsaxPlusLinear.link, size: 16),
                  label: const Text('Link Page'),
                  onPressed: onLinkPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: fg,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  if (!isEditing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPage ? onNavigate : null,
        borderRadius: BorderRadius.circular(14),
        child: gradientWidget,
      ),
    );
  }
  return gradientWidget;
}

// ---------------------------------------------------------------------------
// Outlined style
// ---------------------------------------------------------------------------

/// Border-only style with transparent background – subtle reference.
Widget buildPageBlockOutlinedStyle({
  required ThemeData theme,
  required dynamic styleUtils,
  required BlockStyle blockStyle,
  required String title,
  required bool hasPage,
  required bool isEditing,
  required bool showIcon,
  required VoidCallback onNavigate,
  required VoidCallback onLinkPage,
  required TextEditingController titleController,
  required ValueChanged<String> onTitleChanged,
}) {
  final borderColor =
      styleUtils.parseHex(blockStyle.borderColor) ??
      theme.colorScheme.primary.withValues(alpha: 0.6);

  final titleStyle = theme.textTheme.bodyLarge?.copyWith(
    color: styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.primary,
    fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w600,
    fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
    fontSize: blockStyle.fontSize,
    fontFamily: blockStyle.fontFamily,
    decoration: _buildDecoration(blockStyle),
  );

  final outlinedWidget = Container(
    decoration: BoxDecoration(
      border: Border.all(color: borderColor, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showIcon) ...[
              Icon(
                getPageIcon(blockStyle.customIcon),
                color: borderColor,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: titleController,
                      onChanged: onTitleChanged,
                      style: titleStyle,
                      textAlign: styleUtils.textAlignFromStyle(blockStyle),
                      decoration: const InputDecoration(
                        hintText: 'Untitled',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : Text(
                      title,
                      style: titleStyle,
                      textAlign: styleUtils.textAlignFromStyle(blockStyle),
                    ),
            ),
            if (!isEditing && hasPage)
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 16,
                color: borderColor,
              ),
          ],
        ),
        if (isEditing) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(IconsaxPlusLinear.arrow_right_3, size: 14),
                  label: const Text('Go', style: TextStyle(fontSize: 13)),
                  onPressed: hasPage ? onNavigate : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(IconsaxPlusLinear.link, size: 14),
                  label: const Text('Link', style: TextStyle(fontSize: 13)),
                  onPressed: onLinkPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  if (!isEditing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPage ? onNavigate : null,
        borderRadius: BorderRadius.circular(12),
        child: outlinedWidget,
      ),
    );
  }
  return outlinedWidget;
}

// ---------------------------------------------------------------------------
// Hero style
// ---------------------------------------------------------------------------

/// Large icon centred with a prominent title below – "hero" display.
Widget buildPageBlockHeroStyle({
  required ThemeData theme,
  required dynamic styleUtils,
  required BlockStyle blockStyle,
  required String title,
  required bool hasPage,
  required bool isEditing,
  required bool showIcon,
  required VoidCallback onNavigate,
  required VoidCallback onLinkPage,
  required TextEditingController titleController,
  required ValueChanged<String> onTitleChanged,
}) {
  final accentColor =
      styleUtils.parseHex(blockStyle.color) ?? theme.colorScheme.primary;

  final titleStyle = theme.textTheme.titleLarge?.copyWith(
    color: accentColor,
    fontWeight: blockStyle.bold ? FontWeight.bold : FontWeight.w700,
    fontStyle: blockStyle.italic ? FontStyle.italic : FontStyle.normal,
    fontSize: blockStyle.fontSize,
    fontFamily: blockStyle.fontFamily,
    decoration: _buildDecoration(blockStyle),
  );

  final heroWidget = Container(
    decoration: BoxDecoration(
      color:
          styleUtils.parseHex(blockStyle.background) ??
          theme.colorScheme.primaryContainer.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
    child: Column(
      children: [
        if (showIcon) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              getPageIcon(blockStyle.customIcon),
              color: accentColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
        ],
        isEditing
            ? TextField(
                controller: titleController,
                onChanged: onTitleChanged,
                textAlign: styleUtils.textAlignFromStyle(blockStyle),
                style: titleStyle,
                decoration: InputDecoration(
                  hintText: 'Untitled',
                  hintStyle: titleStyle?.copyWith(
                    color: accentColor.withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              )
            : Text(
                title,
                style: titleStyle,
                textAlign: styleUtils.textAlignFromStyle(blockStyle),
              ),
        if (!isEditing && hasPage) ...[
          const SizedBox(height: 8),
          Icon(
            IconsaxPlusLinear.arrow_right_3,
            color: accentColor.withOpacity(0.7),
            size: 20,
          ),
        ],
        if (isEditing) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(IconsaxPlusLinear.arrow_right_3, size: 16),
                label: const Text('Open Page'),
                onPressed: hasPage ? onNavigate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(IconsaxPlusLinear.link, size: 16),
                label: const Text('Link'),
                onPressed: onLinkPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  if (!isEditing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPage ? onNavigate : null,
        borderRadius: BorderRadius.circular(16),
        child: heroWidget,
      ),
    );
  }
  return heroWidget;
}
