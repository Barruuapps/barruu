import 'package:barruu/features/auth/providers/local_auth_provider.dart';
import 'package:barruu/core/theme/domain/models/app_theme_mode.dart';
import 'package:barruu/core/theme/domain/providers/app_theme_mode_provider.dart';
import 'package:barruu/features/workspace/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Clean, card-based settings screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDeletingAccount = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appThemeMode = ref.watch(appThemeModeProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Appearance
          _sectionLabel(theme, 'Appearance'),
          _card(theme, [
            _tileNav(
              theme,
              icon: IconsaxPlusLinear.sun_1,
              title: 'Theme',
              trailing: Text(
                appThemeMode.displayName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              onTap: () => _showThemeSheet(context, ref, appThemeMode),
            ),
            _divider(theme),
            _tileNav(
              theme,
              icon: IconsaxPlusLinear.color_swatch,
              title: 'Reader Themes',
              onTap: () => context.push('/theme-selection'),
            ),
          ]),

          const SizedBox(height: 20),

          // Privacy & Security
          _sectionLabel(theme, 'Privacy & Security'),
          _card(theme, [
            _tileNav(
              theme,
              icon: IconsaxPlusLinear.lock,
              title: 'Privacy',
              onTap: () => _comingSoon('Privacy Settings'),
            ),
            _divider(theme),
            _tileNav(
              theme,
              icon: IconsaxPlusLinear.shield_security,
              title: 'Security',
              onTap: () => _comingSoon('Security Settings'),
            ),
            _divider(theme),
            _tileNav(
              theme,
              icon: IconsaxPlusLinear.user_remove,
              title: 'Blocked Users',
              onTap: () => _comingSoon('Blocked Users'),
            ),
          ]),

          const SizedBox(height: 20),

          // Notifications
          _sectionLabel(theme, 'Notifications'),
          _card(theme, [
            _tileNav(
              theme,
              icon: IconsaxPlusLinear.notification,
              title: 'Push Notifications',
              onTap: () => _comingSoon('Push Notifications'),
            ),
            _divider(theme),
            _tileNav(
              theme,
              icon: IconsaxPlusLinear.sms,
              title: 'Email Notifications',
              onTap: () => _comingSoon('Email Notifications'),
            ),
          ]),

          const SizedBox(height: 20),

          // Subscription
          _sectionLabel(theme, 'Subscription'),
          _card(theme, [
            _tileNav(
              theme,
              icon: IconsaxPlusLinear.crown_1,
              title: 'Manage Subscription',
              onTap: null,
            ),
          ]),

          const SizedBox(height: 20),

          // Storage
          _sectionLabel(theme, 'Storage'),
          _card(theme, [
            _tileAction(
              theme,
              icon: IconsaxPlusLinear.trash,
              title: 'Clear Cache',
              onTap: () => _clearCache(theme),
            ),
          ]),

          const SizedBox(height: 20),

          // About
          _sectionLabel(theme, 'About'),
          _card(theme, [
            _tileNav(
              theme,
              icon: IconsaxPlusLinear.info_circle,
              title: AppConstants.appName,
              onTap: () => context.push('/about'),
            ),
          ]),

          const SizedBox(height: 20),

          // Account actions
          _sectionLabel(theme, 'Account'),
          _card(theme, [
            _tileAction(
              theme,
              icon: IconsaxPlusLinear.logout,
              title: 'Log Out',
              isDestructive: true,
              onTap: () => _handleLogout(),
            ),
            _divider(theme),
            _tileAction(
              theme,
              icon: IconsaxPlusLinear.warning_2,
              title: 'Delete Account',
              isDestructive: true,
              isLoading: _isDeletingAccount,
              onTap: () => _showDeleteAccountDialog(theme),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Layout helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _card(ThemeData theme, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      color: theme.colorScheme.surface,
      child: Column(children: children),
    );
  }

  Widget _divider(ThemeData theme) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 0,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }

  Widget _tileNav(
    ThemeData theme, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      leading: Icon(icon, size: 22, color: theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing:
          trailing ??
          Icon(
            IconsaxPlusLinear.arrow_right_3,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
      onTap: onTap,
    );
  }

  Widget _tileAction(
    ThemeData theme, {
    required IconData icon,
    required String title,
    bool isDestructive = false,
    bool isLoading = false,
    VoidCallback? onTap,
  }) {
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return ListTile(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      leading: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 22, color: color),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(color: color),
      ),
      onTap: isLoading ? null : onTap,
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearCache(ThemeData theme) {
    final cache = PaintingBinding.instance.imageCache;
    cache.clear();
    cache.clearLiveImages();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cache cleared'),
        backgroundColor: theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showThemeSheet(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode current,
  ) async {
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Theme',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...AppThemeMode.values.map((mode) {
                final selected = mode == current;
                return ListTile(
                  leading: Icon(
                    _themeIcon(mode),
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                  title: Text(mode.displayName),
                  trailing: selected
                      ? Icon(
                          Icons.check_rounded,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref
                        .read(appThemeModeProvider.notifier)
                        .setThemeMode(mode);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  IconData _themeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return IconsaxPlusLinear.sun_1;
      case AppThemeMode.dark:
        return IconsaxPlusLinear.moon;
      case AppThemeMode.system:
        return IconsaxPlusLinear.mobile;
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await ref.read(authStateProvider.notifier).logout();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }

  Future<void> _showDeleteAccountDialog(ThemeData theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        content: const Text(
          'This will permanently delete your account and all your data. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    try {
      await ref.read(authStateProvider.notifier).deleteAccount();
      if (mounted) {
        setState(() => _isDeletingAccount = false);
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion failed: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }
}
