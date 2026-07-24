import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/errors/error_screen.dart';
import 'package:barruu/features/workspace/presentation/screen/create_document_screen.dart';
import 'package:barruu/features/workspace/presentation/screen/edit_document_screen.dart'
    show EditDocumentScreen;
import 'package:barruu/features/workspace/presentation/screen/preview_document.dart';
import 'package:barruu/features/workspace/presentation/screen/splash_screen.dart';
import 'package:barruu/features/home/presentation/screens/home_screen.dart';
import 'package:barruu/features/home/presentation/screens/calendar_screen.dart';
import 'package:barruu/core/theme/domain/presentation/pages/theme_selection_page.dart';
import 'package:barruu/features/auth/presentation/screens/login_screen.dart';
import 'package:barruu/features/auth/presentation/screens/signup_screen.dart';
import 'package:barruu/features/ai/presentation/screens/ai_chat_page.dart';
import 'package:barruu/features/profile/screens/edit_profile_screen.dart';
import 'package:barruu/core/models/user_profile.dart';
import 'package:barruu/features/profile/screens/user_profile_screen.dart';
import 'package:barruu/features/profile/screens/settings_screen.dart';
import 'package:barruu/features/profile/screens/about_screen.dart';
import 'package:barruu/features/onboarding/screens/welcome_screen.dart';
import 'package:barruu/features/onboarding/screens/topic_selection_screen.dart';
import 'package:barruu/features/onboarding/screens/profession_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Custom page transition for smoother animations
Page<T> buildPageWithTransition<T>({
  required Widget child,
  required GoRouterState state,
  String? restorationId,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    restorationId: restorationId,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Slide and fade transition
      const begin = Offset(0.1, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;

      var slideTween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      var fadeTween = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(slideTween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return router;
});

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/signup',
      builder: (BuildContext context, GoRouterState state) {
        return const SignupScreen();
      },
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithTransition(
          child: const WelcomeScreen(),
          state: state,
        );
      },
    ),
    GoRoute(
      path: '/topic-selection',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithTransition(
          child: const TopicSelectionScreen(),
          state: state,
        );
      },
    ),
    GoRoute(
      path: '/profession-selection',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return buildPageWithTransition(
          child: const ProfessionSelectionScreen(),
          state: state,
        );
      },
    ),
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'create-document',
          builder: (BuildContext context, GoRouterState state) {
            return const CreateDocumentScreen();
          },
        ),

        GoRoute(
          path: 'edit-document/:path',
          builder: (BuildContext context, GoRouterState state) {
            final path = state.pathParameters['path'];
            if (path == null) {
              logger.w('Invalid document path: null ${state.pathParameters}');
              return const ErrorScreen(message: 'Invalid document path');
            }
            try {
              final decodedPath = Uri.decodeComponent(path);
              final doc = Directory(decodedPath);
              if (!kIsWeb && !doc.existsSync()) {
                logger.w('Document does not exist: $decodedPath');
                return const ErrorScreen(message: 'Document not found');
              }
              return EditDocumentScreen(doc: doc);
            } catch (e, stackTrace) {
              logger.e(
                'Failed to process document path: $path',
                error: e,
                stackTrace: stackTrace,
              );
              return const ErrorScreen(message: 'Error accessing document');
            }
          },
        ),
        GoRoute(
          path: 'preview-document/:path',
          builder: (BuildContext context, GoRouterState state) {
            final path = state.pathParameters['path'];
            if (path == null) {
              logger.w('Invalid document path: null ${state.pathParameters}');
              return const ErrorScreen(message: 'Invalid document path');
            }
            try {
              final decodedPath = Uri.decodeComponent(path);
              final doc = Directory(decodedPath);
              if (!kIsWeb && !doc.existsSync()) {
                logger.w('Document does not exist: $decodedPath');
                return const ErrorScreen(message: 'Document not found');
              }
              return PreviewDocument(doc: doc);
            } catch (e, stackTrace) {
              logger.e(
                'Failed to process document path: $path',
                error: e,
                stackTrace: stackTrace,
              );
              return const ErrorScreen(message: 'Error accessing document');
            }
          },
        ),
        // AI Chat route without document context
        GoRoute(
          path: 'ai-chat',
          builder: (BuildContext context, GoRouterState state) {
            return const AIChatPage();
          },
        ),
        // AI Chat route with document context
        GoRoute(
          path: 'ai-chat/:docPath',
          builder: (BuildContext context, GoRouterState state) {
            final docPath = state.pathParameters['docPath'];
            if (docPath == null) {
              return const AIChatPage();
            }
            try {
              final decodedPath = Uri.decodeComponent(docPath);
              final doc = Directory(decodedPath);
              if (!kIsWeb && !doc.existsSync()) {
                return const AIChatPage();
              }
              return AIChatPage(docDir: doc);
            } catch (e, stackTrace) {
              logger.e(
                'Failed to process document path for AI chat: $docPath',
                error: e,
                stackTrace: stackTrace,
              );
              return const AIChatPage();
            }
          },
        ),
        GoRoute(
          path: '/workspace',
          builder: (BuildContext context, GoRouterState state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: 'theme-selection',
          builder: (BuildContext context, GoRouterState state) {
            return const ThemeSelectionPage();
          },
        ),
        GoRoute(
          path: 'calendar',
          builder: (BuildContext context, GoRouterState state) {
            return const CalendarScreen();
          },
        ),
        GoRoute(
          path: 'edit-profile',
          pageBuilder: (BuildContext context, GoRouterState state) {
            // Get profile from extra parameter
            final profile = state.extra;
            if (profile == null) {
              return const MaterialPage(
                child: ErrorScreen(message: 'Profile data required'),
              );
            }
            return buildPageWithTransition(
              child: EditProfileScreen(profile: profile as UserProfile),
              state: state,
            );
          },
        ),
        GoRoute(
          path: 'profile/:userId',
          pageBuilder: (BuildContext context, GoRouterState state) {
            final userId = state.pathParameters['userId'];
            if (userId == null) {
              return const MaterialPage(
                child: ErrorScreen(message: 'User ID required'),
              );
            }
            return buildPageWithTransition(
              child: UserProfileScreen(userId: userId),
              state: state,
            );
          },
        ),
        GoRoute(
          path: 'settings',
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithTransition(
              child: const SettingsScreen(),
              state: state,
            );
          },
        ),
        GoRoute(
          path: 'about',
          pageBuilder: (BuildContext context, GoRouterState state) {
            return buildPageWithTransition(
              child: const AboutScreen(),
              state: state,
            );
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) {
    logger.e('Navigation error: ${state.error}');
    if (state.uri.toString().contains('content://') ||
        state.uri.toString().contains('file://')) {
      return const HomeScreen();
    }
    return ErrorScreen(message: state.error?.toString() ?? 'Page not found');
  },
  redirect: (context, state) {
    final fullPath = state.uri.toString();
    if (fullPath.startsWith('content://') || fullPath.startsWith('file://')) {
      logger.i('Redirecting content/file URI to home: $fullPath');
      return '/';
    }
    final location = state.uri.toString();
    if (location.contains('content://') ||
        location.contains('file://') ||
        location.contains('/media/')) {
      logger.i('Redirecting media path to home: $location');
      return '/';
    }
    return null;
  },
  debugLogDiagnostics: kDebugMode,
);
