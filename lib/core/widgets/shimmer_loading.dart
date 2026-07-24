import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A professional shimmer loading indicator that adapts to the current theme
/// and respects accessibility settings for reduced motion
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Check for reduced motion accessibility setting
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    // If animations are disabled, show static placeholder
    if (disableAnimations) {
      return child;
    }

    return Shimmer.fromColors(
      baseColor: isDark
          ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
          : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      highlightColor: isDark
          ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
          : Colors.white.withOpacity(0.9),
      period: const Duration(milliseconds: 1500), // Smooth, calm animation
      child: child,
    );
  }
}

/// Shimmer loading for card layouts
class ShimmerCardLoading extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerCardLoading({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: borderRadius ?? BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Shimmer loading for list items
class ShimmerListItemLoading extends StatelessWidget {
  const ShimmerListItemLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ShimmerLoading(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading for grid cards
class ShimmerGridCardLoading extends StatelessWidget {
  const ShimmerGridCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainer,
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A professional shimmer progress indicator for dialogs and overlays.
/// 
/// Uses a pulsing shimmer effect with multiple circular layers.
/// **Use for**: Document/page loading, initial data loading, centered loading states.
/// 
/// Example: PDF document loading, full-screen loading overlays
class ShimmerCircularProgress extends StatelessWidget {
  final double size;
  final Color? color;

  const ShimmerCircularProgress({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = color ?? theme.colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: progressColor.withOpacity(0.1),
            ),
          ),
          // Outer shimmer ring
          ShimmerLoading(
            child: Container(
              width: size * 0.85,
              height: size * 0.85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: progressColor.withOpacity(0.2),
              ),
            ),
          ),
          // Inner shimmer circle
          ShimmerLoading(
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: progressColor.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline shimmer for button loading states.
/// 
/// Small, rectangular shimmer bar designed for inline use within buttons.
/// **Use for**: Button loading indicators, small inline actions
/// 
/// Example: Login button, submit button loading states
class ShimmerButtonLoading extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerButtonLoading({
    super.key,
    this.width = 20,
    this.height = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Inline shimmer for small loading indicators.
/// 
/// Circular shimmer suitable for small, inline loading states like pagination.
/// **Use for**: Page/item loading within lists, smaller loading contexts than ShimmerCircularProgress.
/// 
/// Example: Paginating list items, loading individual PDF pages
class ShimmerInlineLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const ShimmerInlineLoading({
    super.key,
    this.size = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmerColor = color ?? theme.colorScheme.primary.withOpacity(0.3);
    
    return SizedBox(
      width: size,
      height: size,
      child: ShimmerLoading(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: shimmerColor,
          ),
        ),
      ),
    );
  }
}

/// Shimmer loading that looks like a document page
class ShimmerDocumentLoading extends StatelessWidget {
  const ShimmerDocumentLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ShimmerLoading(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header block
              Container(
                height: 48,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Paragraph block
              Container(
                height: 16,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 16,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 16,
                width: MediaQuery.of(context).size.width * 0.7,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Subheader
              Container(
                height: 32,
                width: MediaQuery.of(context).size.width * 0.5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // More paragraphs
              Container(
                height: 16,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 16,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 16,
                width: MediaQuery.of(context).size.width * 0.8,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Code block placeholder
              Container(
                height: 120,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rectangular shimmer box used as placeholder for text/images
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer loading that matches the ArticleCard layout.
/// Use this as the feed skeleton while posts are loading.
class ShimmerArticleCardLoading extends StatelessWidget {
  const ShimmerArticleCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;

    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: base,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 13,
                        width: 120,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 11,
                        width: 80,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 11,
                  width: 50,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Title (2 lines)
            Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 20,
              width: MediaQuery.of(context).size.width * 0.65,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
            // Description (2 lines)
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 14,
              width: MediaQuery.of(context).size.width * 0.8,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 14),
            // Engagement row
            Row(
              children: [
                Container(
                  height: 28,
                  width: 60,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 28,
                  width: 60,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 28,
                  width: 40,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 28,
                  width: 40,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant.withOpacity(0.2),
            ),
          ],
        ),
      ),
    );
  }
}
