import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:barruu/core/constants/design_tokens.dart';

/// Collection of premium skeleton loaders for Barruu.
///
/// These shimmer-based placeholders provide a polished loading experience
/// matching the quality of Notion, Linear, and other premium desktop apps.
///
/// Respects `MediaQuery.of(context).disableAnimations` for accessibility.

class _ShimmerWrapper extends StatelessWidget {
  final Widget child;
  const _ShimmerWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    if (disableAnimations) {
      return child;
    }

    return Shimmer.fromColors(
      baseColor: isDark
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      highlightColor: isDark
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45)
          : Colors.white.withValues(alpha: 0.85),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

BoxDecoration _placeholderBox(ThemeData theme) => BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
    );

// ============================================================================
// Dashboard / Workspace Grid Skeleton
// ============================================================================

/// A grid of shimmer cards matching the workspace document grid layout.
/// Use when the document list is loading.
class SkeletonDocumentGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double aspectRatio;

  const SkeletonDocumentGrid({
    super.key,
    this.itemCount = 8,
    this.crossAxisCount = 4,
    this.aspectRatio = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: DesignTokens.spacing16,
        mainAxisSpacing: DesignTokens.spacing16,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) =>
          const _SkeletonDocumentGridCard(),
    );
  }
}

class _SkeletonDocumentGridCard extends StatelessWidget {
  const _SkeletonDocumentGridCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ShimmerWrapper(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius:
              BorderRadius.circular(DesignTokens.radiusXLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(DesignTokens.radiusXLarge),
                  ),
                ),
              ),
            ),
            // Content placeholder
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Container(
                      height: 16,
                      decoration: _placeholderBox(theme),
                    ),
                    const SizedBox(height: DesignTokens.spacing8),
                    // Description
                    Container(
                      height: 12,
                      width: 80,
                      decoration: _placeholderBox(theme),
                    ),
                    const Spacer(),
                    // Date badge
                    Container(
                      height: 28,
                      width: 100,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                            DesignTokens.radiusSmall),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// List Item Skeleton (for sidebar, recent docs, search results)
// ============================================================================

/// A list of shimmer cards matching the document list layout.
class SkeletonDocumentList extends StatelessWidget {
  final int itemCount;

  const SkeletonDocumentList({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, __) =>
          const _SkeletonDocumentListItem(),
    );
  }
}

class _SkeletonDocumentListItem extends StatelessWidget {
  const _SkeletonDocumentListItem();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: DesignTokens.spacing12,
      ),
      child: _ShimmerWrapper(
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spacing12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius:
                BorderRadius.circular(DesignTokens.radiusLarge),
          ),
          child: Row(
            children: [
              // Cover image
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spacing12),
              // Title + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 15,
                      decoration: _placeholderBox(theme),
                    ),
                    const SizedBox(height: DesignTokens.spacing8),
                    Container(
                      height: 12,
                      width: 100,
                      decoration: _placeholderBox(theme),
                    ),
                  ],
                ),
              ),
              // Menu button placeholder
              const SizedBox(width: DesignTokens.spacing8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
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

// ============================================================================
// Sidebar Skeleton
// ============================================================================

/// Shimmer placeholder for the left sidebar navigation.
class SkeletonSidebar extends StatelessWidget {
  final int itemCount;

  const SkeletonSidebar({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacing12),
        child: Column(
          children: [
            // Logo / header
            Container(
              height: 32,
              margin: const EdgeInsets.only(
                bottom: DesignTokens.spacing24,
              ),
              decoration: _placeholderBox(theme),
            ),
            // Nav items
            ...List.generate(itemCount, (index) => Padding(
              padding: const EdgeInsets.only(
                bottom: DesignTokens.spacing8,
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusSmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing12),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: _placeholderBox(theme),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Create Document Page Skeleton
// ============================================================================

/// Full-page skeleton for the create document screen.
class SkeletonCreateDocument extends StatelessWidget {
  const SkeletonCreateDocument({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ShimmerWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover image placeholder
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(
                DesignTokens.radiusXLarge,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spacing24),
          // Title input
          Container(
            height: 52,
            decoration: _placeholderBox(theme),
          ),
          const SizedBox(height: DesignTokens.spacing16),
          // Description
          Container(
            height: 90,
            decoration: _placeholderBox(theme),
          ),
          const SizedBox(height: DesignTokens.spacing16),
          // Tags
          Container(
            height: 44,
            decoration: _placeholderBox(theme),
          ),
          const SizedBox(height: DesignTokens.spacing24),
          // Submit button
          Container(
            height: DesignTokens.buttonHeightLarge,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(
                DesignTokens.radiusLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}