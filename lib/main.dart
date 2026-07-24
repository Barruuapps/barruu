import 'dart:async';
import 'dart:io';
import 'package:barruu/router/app_router.dart';
import 'package:barruu/core/utils/ui_utils.dart';
import 'package:barruu/core/theme/domain/models/app_theme_mode.dart';
import 'package:barruu/core/theme/domain/providers/app_theme_mode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/core/theme/app_theme.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show MethodChannel, LogicalKeyboardKey;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/workspace/data/sources/document_local_source.dart';
import 'core/errors/error_screen.dart';
import 'features/workspace/presentation/controllers/documents_controller.dart';
import 'core/widgets/command_palette.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables from .env file (optional - app works without it)
    try {
      await dotenv.load();
      logger.i('Environment variables loaded from .env file');
    } catch (e) {
      // .env file is optional - AI features will show configuration prompts
      logger.w(
        'Could not load .env file: $e. AI features may require configuration.',
      );
    }

    // Initialize sqflite for desktop platforms
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // Initialize Firebase

    runApp(const ProviderScope(child: BarruuApp()));
  } catch (e, stackTrace) {
    logger.e('Failed to initialize app', error: e, stackTrace: stackTrace);
    runApp(const ProviderScope(child: ErrorApp()));
  }
}

class BarruuApp extends ConsumerStatefulWidget {
  const BarruuApp({super.key});

  @override
  ConsumerState<BarruuApp> createState() => _BarruuAppState();
}

