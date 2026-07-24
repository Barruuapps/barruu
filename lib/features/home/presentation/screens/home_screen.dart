import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:barruu/core/constants/design_tokens.dart';
import 'package:barruu/core/widgets/sidebar_nav.dart';
import 'package:barruu/core/widgets/premium_empty_state.dart';
import 'package:barruu/core/widgets/skeleton_loaders.dart';
import 'package:barruu/features/workspace/presentation/controllers/documents_controller.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/features/workspace/presentation/widgets/workspace/document_card.dart';
import 'package:barruu/features/workspace/presentation/widgets/workspace/cover_image_widget.dart';
/// Adaptive home — desktop sidebar+dashboard, mobile phone-grid.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= DesignTokens.breakpointMD) {
        return const _DesktopShell();
      }
      return const _Dashboard();
    });
  }
}

// ─── Desktop layout ─────────────────────────────────────────────────────

class _DesktopShell extends ConsumerWidget {
  const _DesktopShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Row(children: [
        const _Sidebar(),
        VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
        const Expanded(child: _Dashboard()),
      ]),
    );
  }
}

// ─── Sidebar ────────────────────────────────────────────────────────────

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final path = router.routerDelegate.currentConfiguration.uri.path;

    return SidebarShell(
      workspaceName: 'Barruu',
      children: [
        _nav(IconsaxPlusLinear.home, 'Home', path == '/', () => router.go('/')),
        _nav(IconsaxPlusLinear.document_text, 'Workspace', path.startsWith('/workspace'), () => router.go('/workspace')),
        _nav(IconsaxPlusLinear.add, 'New Document', false, () => router.push('/create-document')),
        const SizedBox(height: DesignTokens.spacing8),
        SidebarSection(title: 'EXPLORE', children: [
          _nav(IconsaxPlusLinear.calendar, 'Calendar', false, () => router.push('/calendar')),
          _nav(IconsaxPlusLinear.profile_2user, 'Profile', false, () {}),
        ]),
        const SizedBox(height: DesignTokens.spacing8),
        SidebarSection(title: 'PERSONAL', children: [
          _nav(IconsaxPlusLinear.clock, 'Recent', false, () => router.go('/workspace')),
          _nav(IconsaxPlusLinear.star, 'Favorites', false, () {}),
          _nav(IconsaxPlusLinear.trash, 'Trash', false, () {}),
        ]),
        _nav(IconsaxPlusLinear.color_swatch, 'Theme', false, () => router.push('/theme-selection')),
        _nav(IconsaxPlusLinear.setting_2, 'Settings', false, () => router.push('/settings')),
        const SizedBox(height: DesignTokens.spacing8),
      ],
    );
  }

  Widget _nav(IconData icon, String label, bool active, VoidCallback tap) {
    return SidebarNavItem(icon: icon, label: label, isActive: active, onTap: tap);
  }
}

// ─── Dashboard ──────────────────────────────────────────────────────────

class _Dashboard extends ConsumerWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final tt = t.textTheme;
    final cs = t.colorScheme;
    final router = GoRouter.of(context);
    final docsState = ref.watch(documentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spacing40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DesignTokens.contentWideMaxWidth),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome back 👋', style: tt.headlineMedium?.copyWith(fontWeight: DesignTokens.weightExtraBold, color: cs.onSurface)),
            const SizedBox(height: DesignTokens.spacing8),
            Text('Barruu — your offline-first document editor', style: tt.bodyLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: DesignTokens.spacing40),
            _sectionHeading(t, 'Quick Actions'),
            const SizedBox(height: DesignTokens.spacing16),
            Wrap(spacing: 16, runSpacing: 16, children: [
              _quickCard(context, IconsaxPlusLinear.document_text, 'New Document', 'Create a blank document', () => router.push('/create-document')),
              _quickCard(context, IconsaxPlusLinear.folder_2, 'Workspace', 'View all documents', () => router.go('/workspace')),
              _quickCard(context, IconsaxPlusLinear.import, 'Import', 'Import .bipy files', () => router.go('/workspace')),
              _quickCard(context, IconsaxPlusLinear.color_swatch, 'Theme', 'Customize appearance', () => router.push('/theme-selection')),
              _quickCard(context, IconsaxPlusLinear.setting_2, 'Settings', 'Preferences', () => router.push('/settings')),
            ]),
            const SizedBox(height: DesignTokens.spacing48),

            // Recent documents
            docsState.when(
              loading: () => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionHeading(t, 'Recent Documents'),
                const SizedBox(height: DesignTokens.spacing16),
                const SkeletonDocumentGrid(itemCount: 4, crossAxisCount: 4),
              ]),
              error: (_, __) => _sectionHeading(t, 'Recent Documents'),
              data: (docs) {
                if (docs.isEmpty) {
                  return PremiumEmptyState.noDocuments(onCreate: () => router.push('/create-document'));
                }
                final recent = docs.take(4).toList();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: _sectionHeading(t, 'Recent Documents')),
                    TextButton(onPressed: () => router.go('/workspace'), child: const Text('View all')),
                  ]),
                  const SizedBox(height: DesignTokens.spacing16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 16, mainAxisSpacing: 16),
                    itemCount: recent.length,
                    itemBuilder: (_, i) {
                      final doc = recent[i];
                      final meta = ref.read(documentsProvider.notifier).getCachedMeta(doc) ?? {};
                      return WorkspaceDocumentCard(
                        doc: doc, meta: meta,
                        buildCoverImage: (c, t) => CoverImageWidget(coverImageUrl: c, theme: t),
                        buildPopupMenuButton: (_) => const SizedBox.shrink(),
                        onShowSnackBar: (_) {},
                        onReloadDocuments: () => ref.read(documentsProvider.notifier).loadDocuments(),
                      );
                    },
                  ),
                ]);
              },
            ),

            const SizedBox(height: DesignTokens.spacing40),
            // Tips
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacing24),
              decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.primary.withValues(alpha: 0.15))),
              child: Row(children: [
                Icon(IconsaxPlusLinear.info_circle, size: 28, color: cs.primary),
                const SizedBox(width: 16),
                Expanded(child: Text('Press Ctrl+K for the command palette — search, navigate, create.', style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────

Widget _sectionHeading(ThemeData t, String title) {
  return Text(title, style: t.textTheme.titleMedium?.copyWith(fontWeight: DesignTokens.weightSemiBold, color: t.colorScheme.onSurface));
}

Widget _quickCard(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
  return _HoverCard(
    width: 220,
    padding: const EdgeInsets.all(20),
    onTap: onTap,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)),
        child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      ),
      const SizedBox(height: 16),
      Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: DesignTokens.weightSemiBold, color: Theme.of(context).colorScheme.onSurface)),
      const SizedBox(height: 4),
      Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]),
  );
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final double width;
  final EdgeInsetsGeometry padding;
  final VoidCallback onTap;
  const _HoverCard({required this.child, required this.width, required this.padding, required this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesignTokens.durationHover,
          width: widget.width,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: _hover ? t.colorScheme.surfaceContainerHigh : t.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXLarge),
            border: Border.all(color: _hover ? t.colorScheme.outline : t.colorScheme.outlineVariant),
            boxShadow: _hover ? [BoxShadow(color: t.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}