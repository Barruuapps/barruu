import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Enum for media source options
enum MediaSource { url, file, camera }

/// Dialog for selecting media source (URL, file picker, or camera/microphone)
class MediaSourceDialog {
  static Future<MediaSource?> show(
    BuildContext context, {
    required String title,
    bool showCameraOption = true,
    String? cameraLabel,
  }) async {
    return showModalBottomSheet<MediaSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MediaSourceSheet(
        title: title,
        showCameraOption: showCameraOption,
        cameraLabel: cameraLabel,
      ),
    );
  }
}

class _MediaSourceSheet extends StatelessWidget {
  final String title;
  final bool showCameraOption;
  final String? cameraLabel;

  const _MediaSourceSheet({
    required this.title,
    required this.showCameraOption,
    this.cameraLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Media options in horizontal row
            Row(
              children: [
                // URL option
                Expanded(
                  child: _MediaSourceOption(
                    icon: IconsaxPlusLinear.link,
                    title: 'URL',
                    onTap: () => Navigator.pop(context, MediaSource.url),
                  ),
                ),
                const SizedBox(width: 12),

                // File picker option
                Expanded(
                  child: _MediaSourceOption(
                    icon: IconsaxPlusLinear.import,
                    title: 'local',
                    onTap: () => Navigator.pop(context, MediaSource.file),
                  ),
                ),

                if (showCameraOption) ...[
                  const SizedBox(width: 12),

                  // Camera/Microphone option
                  Expanded(
                    child: _MediaSourceOption(
                      icon: IconsaxPlusLinear.camera,
                      title: cameraLabel ?? 'Capture new',
                      onTap: () => Navigator.pop(context, MediaSource.camera),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Cancel button
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaSourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MediaSourceOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
