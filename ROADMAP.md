# Barruu Roadmap

This document outlines the development roadmap for Barruu. Priorities and timelines may shift based on community feedback and contributions.

## Vision

Barruu aims to become the premier open-source platform for creating **interactive knowledge**. We envision a world where anyone can create rich, engaging, interactive educational content — not just static documents.

---

## Phase 1 — Core Editor (v0.x)

*Status: In Progress*

### Rich Text & Block Editor

- [x] Block-based editing with slash (`/`) commands
- [x] Core block types: paragraph, heading (H1-H6), bullet list, numbered list, quote, divider
- [x] Inline formatting: bold, italic, underline, strikethrough, code, links
- [x] Drag-and-drop block reordering
- [x] Copy/paste with format preservation
- [ ] Undo/redo system improvements
- [ ] Keyboard shortcuts reference
- [ ] Markdown paste support

### Code Blocks

- [x] Syntax highlighting for 50+ languages
- [ ] Code execution (sandboxed)
- [ ] Line numbers
- [ ] Code folding

### Math Blocks

- [x] LaTeX rendering
- [x] Inline math
- [ ] Math block editor improvements
- [ ] Symbol palette

### Media Blocks

- [x] Image blocks
- [x] Video blocks
- [x] Audio blocks with transcript
- [ ] File attachment blocks

### Platform Support

- [x] Linux desktop (GTK)
- [x] macOS desktop (Cocoa)
- [x] Windows desktop (Win32)
- [x] Android mobile/tablet
- [x] iOS mobile/tablet
- [ ] Web (Flutter Web)

### Storage

- [x] Offline-first SQLite storage
- [x] Workspace organization
- [ ] Backup/restore
- [ ] Cross-device sync (local network)

### Export

- [ ] PDF export
- [ ] Markdown export
- [ ] HTML export
- [ ] Plain text export

---

## Phase 2 — Interactive Blocks (v0.5+)

*Status: Planned*

### Quiz & Assessment Blocks

- [ ] Multiple choice quiz block
- [ ] Fill-in-the-blank (improved)
- [ ] Matching/ordering block
- [ ] Short answer block
- [ ] Score tracking
- [ ] Feedback display

### Drawing & Diagram Blocks

- [ ] Freehand drawing block
- [ ] Shape library (rectangles, circles, arrows, etc.)
- [ ] Diagram block (flowcharts, UML)
- [ ] Handwriting recognition

### Data & Visualization Blocks

- [x] Chart blocks (bar, line, pie)
- [x] Graph/diagram blocks
- [ ] Table block with sorting/filtering
- [ ] Kanban board block
- [ ] Calendar block improvements
- [ ] Map block

### Interactive Content Blocks

- [x] Stepper/tutorial block
- [ ] Embed block (websites, iframes)
- [ ] Web component block
- [ ] 3D model viewer block

### Export & Sharing

- [ ] Share as read-only link
- [ ] Publish to web
- [ ] Embed in other sites
- [ ] Export with interactive elements preserved

---

## Phase 3 — Platform & Ecosystem (v1.0+)

*Status: Planned*

### AI Assistant

- [ ] AI-powered writing assistant
- [ ] AI content summarizer
- [ ] AI quiz/question generator
- [ ] AI block suggestions
- [ ] AI translation
- [ ] AI image generation

### Cloud Synchronization

- [ ] End-to-end encrypted cloud sync
- [ ] Multi-device sync
- [ ] Conflict resolution (CRDT-based)
- [ ] Selective sync (per workspace)
- [ ] Offline-queue for pending changes

### Plugin System

- [ ] Plugin API (Dart & Rust)
- [ ] Custom block type registration
- [ ] Custom theme registration
- [ ] Plugin marketplace/registry
- [ ] Plugin sandboxing & permissions
- [ ] Hot-reload for plugin development

### Templates

- [ ] Template gallery
- [ ] Community templates
- [ ] Template import/export
- [ ] Default templates (resume, book, course, notes)

### Collaboration

- [ ] Real-time collaborative editing (CRDT/Yjs)
- [ ] Comments and suggestions
- [ ] Version history/diff
- [ ] Presence indicators
- [ ] Permissions (view, comment, edit)

### Developer Experience

- [ ] Rust backend for performance-critical operations
- [ ] CLI tool for project management
- [ ] Developer documentation
- [ ] SDK for external integrations
- [ ] API for programmatic document creation

---

## Phase 4 — Beyond (v2.0+)

*Status: Future*

### Advanced Features

- [ ] AI tutoring system
- [ ] Learning path generation
- [ ] Gamification engine
- [ ] Analytics dashboard for educators
- [ ] Accessibility (WCAG compliance)
- [ ] Localization/i18n framework

### Ecosystem

- [ ] Mobile companion app enhancements
- [ ] Desktop widgets
- [ ] Browser extension (clip content)
- [ ] Integration with LMS platforms (Moodle, Canvas)
- [ ] API-first architecture for headless use

---

## How to Contribute to the Roadmap

The roadmap is a living document shaped by the community. To suggest changes or additions:

1. Open a [Feature Request](https://github.com/Barruuapps/barruu/issues/new?template=feature_request.md) on GitHub
1. Discuss in [GitHub Discussions](https://github.com/Barruuapps/barruu/discussions)
1. Join the conversation on [Discord](https://discord.gg/MtUgbVYMw)

---

<p align="center">
  <sub>Last updated: July 2026</sub>
</p>
