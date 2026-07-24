import 'dart:io';
import 'package:barruu/core/models/user_profile.dart';
import 'package:barruu/core/services/user_service.dart';
import 'package:barruu/features/auth/providers/local_auth_provider.dart';
import 'package:barruu/core/utils/ui_utils.dart';
import 'package:barruu/core/constants/user_constants.dart';
import 'package:barruu/core/widgets/profession_selector.dart';
import 'package:barruu/core/widgets/interests_selector.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/features/profile/widgets/avatar_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Screen for editing user profile information
///
/// Features:
/// - Avatar upload with R2 storage integration
/// - Profile information editing (name, bio, etc.)
/// - Real-time validation
/// - Loading and error states
/// - Integration with Firestore UserService
class EditProfileScreen extends ConsumerStatefulWidget {
  /// Current user profile to edit
  final UserProfile profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _professionalTitleController;
  late TextEditingController _organizationController;
  late TextEditingController _websiteController;

  final _formKey = GlobalKey<FormState>();

  String? _uploadedAvatarUrl;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;

  // New fields for profession and interests
  String? _selectedProfession;
  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current profile data
    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _professionalTitleController = TextEditingController(
      text: widget.profile.professionalTitle ?? '',
    );
    _organizationController = TextEditingController(
      text: widget.profile.organization ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.profile.websiteUrl ?? '',
    );

    _uploadedAvatarUrl = widget.profile.avatarUrl;
    _selectedProfession = widget.profile.profession;
    _selectedInterests = List.from(widget.profile.interests);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _professionalTitleController.dispose();
    _organizationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isLoading
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Avatar section
                _buildAvatarSection(theme),

                _buildSectionHeader(
                  theme,
                  'Personal Info',
                  IconsaxPlusLinear.user,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _displayNameController,
                        label: 'Display Name',
                        icon: IconsaxPlusLinear.user,
                        hint: 'Your name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Display name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: IconsaxPlusLinear.user_tag,
                        hint: '@username',
                        prefix: '@',
                        enabled: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Username is required';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                            return 'Username can only contain letters, numbers, and underscores';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _bioController,
                        label: 'Bio',
                        icon: IconsaxPlusLinear.message_text,
                        hint: 'Tell us about yourself',
                        maxLines: 4,
                        maxLength: 500,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Professional Info section
                _buildSectionHeader(
                  theme,
                  'Professional Info',
                  IconsaxPlusLinear.briefcase,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _professionalTitleController,
                        label: 'Professional Title',
                        icon: IconsaxPlusLinear.briefcase,
                        hint: 'Software Engineer, Designer, etc.',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _organizationController,
                        label: 'Organization',
                        icon: IconsaxPlusLinear.building,
                        hint: 'Company or organization',
                      ),
                      const SizedBox(height: 4),

                      // Profession selector (professional accounts only)
                      if (widget.profile.accountType ==
                          AccountType.professional) ...[
                        const SizedBox(height: 12),
                        ProfessionSelector(
                          selectedProfession: _selectedProfession,
                          onProfessionSelected: (profession) {
                            setState(() {
                              _selectedProfession = profession;
                            });
                          },
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Social Links section
                _buildSectionHeader(
                  theme,
                  'Social Links',
                  IconsaxPlusLinear.link,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _websiteController,
                        label: 'Website',
                        icon: IconsaxPlusLinear.link,
                        hint: 'https://yourwebsite.com',
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final urlPattern = RegExp(
                              r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
                            );
                            if (!urlPattern.hasMatch(value)) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Interests section
                _buildSectionHeader(
                  theme,
                  'Interests',
                  IconsaxPlusLinear.category,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      InterestsSelector(
                        selectedInterests: _selectedInterests,
                        onInterestsChanged: (interests) {
                          setState(() {
                            _selectedInterests = interests;
                          });
                        },
                        compact: true,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: ShimmerCircularProgress(size: 48)),
            ),
        ],
      ),
    );
  }

  /// Avatar section
  Widget _buildAvatarSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: AvatarPicker(
          currentAvatarUrl: _uploadedAvatarUrl,
          onImageSelected: _handleAvatarSelected,
          radius: 52,
          isLoading: _isUploadingAvatar,
        ),
      ),
    );
  }

  /// Section header label
  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefix,
    int maxLines = 1,
    int? maxLength,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textCapitalization: maxLines > 1
          ? TextCapitalization.sentences
          : TextCapitalization.words,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        prefixIcon: Icon(icon, size: 20),
        counterText: maxLength != null ? null : '',
      ),
    );
  }

  Future<void> _handleAvatarSelected(File imageFile) async {
    // Store the avatar locally (local-first mode - no cloud storage)
    setState(() {
      _uploadedAvatarUrl = imageFile.path;
      _isUploadingAvatar = false;
    });

    if (mounted) {
      UIUtils.showSnackBar(context, 'Avatar updated');
    }
  }

  Future<void> _saveProfile() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate interests
    if (_selectedInterests.length < InterestsSelector.defaultMinSelection) {
      UIUtils.showSnackBar(
        context,
        'Please select at least ${InterestsSelector.defaultMinSelection} interests',
        isError: true,
      );
      return;
    }

    // Validate profession for professional accounts
    if (widget.profile.accountType == AccountType.professional &&
        _selectedProfession == null) {
      UIUtils.showSnackBar(
        context,
        'Please select your profession',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated profile
      final updatedProfile = widget.profile.copyWith(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        avatarUrl: _uploadedAvatarUrl,
        professionalTitle: _professionalTitleController.text.trim().isEmpty
            ? null
            : _professionalTitleController.text.trim(),
        organization: _organizationController.text.trim().isEmpty
            ? null
            : _organizationController.text.trim(),
        websiteUrl: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        profession: _selectedProfession,
        interests: _selectedInterests,
      );

      // Update profile in Firestore
      final userService = ref.read(userServiceProvider);
      final result = await userService.updateProfile(updatedProfile);

      if (!result.isSuccess) {
        if (mounted) {
          UIUtils.showSnackBar(
            context,
            'Failed to update profile: ${result.when(success: (_) => 'Unknown error', error: (msg) => msg)}',
            isError: true,
          );
        }
        return;
      }

      // Refresh auth state to update UI
      await ref.read(authStateProvider.notifier).refresh();

      if (mounted) {
        UIUtils.showSnackBar(context, 'Profile updated successfully!');
        Navigator.pop(context, updatedProfile);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showSnackBar(
          context,
          'Failed to save profile: ${e.toString()}',
          isError: true,
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
}
