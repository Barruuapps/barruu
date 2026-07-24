# Storage & Persistence

Barruu uses an **offline-first** storage architecture.

## Overview

All user data is stored locally on the device using **SQLite** via the `sqflite` package. This ensures users have full control over their data and can work without an internet connection.

## Storage Layer

```text
lib/features/workspace/data/
├── models/              # Data transfer objects
├── repositories/        # Repository implementations
└── sources/             # Data source implementations
    └── document_local_source.dart  # SQLite implementation
```

## Database Schema

The primary storage uses SQLite with tables for:

- `documents` — Document metadata and structure
- `blocks` — Individual block content
- `workspaces` — Workspace groupings
- `user_preferences` — App settings and preferences

## Data Flow

1. **Write**: UI → Repository → Local Source → SQLite
2. **Read**: SQLite → Local Source → Repository → UI
3. **Sync** (future): SQLite ↔ Cloud API

## Future: Cloud Sync

A cloud synchronization layer is planned for Phase 3. Key principles:

- **End-to-end encryption** for all synced data
- **CRDT-based** conflict resolution
- **Selective sync** per workspace
- **Offline queue** for pending changes

## Backup

Users are encouraged to export and back up their data regularly. Export options include:

- Full database backup (.sqlite)
- Document export (PDF, Markdown, HTML)

---

*Storage documentation is being expanded.*
