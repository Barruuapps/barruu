# Architecture

This document describes the high-level architecture of Barruu.

## Overview

Barruu follows a **Clean Architecture** pattern with feature-based modules. The entire application is built with Flutter and Dart, targeting desktop (Linux, macOS, Windows), mobile (Android, iOS), and web.

## Layers

### Presentation Layer
- Flutter widgets and screens
- Riverpod state management
- GoRouter navigation
- Platform-specific adaptations

### Domain Layer
- Business logic entities
- Use cases
- Repository interfaces

### Data Layer
- Repository implementations
- Local data sources (SQLite via Sqflite)
- Remote data sources (future)

## Key Design Decisions

- **Offline-first**: All data is stored locally. A cloud sync layer may be added later.
- **Block-based documents**: Every piece of content is a block, enabling rich compositions.
- **Riverpod**: Chosen over BLoC for its simplicity, compile-time safety, and testability.
- **Freezed**: Used for immutable data classes with pattern matching support.
- **SQLite**: Local persistence via sqflite, providing reliable offline storage.

## Directory Structure

```text
lib/
├── core/          # Shared utilities, theme, services
├── features/      # Feature modules
│   ├── auth/
│   ├── home/
│   ├── workspace/ # Editor & documents
│   ├── learning/  # Quizzes & assessments
│   ├── ai/        # AI features
│   └── onboarding/
└── router/        # Navigation configuration
```

## Data Flow

```text
┌──────────┐     ┌──────────────┐     ┌───────────┐
│   UI     │ ──▶ │  Repository  │ ──▶ │  SQLite   │
│ (Riverpod)│ ◀── │              │ ◀── │ (Sqflite) │
└──────────┘     └──────────────┘     └───────────┘
```

---

*This document is actively being developed.*