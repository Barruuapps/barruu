import 'package:flutter/material.dart';
import 'package:barruu/core/theme/design_tokens.dart';
import 'package:barruu/core/widgets/buttons/primary_button.dart';
import 'package:barruu/core/widgets/app_logo_widget.dart';

/// Welcome screen - first screen in onboarding flow
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // App logo
              const AppLogoWidget(size: 100),
              const SizedBox(height: AppSpacing.xl),

              // Headline
              Text(
                'Read Better.\nWrite Better.',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.base),

              // Subheadline
              Text(
                'Join thousands of professionals sharing knowledge',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),

              const Spacer(),

              // Primary CTA
              PrimaryButton(
                label: 'Get Started',
                fullWidth: true,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/topic-selection');
                },
              ),
              const SizedBox(height: AppSpacing.base),

              // Secondary CTA
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: AppTypography.bodyMedium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
