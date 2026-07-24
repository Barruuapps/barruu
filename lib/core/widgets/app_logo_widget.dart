import 'package:flutter/material.dart';

/// Reusable app logo widget with consistent styling
/// Displays the app logo from assets with circular shape and proper styling
class AppLogoWidget extends StatelessWidget {
  /// Size of the logo (width and height)
  final double size;

  /// Fallback icon to show if image fails to load
  final IconData fallbackIcon;

  /// Opacity of the shadow effect
  final double shadowOpacity;

  /// Blur radius of the shadow
  final double shadowBlur;

  /// Spread radius of the shadow
  final double shadowSpread;

  const AppLogoWidget({
    super.key,
    this.size = 100,
    this.fallbackIcon = Icons.library_books,
    this.shadowOpacity = 0.2,
    this.shadowBlur = 15,
    this.shadowSpread = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: shadowOpacity),
            blurRadius: shadowBlur,
            spreadRadius: 0, // Keep shadow circular
            offset: const Offset(0, 4), // Slight offset for depth
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: ClipOval(
          child: Image.asset(
            'assets/images/app_logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image fails to load
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primaryContainer,
                ),
                child: Icon(
                  fallbackIcon,
                  size: size * 0.6,
                  color: theme.colorScheme.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
