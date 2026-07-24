# Block Types

Barruu supports a variety of block types for creating rich, interactive content.

## Implemented Blocks

### Text & Structure
- **Paragraph** — Standard text block
- **Header** — H1 through H6 headings
- **List** — Ordered and unordered lists
- **Quote** — Blockquote with attribution
- **Divider** — Horizontal rule

### Media
- **Image** — PNG, JPG, GIF, SVG
- **Video** — MP4, WebM playback
- **Audio** — MP3, WAV, OGG with transcripts

### Code & Math
- **Code** — Syntax highlighting for 50+ languages
- **Math** — LaTeX rendering (inline and block)

### Interactive
- **Quiz** — Multiple choice, fill-in-the-blank (in progress)
- **Stepper** — Step-by-step tutorials
- **Graph** — Chart visualization (bar, line, pie)
- **Diagram** — Graph/flowchart diagrams

### Layout
- **Columns** — Multi-column layout

## Block Implementation Pattern

Each block type follows a consistent implementation pattern:

```text
lib/features/workspace/presentation/widgets/blocks/
├── editor/    # Block editors (what you see when editing)
│   └── <type>_editor_block.dart
└── reader/    # Block readers (what you see when viewing)
    └── <type>_reader_block.dart
```

## Future Block Types

See [ROADMAP.md](../../ROADMAP.md#phase-2--interactive-blocks) for planned block types.

---

*Detailed specifications for each block type are being developed.*