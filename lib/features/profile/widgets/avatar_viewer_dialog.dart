import 'package:flutter/material.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Instagram-style avatar viewer dialog
/// Shows the profile picture in a full-screen modal with zoom functionality
class AvatarViewerDialog extends StatelessWidget {
  final String? avatarUrl;
  final String displayName;
  final String? heroTag;

  const AvatarViewerDialog({
    super.key,
    required this.avatarUrl,
    required this.displayName,
    this.heroTag,
  });

  /// Shows the avatar viewer dialog
  static void show(
    BuildContext context, {
    required String? avatarUrl,
    required String displayName,
    String? heroTag,
  }) {
    if (avatarUrl == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AvatarViewerDialog(
        avatarUrl: avatarUrl,
        displayName: displayName,
        heroTag: heroTag,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Dismiss on tap anywhere
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // Centered avatar with interactive viewer for zoom
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display name
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Avatar with zoom capability
                InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: heroTag != null
                      ? Hero(
                          tag: heroTag!,
                          child: _buildAvatarImage(),
                        )
                      : _buildAvatarImage(),
                ),
                const SizedBox(height: 24),
                
                // Hint text
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        IconsaxPlusLinear.search_zoom_in,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pinch to zoom',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: 300,
                height: 300,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 300,
                  height: 300,
                  color: Colors.grey[800],
                  child: Center(
                    child: ShimmerCircularProgress(
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 300,
                  height: 300,
                  color: Colors.grey[800],
                  child: Icon(
                    IconsaxPlusLinear.user,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              )
            : Container(
                width: 300,
                height: 300,
                color: Colors.grey[800],
                child: Icon(
                  IconsaxPlusLinear.user,
                  size: 120,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
      ),
    );
  }
}
