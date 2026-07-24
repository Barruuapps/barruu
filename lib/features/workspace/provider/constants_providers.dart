import 'package:flutter_riverpod/flutter_riverpod.dart';

final fontFamiliesProvider = Provider<List<String>>((ref) {
  return const {
    'Times New Roman',
    'Arial',
    'Roboto',
    'Helvetica',
    'Georgia',
    'Courier New',
    'Verdana',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Poppins',
    'Nunito',
    'Inter',
    'Source Sans Pro',
    'Work Sans',
    'Merriweather',
  }.toList();
});

// Font sizes with provider
final fontSizesProvider = Provider<List<double>>((ref) {
  return const [
    6,
    8,
    9,
    10,
    11,
    12,
    14,
    16,
    18,
    20,
    24,
    28,
    32,
    36,
    48,
    64,
  ];
});

// Supported programming languages for code blocks
final supportedLanguagesProvider = Provider<List<String>>((ref) {
  return const [
    'text',
    'c',
    'cpp',
    'csharp',
    'python',
    'java',
    'dart',
    'kotlin',
    'javascript',
    'typescript',
    'go',
    'rust',
    'swift',
    'ruby',
    'php',
    'scala',
    'r',
    'perl',
    'haskell',
    'elixir',
    'erlang',
    'lua',
    'matlab',
    'objectivec',
    'shell',
    'sql'
  ];
});

// Default font family provider
final defaultFontFamilyProvider = Provider<String>((ref) {
  return 'Times New Roman';
});

// Default font size provider
final defaultFontSizeProvider = Provider<double>((ref) {
  return 18.0;
});

// Text alignment options
final textAlignOptionsProvider = Provider<List<String>>((ref) {
  return const ['left', 'center', 'right', 'justify'];
});

// Helper function to get display name for programming languages
String getLanguageDisplayName(String languageCode) {
  final languageMap = {
    'text': 'Plain Text',
    'c': 'C',
    'cpp': 'C++',
    'csharp': 'C#',
    'python': 'Python',
    'java': 'Java',
    'dart': 'Dart',
    'kotlin': 'Kotlin',
    'javascript': 'JavaScript',
    'typescript': 'TypeScript',
    'go': 'Go',
    'rust': 'Rust',
    'swift': 'Swift',
    'ruby': 'Ruby',
    'php': 'PHP',
    'scala': 'Scala',
    'r': 'R',
    'perl': 'Perl',
    'haskell': 'Haskell',
    'elixir': 'Elixir',
    'erlang': 'Erlang',
    'lua': 'Lua',
    'matlab': 'MATLAB',
    'objectivec': 'Objective-C',
    'shell': 'Shell',
    'sql': 'SQL'
  };

  return languageMap[languageCode] ?? languageCode;
}