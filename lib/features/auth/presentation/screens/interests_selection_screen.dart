import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barruu/core/constants/user_constants.dart';
import 'package:barruu/core/widgets/interests_selector.dart';
import 'package:barruu/core/widgets/shimmer_loading.dart';
import 'package:barruu/core/utils/ui_utils.dart';
import 'package:barruu/features/auth/providers/local_auth_provider.dart';

/// Interests selection screen shown after signup
/// Allows users to select their interests for personalized content
class InterestsSelectionScreen extends ConsumerStatefulWidget {
  /// User data passed from signup
  final String email;
  final String password;
  final String name;
  final String? username;

  const InterestsSelectionScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    this.username,
  });

  @override
  ConsumerState<InterestsSelectionScreen> createState() =>
      _InterestsSelectionScreenState();
}

class _InterestsSelectionScreenState
    extends ConsumerState<InterestsSelectionScreen> {
  List<String> _selectedInterests = [];
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;

  /// Register user with given interests
  Future<void> _registerUser(List<String> interests) async {
    setState(() {
      _isLoading = true;
    });

    final success = await ref
        .read(authStateProvider.notifier)
        .register(
          widget.email,
          widget.password,
          widget.name,
          username: widget.username,
          accountType: AccountType.regular,
          interests: interests,
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      UIUtils.showSnackBar(context, 'Welcome to Barruu!');
      context.go('/');
    } else {
      final error = ref.read(authStateProvider).error;
      UIUtils.showSnackBar(
        context,
        error ?? 'Unable to create account. Please try again.',
        isError: true,
      );
    }
  }

  Future<void> _handleContinue() async {
    // Validate interests selection
    if (_selectedInterests.length < InterestsSelector.defaultMinSelection) {
      UIUtils.showSnackBar(
        context,
        'Please select at least ${InterestsSelector.defaultMinSelection} interests',
        isError: true,
      );
      return;
    }

    // Validate consent
    if (!_agreedToTerms || !_agreedToPrivacy) {
      UIUtils.showSnackBar(
        context,
        'Please agree to the Terms of Service and Privacy Policy to continue',
        isError: true,
      );
      return;
    }

    await _registerUser(_selectedInterests);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Interests'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Icon(
                    Icons.interests,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Personalize Your Feed',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your interests to get personalized content recommendations',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Interests selector
                  InterestsSelector(
                    selectedInterests: _selectedInterests,
                    onInterestsChanged: (interests) {
                      setState(() {
                        _selectedInterests = interests;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // GDPR Consent Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Legal Agreements',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _agreedToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreedToTerms = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              style: theme.textTheme.bodySmall,
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        CheckboxListTile(
                          value: _agreedToPrivacy,
                          onChanged: (value) {
                            setState(() {
                              _agreedToPrivacy = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              style: theme.textTheme.bodySmall,
                              children: [
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' and consent to the processing of my personal data',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Continue button
                  FilledButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const ShimmerButtonLoading(width: 20, height: 20)
                        : const Text('Continue'),
                  ),
                  const SizedBox(height: 16),

                  // Skip button
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            // Validate consent even when skipping
                            if (!_agreedToTerms || !_agreedToPrivacy) {
                              UIUtils.showSnackBar(
                                context,
                                'Please agree to the Terms of Service and Privacy Policy to continue',
                                isError: true,
                              );
                              return;
                            }
                            _registerUser([]);
                          },
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
