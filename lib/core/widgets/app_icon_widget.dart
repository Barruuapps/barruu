import 'package:cached_network_image/cached_network_image.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// A reusable app icon widget that handles network images with proper loading
/// and error states. Provides consistent styling across the app.
class AppIconWidget extends StatelessWidget {
  /// The URL of the icon image. If null or empty, shows the fallback icon.
  final String? iconUrl;

  /// The size of the icon container. Default is 64.
  final double size;

  /// The border radius of the icon. Default is 16.
  final double borderRadius;

  /// Optional fallback icon to show when image fails to load.
  /// Defaults to IconsaxPlusLinear.document_text.
  final IconData fallbackIcon;

  const AppIconWidget({
    super.key,
    required this.iconUrl,
    this.size = 64,
    this.borderRadius = 16,
    this.fallbackIcon = IconsaxPlusLinear.document_text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValidUrl = iconUrl != null && iconUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: hasValidUrl
            ? CachedNetworkImage(
                imageUrl: iconUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildLoadingWidget(theme),
                errorWidget: (context, url, error) => _buildFallbackIcon(theme),
              )
            : _buildFallbackIcon(theme),
      ),
    );
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    return Center(
      child: ShimmerCircularProgress(
        size: size * 0.4,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: size * 0.5,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// A circular avatar widget for user profile pictures with loading and error handling.
class UserAvatarWidget extends StatelessWidget {
  /// The URL of the avatar image. If null or empty, shows the fallback icon.
  final String? avatarUrl;

  /// The radius of the avatar. Default is 50.
  final double radius;

  /// Optional fallback icon. Defaults to IconsaxPlusLinear.user.
  final IconData fallbackIcon;

  const UserAvatarWidget({
    super.key,
    required this.avatarUrl,
    this.radius = 50,
    this.fallbackIcon = IconsaxPlusLinear.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValidUrl = avatarUrl != null && avatarUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: hasValidUrl
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildLoadingWidget(theme),
                errorWidget: (context, url, error) => _buildFallbackIcon(theme),
              ),
            )
          : _buildFallbackIcon(theme),
    );
  }

  Widget _buildLoadingWidget(ThemeData theme) {
    return Center(
      child: ShimmerCircularProgress(
        size: radius * 0.6,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Icon(fallbackIcon, size: radius, color: theme.colorScheme.primary);
  }
}
