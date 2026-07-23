import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barruu/utils/barruu_logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:barruu/error/error.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await dotenv.load();
      barruuLogger.i('Environment variables loaded from .env file');
    } catch (e) {
      // .env file is optional - AI features will show configuration prompts
      barruuLogger.w(
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
    barruuLogger.e(
      'Failed to initialize app',
      error: e,
      stackTrace: stackTrace,
    );
    runApp(const ProviderScope(child: BarruuErrorApp()));
  }
}

class BarruuApp extends StatelessWidget {
  const BarruuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barruu',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Center(child: Text('Welcome to Barruu!')),
    );
  }
}
