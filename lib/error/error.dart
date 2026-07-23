import 'package:barruu/utils/barruu_logger.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class BarruuErrorApp extends StatelessWidget {
  const BarruuErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bipy - Reading App',
      theme: ThemeData.light(),
      home: const ErrorScreen(message: 'Application failed to start'),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Error icon',
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: 'Error message',
              child: Text(
                message,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                try {
                  // First try with direct navigation to root route which is safer
                  try {
                    context.go('/workspace');
                  } catch (e) {
                    barruuLogger.e('First navigation attempt failed', error: e);

                    // If the first attempt fails, try a more basic approach
                    try {
                      // Use context.go with a delay to allow the UI to update
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (context.mounted) {
                          context.go('/splash');
                        }
                      });
                    } catch (e) {
                      barruuLogger.e('Second navigation attempt failed', error: e);
                    }
                  }
                } catch (e, stackTrace) {
                  barruuLogger.e(
                    'All navigation attempts failed',
                    error: e,
                    stackTrace: stackTrace,
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
