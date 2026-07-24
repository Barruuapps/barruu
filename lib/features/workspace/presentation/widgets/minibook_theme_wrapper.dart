import 'package:barruu/core/theme/app_theme.dart';
import 'package:barruu/core/theme/domain/providers/minibook_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wrapper widget that applies minibook theme for reading content.
///
/// This is used in DisplayDocument and PreviewDocument screens to allow users
/// to read content with their preferred minibook theme, separate from the
/// app's system theme (light/dark/system).
class MinibookThemeWrapper extends ConsumerWidget {
  final Widget child;

  const MinibookThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minibookThemeType = ref.watch(minibookThemeProvider);
    final minibookTheme = AppTheme.getTheme(minibookThemeType);

    return Theme(data: minibookTheme, child: child);
  }
}
