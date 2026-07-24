import 'package:barruu/core/constants/user_constants.dart';
import 'package:barruu/core/models/user_profile.dart';
import 'package:barruu/features/auth/providers/local_auth_provider.dart';
import 'package:barruu/core/services/user_service.dart';
import 'package:barruu/core/services/follow_service.dart';
import 'package:barruu/core/widgets/default_avatar.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/features/profile/widgets/follow_button.dart';
import 'package:barruu/features/profile/widgets/avatar_viewer_dialog.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen to view another user's profile
///
/// Features:
/// - User profile header with avatar, bio, and stats
/// - Follow/unfollow button
/// - User's published posts grid
/// - Navigate to followers/following lists
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isCurrentUser = false;
  bool _isFollowing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      _isCurrentUser = authState.userId == widget.userId;

      // Load user profile
      final profileResult = await ref
          .read(userServiceProvider)
          .getProfile(widget.userId);
      profileResult.when(
        success: (profile) {
          if (mounted) {
            setState(() {
              _profile = profile;
            });
          }
        },
        error: (error) {
          if (mounted) {
            setState(() {
              _error = error;
            });
          }
        },
      );

      // Load follow status if not current user
      if (!_isCurrentUser && authState.userId.isNotEmpty) {
        try {
          final isFollowing = await ref
              .read(followServiceProvider)
              .isFollowingUser(authState.userId, widget.userId);
          if (mounted) {
            setState(() {
              _isFollowing = isFollowing;
            });
          }
        } catch (e) {
          // Ignore follow status errors
          logger.w('Failed to load follow status: $e');
        }
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

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
        ),
        body: _buildShimmerLoading(context),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load profile', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
        ),
        body: const Center(child: Text('Profile not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: true,
            title: Text(
              profile.username,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(IconsaxPlusLinear.more),
                onPressed: () => _showOptionsMenu(context),
                tooltip: 'More options',
              ),
            ],
          ),

          // Profile Header
          SliverToBoxAdapter(
            child: _buildProfileHeader(context, theme, profile),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    ThemeData theme,
    UserProfile profile,
  ) {
    const double bannerHeight = 120.0;
    const double avatarRadius = 48.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cover banner with avatar overlapping at bottom
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Cover banner
            _buildCoverBanner(context, theme, profile, bannerHeight),

            // Avatar overlapping the banner
            Positioned(
              bottom: -(avatarRadius + 4),
              child: _buildProfileAvatar(context, theme, profile, avatarRadius),
            ),
          ],
        ),

        SizedBox(height: avatarRadius + 16),

        // Display Name + Verified Badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  profile.displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.verified_rounded,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Username
        Text(
          '@${profile.username}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        // Account type badge + Professional Title + Organization
        if (profile.accountType != AccountType.regular ||
            (profile.professionalTitle != null &&
                profile.professionalTitle!.isNotEmpty) ||
            (profile.organization != null &&
                profile.organization!.isNotEmpty)) ...[
          const SizedBox(height: 10),
          _buildProfessionalInfo(context, theme, profile),
        ],

        // Bio
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              profile.bio!,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        // Website link
        if (profile.websiteUrl != null && profile.websiteUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildWebsiteLink(context, theme, profile.websiteUrl!),
        ],

        const SizedBox(height: 20),

        // Stats row
        _buildStatsRow(context, theme, profile),

        const SizedBox(height: 16),

        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildActionButtons(context, theme, profile),
        ),

        // Interests chips
        if (profile.interests.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildInterestsChips(context, theme, profile.interests),
        ],

        const SizedBox(height: 8),
      ],
    );
  }

  /// Gradient cover banner
  Widget _buildCoverBanner(
    BuildContext context,
    ThemeData theme,
    UserProfile profile,
    double height,
  ) {
    if (profile.coverImageUrl != null && profile.coverImageUrl!.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: CachedNetworkImage(
          imageUrl: profile.coverImageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildGradientBanner(theme, height),
          errorWidget: (context, url, error) =>
              _buildGradientBanner(theme, height),
        ),
      );
    }
    return _buildGradientBanner(theme, height);
  }

  Widget _buildGradientBanner(ThemeData theme, double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
            theme.colorScheme.tertiary.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }

  /// Avatar with gradient ring
  Widget _buildProfileAvatar(
    BuildContext context,
    ThemeData theme,
    UserProfile profile,
    double radius,
  ) {
    return Hero(
      tag: 'profile_avatar_${profile.uid}',
      child: GestureDetector(
        onTap: () {
          if (profile.avatarUrl != null) {
            AvatarViewerDialog.show(
              context,
              avatarUrl: profile.avatarUrl,
              displayName: profile.displayName,
              heroTag: 'profile_avatar_${profile.uid}',
            );
          }
        },
        child: Container(
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
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
            ),
            padding: const EdgeInsets.all(3),
            child: profile.avatarUrl != null
                ? CircleAvatar(
                    radius: radius,
                    backgroundImage: CachedNetworkImageProvider(
                      profile.avatarUrl!,
                    ),
                  )
                : DefaultAvatar(
                    userId: profile.uid,
                    displayName: profile.displayName,
                    radius: radius,
                  ),
          ),
        ),
      ),
    );
  }

  /// Professional title, organization, and account type badge
  Widget _buildProfessionalInfo(
    BuildContext context,
    ThemeData theme,
    UserProfile profile,
  ) {
    final isProfessional = profile.accountType == AccountType.professional;
    final isOrganization = profile.accountType == AccountType.organization;

    return Column(
      children: [
        // Account type badge
        if (isProfessional || isOrganization)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOrganization
                      ? IconsaxPlusLinear.buildings
                      : IconsaxPlusLinear.briefcase,
                  size: 13,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 5),
                Text(
                  isOrganization ? 'Organization' : 'Professional',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Professional title
        if (profile.professionalTitle != null &&
            profile.professionalTitle!.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                IconsaxPlusLinear.briefcase,
                size: 13,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  profile.professionalTitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

        // Organization
        if (profile.organization != null &&
            profile.organization!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                IconsaxPlusLinear.buildings,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  profile.organization!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Clickable website link
  Widget _buildWebsiteLink(BuildContext context, ThemeData theme, String url) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Unable to open link'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            IconsaxPlusLinear.link,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            url.replaceAll(RegExp(r'^https?://'), ''),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
              decorationColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Stats row (published apps count)
  Widget _buildStatsRow(
    BuildContext context,
    ThemeData theme,
    UserProfile profile,
  ) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [],
      ),
    );
  }

  /// Action buttons (edit profile / follow + share)
  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    UserProfile profile,
  ) {
    if (_isCurrentUser) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.tonal(
              onPressed: () => context.push('/edit-profile', extra: profile),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconsaxPlusLinear.edit, size: 16, semanticLabel: 'Edit'),
                  const SizedBox(width: 6),
                  Text(
                    'Edit Profile',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _handleShareProfile,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Icon(
              IconsaxPlusLinear.share,
              size: 18,
              semanticLabel: 'Share profile',
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: FollowButton(
              userId: profile.uid,
              isFollowing: _isFollowing,
              size: FollowButtonSize.large,
              fullWidth: true,
              onFollowChanged: _loadProfile,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _handleShareProfile,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Icon(
              IconsaxPlusLinear.share,
              size: 18,
              semanticLabel: 'Share profile',
            ),
          ),
        ],
      );
    }
  }

  /// Interests chips
  Widget _buildInterestsChips(
    BuildContext context,
    ThemeData theme,
    List<String> interests,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: interests.map((interest) {
          return Chip(
            label: Text(
              interest,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: theme.colorScheme.secondaryContainer.withValues(
              alpha: 0.7,
            ),
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    ThemeData theme,
    String count,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle at the top for visual feedback
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  IconsaxPlusLinear.share,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Share Profile'),
                onTap: () {
                  Navigator.pop(context);
                  _handleShareProfile();
                },
              ),
              if (!_isCurrentUser) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    IconsaxPlusLinear.warning_2,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Report User',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleReportUser();
                  },
                ),
                ListTile(
                  leading: Icon(
                    IconsaxPlusLinear.close_circle,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Block User',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleBlockUser();
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: ShimmerLoading(
        child: Column(
          children: [
            // Cover banner shimmer
            Container(
              width: double.infinity,
              height: 120,
              color: theme.colorScheme.surfaceContainerHighest,
            ),

            // Avatar shimmer (overlapping)
            Transform.translate(
              offset: const Offset(0, -48),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 4,
                  ),
                ),
              ),
            ),

            // Name + username shimmer
            Transform.translate(
              offset: const Offset(0, -36),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      width: 180,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats row shimmer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 40),
                        Container(
                          width: 60,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 40),
                        Container(
                          width: 60,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Button shimmer
                    Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
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

  /// Share user profile using the system share sheet
  void _handleShareProfile() {
    final profile = _profile;
    if (profile == null) return;

    // Build bio section only if bio exists and is not empty
    final bioSection = profile.bio?.isNotEmpty == true
        ? '\n${profile.bio}\n'
        : '';

    final shareText =
        '''
Check out ${profile.displayName}'s profile on ${AppConstants.appName}!

@${profile.username}$bioSection
View profile: ${AppConstants.webBaseUrl}/@${profile.username}
    '''
            .trim();

    Share.share(
      shareText,
      subject: '${profile.displayName} on ${AppConstants.appName}',
    );

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile shared successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Report user for inappropriate behavior
  Future<void> _handleReportUser() async {
    final profile = _profile;
    if (profile == null) return;

    final theme = Theme.of(context);

    // Show report reasons dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Why are you reporting @${profile.username}?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildReportOption(context, 'Spam or misleading', 'spam'),
            _buildReportOption(
              context,
              'Harassment or hate speech',
              'harassment',
            ),
            _buildReportOption(
              context,
              'Violence or dangerous content',
              'violence',
            ),
            _buildReportOption(
              context,
              'Inappropriate content',
              'inappropriate',
            ),
            _buildReportOption(context, 'False information', 'false_info'),
            _buildReportOption(context, 'Other', 'other'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (reason != null && mounted) {
      // TODO: Implement actual report submission to backend
      // For now, just show a confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Thank you for your report. We will review it shortly.',
          ),
          backgroundColor: theme.colorScheme.primary,
          duration: const Duration(seconds: 3),
        ),
      );

      logger.i('User reported: ${profile.uid} for reason: $reason');
    }
  }

  Widget _buildReportOption(BuildContext context, String text, String value) {
    return ListTile(
      title: Text(text),
      onTap: () => Navigator.pop(context, value),
      dense: true,
    );
  }

  /// Block user and prevent them from seeing your content
  Future<void> _handleBlockUser() async {
    final profile = _profile;
    if (profile == null) return;

    final theme = Theme.of(context);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Block @${profile.username}?',
          style: TextStyle(color: theme.colorScheme.error),
        ),
        content: Text(
          'They won\'t be able to:\n'
          '• See your profile\n'
          '• Follow you\n'
          '• Contact you on ${AppConstants.appName}\n\n'
          'They won\'t be notified that you blocked them.',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Implement actual block functionality with backend
      // For now, just show a confirmation and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You blocked @${profile.username}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // TODO: Implement unblock
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Block removed'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      logger.i('User blocked: ${profile.uid}');

      // Navigate back to previous screen
      if (context.mounted) {
        context.pop();
      }
    }
  }

}
