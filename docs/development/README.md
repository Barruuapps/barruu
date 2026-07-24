# Development Guide

This document provides a comprehensive guide for setting up and working on Barruu.

## Prerequisites

- **Flutter SDK** >= 3.8.1
- **Dart SDK** (included with Flutter)
- **Rust** (optional, for future backend)

### Platform-Specific

- **Linux**: GTK 3.0, Clang, CMake, Ninja, pkg-config
- **macOS**: Xcode 15+, CocoaPods
- **Windows**: Visual Studio 2022 with C++ desktop workload
- **Android**: Android Studio, Android SDK, NDK
- **iOS**: Xcode 15+, CocoaPods

## Setup

```bash
# Clone the repository
git clone https://github.com/Barruuapps/barruu.git
cd barruu

# Install dependencies
flutter pub get

# Generate code
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

## Development Workflow

### Code Generation

Barruu uses `build_runner` with `freezed` and `json_serializable`. Run:

```bash
# One-time generation
dart run build_runner build --delete-conflicting-outputs

# Watch mode (during development)
dart run build_runner watch --delete-conflicting-outputs
```

### Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/widget_test.dart
```

### Code Quality

```bash
# Static analysis
flutter analyze

# Format code
dart format lib/ test/

# Fix issues
dart fix --apply lib/
```

## Project Structure

See [Architecture documentation](../architecture/README.md).

## IDE Configuration

### VS Code

Recommended extensions:

- Flutter
- Dart
- Rust Analyzer (if working with Rust code)
- EditorConfig

### Android Studio / IntelliJ

Required plugins:

- Flutter
- Dart

---

*Development documentation is being expanded.*