class _BarruuAppState extends ConsumerState<BarruuApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  bool _isProcessingUri = false;
  Uri? _lastProcessedUri;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDeepLinks();
    });
  }

  void _initDeepLinks() async {
    try {
      // Handle initial link (app opened via deep link)
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        logger.i('Handling initial URI: $initialUri');
        // Wait for router to be fully initialized
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await _importAndOpenFile(initialUri);
        }
      }

      // Listen for subsequent deep links (app already running)
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          logger.i('Deep link received: $uri');
          _importAndOpenFile(uri);
        },
        onError: (Object e, StackTrace stackTrace) {
          logger.e('Deep link error', error: e, stackTrace: stackTrace);
        },
      );
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize deep links',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _importAndOpenFile(Uri uri) async {
    // Prevent processing the same URI twice
    if (_isProcessingUri) {
      logger.i('Already processing URI, skipping: $uri');
      return;
    }

    // Check if this exact URI was just processed
    if (_lastProcessedUri != null &&
        _lastProcessedUri.toString() == uri.toString()) {
      logger.i('URI already processed recently, skipping: $uri');
      return;
    }

    _isProcessingUri = true;
    _lastProcessedUri = uri;

    try {
      logger.i('Importing file from URI: $uri');

      // Only process .bipy files
      if (!uri.path.toLowerCase().endsWith('.bipy')) {
        logger.w('Not a .bipy file: $uri');
        _showError('Please select a .bipy file');
        return;
      }

      final documentService = ref.read(documentServiceProvider);
      File? bipyFile;
      String suggestedName = 'Imported Document';

      // Extract filename from URI
      final uriPath = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'document.bipy';
      if (uriPath.contains('.')) {
        suggestedName = uriPath.substring(0, uriPath.lastIndexOf('.'));
        suggestedName = suggestedName
            .replaceAll('%20', ' ')
            .replaceAll('_', ' ');
      }

      // Handle content:// URIs (from file managers, email, etc.)
      if (uri.scheme == 'content') {
        logger.i('Reading content URI: $uri');
        const channel = MethodChannel('com.bitpyrus.barruu/file');
        final bytes = await channel.invokeMethod('readContentUri', {
          'uri': uri.toString(),
        });

        if (bytes == null || (bytes as List).isEmpty) {
          logger.w('Failed to read content URI or empty file');
          _showError('Could not read the selected file');
          return;
        }

        final tempDir = await getTemporaryDirectory();
        final tempFileName =
            'import_${DateTime.now().millisecondsSinceEpoch}.bipy';
        bipyFile = File('${tempDir.path}/$tempFileName');
        await bipyFile.writeAsBytes(bytes as List<int>);
        logger.i('Content URI saved to temp file: ${bipyFile.path}');
      }
      // Handle file:// URIs (direct file access)
      else if (uri.scheme == 'file') {
        bipyFile = File(uri.path);
        logger.i('Processing file URI: ${bipyFile.path}');
      } else {
        logger.w('Unsupported URI scheme: ${uri.scheme}');
        _showError('Unsupported file source');
        return;
      }

      // Verify file exists
      if (!kIsWeb &&
          await FileSystemEntity.type(bipyFile.path) ==
              FileSystemEntityType.notFound) {
        logger.w('File does not exist: ${bipyFile.path}');
        _showError('File not found');
        return;
      }

      // Import the .bipy file
      logger.i('Importing .bipy file: ${bipyFile.path}');
      final docDir = await documentService.importDocumentFromBipyFile(
        bipyFile,
        suggestedName,
      );

      if (docDir == null) {
        logger.w('Failed to import .bipy file');
        _showError('Failed to import document');
        return;
      }

      // Navigate to edit screen
      if (mounted) {
        final docPath = Uri.encodeComponent(docDir.path);
        logger.i('Navigating to edit document: /edit-document/$docPath');

        // Refresh documents list
        ref.read(documentsProvider.notifier).loadDocuments();

        // Use go to replace entire navigation stack
        GoRouter.of(context).go('/edit-document/$docPath');

        // Clean up temp file if it was created from content URI
        if (uri.scheme == 'content' &&
            await FileSystemEntity.type(bipyFile.path) !=
                FileSystemEntityType.notFound) {
          await bipyFile.delete();
          logger.i('Cleaned up temp file');
        }
      }
    } catch (e, stackTrace) {
      logger.e('Failed to import file: $uri', error: e, stackTrace: stackTrace);
      _showError('Error opening file: ${e.toString()}');
    } finally {
      _isProcessingUri = false;
    }
  }

  void _showError(String message) {
    UIUtils.showSnackBar(context, message, isError: true);
  }

  /// Opens the global command palette (Ctrl+K).
  void _showCommandPalette() {
    final router = ref.read(routerProvider);

    showDialog(
      context: context,
      builder: (_) => CommandPalette(
        commands: [
          CommandItem(
            id: 'new-doc',
            title: 'New Document',
            subtitle: 'Create a blank document',
            icon: Icons.add_rounded,
            shortcutLabel: 'Ctrl+N',
            keywords: ['create', 'document', 'new'],
            onExecute: () => router.push('/create-document'),
          ),
          CommandItem(
            id: 'workspace',
            title: 'Go to Workspace',
            subtitle: 'View all documents',
            icon: Icons.folder_rounded,
            shortcutLabel: 'Ctrl+1',
            keywords: ['home', 'documents', 'files'],
            onExecute: () => router.go('/workspace'),
          ),
          CommandItem(
            id: 'theme',
            title: 'Change Theme',
            subtitle: 'Customize appearance',
            icon: Icons.palette_rounded,
            keywords: ['appearance', 'color', 'dark', 'light'],
            onExecute: () => router.push('/theme-selection'),
          ),
          CommandItem(
            id: 'import',
            title: 'Import Document',
            subtitle: 'Import .bipy file',
            icon: Icons.file_download_rounded,
            keywords: ['bipy', 'file', 'open', 'load'],
            onExecute: () {
              // Navigate to workspace which has import
              router.go('/');
            },
          ),
          CommandItem(
            id: 'settings',
            title: 'Settings',
            subtitle: 'App preferences and configuration',
            icon: Icons.settings_rounded,
            shortcutLabel: 'Ctrl+,',
            keywords: ['preferences', 'config', 'options'],
            onExecute: () => router.push('/settings'),
          ),
          CommandItem(
            id: 'ai-chat',
            title: 'AI Assistant',
            subtitle: 'Chat with Barruu AI',
            icon: Icons.auto_awesome_rounded,
            keywords: ['ai', 'chat', 'assistant', 'help'],
            onExecute: () => router.push('/ai-chat'),
          ),
          CommandItem(
            id: 'profile',
            title: 'Edit Profile',
            subtitle: 'Manage your Barruu profile',
            icon: Icons.person_rounded,
            keywords: ['user', 'account', 'avatar'],
            onExecute: () {
              // Requires profile; fallback to home
              router.go('/');
            },
          ),
        ],
        searchPlaceholder: 'Search commands...',
      ),
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appThemeMode = ref.watch(appThemeModeProvider);
    final router = ref.watch(routerProvider);

    // Determine theme and dark theme based on app theme mode
    ThemeData lightTheme = AppTheme.getAppLightTheme();
    ThemeData darkTheme = AppTheme.getAppDarkTheme();
    ThemeMode themeMode;

    switch (appThemeMode) {
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        themeMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
        break;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            () => _showCommandPalette(),
      },
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        title: 'Barruu - Professional Social Media',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
      ),
    );
  }
}
