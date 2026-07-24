# Block Editor

The Barruu block editor is the core interaction surface of the application.

## Overview

The editor is based on a block paradigm — every piece of content (text, image, code, quiz) is a reorderable, nestable block. This provides maximum flexibility for creating rich, interactive documents.

## Block Types

See [blocks/README.md](../blocks/README.md) for the full list of block types.

## Key Features

- **Slash commands** (`/`) for quick block insertion
- **Drag-and-drop** reordering
- **Inline formatting** (bold, italic, underline, code, links)
- **Block-level actions** (duplicate, delete, move, comment)
- **Copy/paste** with format preservation

## Architecture

The editor is implemented in `lib/features/workspace/`:

```text
workspace/
├── data/            # Data layer
│   ├── models/      # Block data models
│   ├── repositories/
│   └── sources/     # SQLite local source
├── domain/          # Business logic
└── presentation/    # UI
    ├── screens/     # Editor screens
    └── widgets/     # Editor widgets
        └── blocks/  # Individual block widgets
            ├── editor/    # Block editors
            └── reader/    # Block readers/renderers
```

## Adding a New Block Type

1. Define the block data model in `data/models/`
2. Create editor widget in `presentation/widgets/blocks/editor/`
3. Create reader widget in `presentation/widgets/blocks/reader/`
4. Register in the block type registry
5. Add slash command registration

---

*Editor documentation is being expanded.*
