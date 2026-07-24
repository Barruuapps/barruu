import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/core/services/follow_service.dart';
import 'package:barruu/features/workspace/data/sources/user_identity_service.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// A reusable follow/unfollow button widget
///
/// Features:
/// - Displays follow/unfollow state
/// - Handles follow/unfollow actions
/// - Loading states during actions
/// - Error feedback via snackbars
/// - Customizable styling
class FollowButton extends ConsumerStatefulWidget {
  /// User ID to follow/unfollow
  final String userId;

  /// Current follow status
  final bool isFollowing;

  /// Callback when follow status changes
  final VoidCallback? onFollowChanged;

  /// Button size (default, small, large)
  final FollowButtonSize size;

  /// Whether to show icon
  final bool showIcon;

  /// Whether the button should fill available width
  final bool fullWidth;

  const FollowButton({
    super.key,
    required this.userId,
    required this.isFollowing,
    this.onFollowChanged,
    this.size = FollowButtonSize.medium,
    this.showIcon = true,
    this.fullWidth = false,
  });

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _isLoading = false;
  late bool _isFollowing;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.isFollowing;
  }

  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFollowing != widget.isFollowing) {
      setState(() {
        _isFollowing = widget.isFollowing;
      });
    }
  }

  Future<void> _handleFollowToggle() async {
    if (_isLoading) return;

    final followService = ref.read(followServiceProvider);
    final userId = await ref.read(userIdentityServiceProvider).getUserId();

    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not retrieve user identity'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isFollowing) {
        // Unfollow
        final result = await followService.unfollowUser(
          userId,
          widget.userId,
        );

        result.when(
          success: (_) {
            setState(() {
              _isFollowing = false;
            });
            widget.onFollowChanged?.call();
          },
          error: (message) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      } else {
        // Follow
        final result = await followService.followUser(
          followerId: userId,
          followingId: widget.userId,
        );

        result.when(
          success: (_) {
            setState(() {
              _isFollowing = true;
            });
            widget.onFollowChanged?.call();
          },
          error: (message) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Button dimensions based on size
    final buttonHeight = switch (widget.size) {
      FollowButtonSize.small => 32.0,
      FollowButtonSize.medium => 40.0,
      FollowButtonSize.large => 48.0,
    };

    final buttonPadding = switch (widget.size) {
      FollowButtonSize.small => const EdgeInsets.symmetric(horizontal: 12),
      FollowButtonSize.medium => const EdgeInsets.symmetric(horizontal: 16),
      FollowButtonSize.large => const EdgeInsets.symmetric(horizontal: 20),
    };

    final fontSize = switch (widget.size) {
      FollowButtonSize.small => 12.0,
      FollowButtonSize.medium => 14.0,
      FollowButtonSize.large => 16.0,
    };

    final iconSize = switch (widget.size) {
      FollowButtonSize.small => 14.0,
      FollowButtonSize.medium => 16.0,
      FollowButtonSize.large => 18.0,
    };

    // Button style based on follow status
    final backgroundColor = _isFollowing
        ? colorScheme.surfaceContainerHighest
        : colorScheme.primary;

    final foregroundColor = _isFollowing
        ? colorScheme.onSurface
        : colorScheme.onPrimary;

    final buttonText = _isFollowing ? 'Following' : 'Follow';
    final buttonIcon = _isFollowing ? IconsaxPlusLinear.tick_circle : IconsaxPlusLinear.user_add;

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleFollowToggle,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: buttonPadding,
          elevation: _isFollowing ? 0 : 2,
          shadowColor: colorScheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: _isFollowing
                ? BorderSide(color: colorScheme.outline.withValues(alpha: 0.5))
                : BorderSide.none,
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: ShimmerInlineLoading(
                  size: iconSize,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.showIcon) ...[
                    Icon(
                      buttonIcon,
                      size: iconSize,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );

    return SizedBox(
      height: buttonHeight,
      width: widget.fullWidth ? double.infinity : null,
      child: button,
    );
  }
}

/// Follow button size variants
enum FollowButtonSize {
  small,
  medium,
  large,
}
