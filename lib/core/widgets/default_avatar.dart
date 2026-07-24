import 'package:flutter/material.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'dart:math' as math;

/// Generates a default avatar with user initials when no avatar image is available
///
/// Features:
/// - Displays user initials (up to 2 characters)
/// - Consistent color generation based on user ID
/// - Customizable size and styling
/// - Fallback icon if no name is provided
class DefaultAvatar extends StatelessWidget {
  /// User's display name (used to generate initials)
  final String? displayName;

  /// Unique user ID (used for consistent color generation)
  final String userId;

  /// Avatar radius
  final double radius;

  /// Whether to show gradient ring (Instagram-style)
  final bool showGradientRing;

  const DefaultAvatar({
    super.key,
    this.displayName,
    required this.userId,
    this.radius = 50,
    this.showGradientRing = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = _generateColorFromUserId(userId, theme);
    final initials = _generateInitials(displayName);

    Widget avatarContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, backgroundColor.withValues(alpha: 0.8)],
        ),
      ),
      child: Center(
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.bold,
                  color: _getTextColor(backgroundColor),
                  letterSpacing: 1.5,
                ),
              )
            : Icon(
                Icons.person,
                size: radius,
                color: _getTextColor(backgroundColor),
              ),
      ),
    );

    if (!showGradientRing) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: avatarContent,
        ),
      );
    }

    // With gradient ring (Instagram-style)
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary,
          ],
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surface,
        ),
        padding: const EdgeInsets.all(3),
        child: ClipOval(child: avatarContent),
      ),
    );
  }

  /// Generate initials from display name (max 2 characters)
  String _generateInitials(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '';
    }

    final words = name.trim().split(RegExp(r'\s+'));

    if (words.length == 1) {
      // Single word: take first 2 characters
      return words[0].substring(0, math.min(2, words[0].length)).toUpperCase();
    } else {
      // Multiple words: take first character of first 2 words
      return (words[0][0] + words[1][0]).toUpperCase();
    }
  }

  /// Generate a consistent color based on user ID
  Color _generateColorFromUserId(String userId, ThemeData theme) {
    // Use hash code of userId to generate consistent color
    final hash = userId.hashCode;
    final hue = (hash % 360).toDouble();

    // Use HSL color space for vibrant colors
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }

  /// Determine text color (black or white) based on background brightness
  Color _getTextColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();

    // Return white for dark backgrounds, black for light backgrounds
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

/// Cached avatar widget that shows default avatar if URL is not available
/// or if image fails to load
class CachedAvatar extends StatelessWidget {
  /// Avatar image URL
  final String? avatarUrl;

  /// User's display name (for fallback initials)
  final String? displayName;

  /// Unique user ID (for fallback color generation)
  final String userId;

  /// Avatar radius
  final double radius;

  /// Whether to show gradient ring
  final bool showGradientRing;

  const CachedAvatar({
    super.key,
    this.avatarUrl,
    this.displayName,
    required this.userId,
    this.radius = 50,
    this.showGradientRing = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show default avatar if no URL
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return DefaultAvatar(
        displayName: displayName,
        userId: userId,
        radius: radius,
        showGradientRing: showGradientRing,
      );
    }

    // Try to load image from URL
    Widget avatarContent = Image.network(
      avatarUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return ShimmerLoading(
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Fall back to default avatar on error
        return DefaultAvatar(
          displayName: displayName,
          userId: userId,
          radius: radius,
          showGradientRing: false, // Don't double-wrap
        );
      },
    );

    if (!showGradientRing) {
      return ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: avatarContent,
        ),
      );
    }

    // With gradient ring (Instagram-style)
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary,
          ],
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surface,
        ),
        padding: const EdgeInsets.all(3),
        child: ClipOval(child: avatarContent),
      ),
    );
  }
}
