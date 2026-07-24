# Architecture

This document describes the high-level architecture of Barruu.

## Overview

Barruu follows a **Clean Architecture** pattern with feature-based modules. The application is built with Flutter for the frontend (desktop, mobile, web) and plans to use Rust for performance-critical backend operations.

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

## Future: Rust Integration

Planned Rust components:
- Document CRDT engine for collaborative editing
- File export pipeline (PDF, Markdown)
- Image processing
- Search indexing
- Plugin runtime sandbox

---

*This document is actively being developed.*