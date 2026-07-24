import 'dart:io';
import 'package:flutter/material.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// A reusable widget for picking and displaying avatar images
/// 
/// Features:
/// - Camera and gallery options
/// - Image preview with loading states
/// - Error handling with user feedback
/// - Customizable size and styling
class AvatarPicker extends StatefulWidget {
  /// Current avatar URL (if any)
  final String? currentAvatarUrl;
  
  /// Callback when an image is selected
  final Function(File imageFile) onImageSelected;
  
  /// Avatar radius (default: 60)
  final double radius;
  
  /// Whether to show the edit button
  final bool showEditButton;
  
  /// Loading state
  final bool isLoading;

  const AvatarPicker({
    super.key,
    this.currentAvatarUrl,
    required this.onImageSelected,
    this.radius = 60,
    this.showEditButton = true,
    this.isLoading = false,
  });

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        // Avatar display
        _buildAvatar(theme),
        
        // Edit button
        if (widget.showEditButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildEditButton(theme),
          ),
          
        // Loading overlay
        if (widget.isLoading)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: ShimmerCircularProgress(size: 40, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    final avatarRadius = widget.radius;
    
    return Container(
      width: avatarRadius * 2,
      height: avatarRadius * 2,
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
        child: ClipOval(
          child: _buildAvatarContent(theme),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(ThemeData theme) {
    // Show selected image if available
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
      );
    }
    
    // Show current avatar from URL
    if (widget.currentAvatarUrl != null && widget.currentAvatarUrl!.isNotEmpty) {
      return Image.network(
        widget.currentAvatarUrl!,
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
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(theme),
      );
    }
    
    // Show fallback icon
    return _buildFallbackIcon(theme);
  }

  Widget _buildFallbackIcon(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          IconsaxPlusLinear.user,
          size: widget.radius,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEditButton(ThemeData theme) {
    return Material(
      color: theme.colorScheme.primary,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: theme.colorScheme.primary.withOpacity(0.4),
      child: InkWell(
        onTap: widget.isLoading ? null : _showImageSourceDialog,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.surface,
              width: 3,
            ),
          ),
          child: Icon(
            IconsaxPlusLinear.camera,
            size: 18,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        IconsaxPlusLinear.gallery,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Choose Photo',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              
              // Camera option
              _ImageSourceOption(
                icon: IconsaxPlusLinear.camera,
                title: 'Take Photo',
                subtitle: 'Use camera to take a new photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              
              // Gallery option
              _ImageSourceOption(
                icon: IconsaxPlusLinear.gallery,
                title: 'Choose from Gallery',
                subtitle: 'Select from your photo library',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              
              // Remove option (if avatar exists)
              if (widget.currentAvatarUrl != null || _selectedImage != null)
                _ImageSourceOption(
                  icon: IconsaxPlusLinear.trash,
                  title: 'Remove Photo',
                  subtitle: 'Use default avatar',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(context);
                    _removeAvatar();
                  },
                ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (image == null) return;

      final file = File(image.path);
      
      setState(() {
        _selectedImage = file;
      });
      
      widget.onImageSelected(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _removeAvatar() {
    setState(() {
      _selectedImage = null;
    });
    // TODO: Implement avatar removal callback if needed
  }
}

/// Image source option item for bottom sheet
class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ImageSourceOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? theme.colorScheme.errorContainer.withOpacity(0.5)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? color : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              IconsaxPlusLinear.arrow_right_3,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
