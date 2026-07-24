# Contributing to Barruu

Thank you for your interest in contributing to Barruu! 🎉 This document outlines the guidelines and workflow for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
  - [Development Environment](#development-environment)
  - [Building the Project](#building-the-project)
- [Development Workflow](#development-workflow)
  - [Branches](#branches)
  - [Commit Conventions](#commit-conventions)
  - [Pull Request Process](#pull-request-process)
  - [Code Review](#code-review)
- [Coding Standards](#coding-standards)
  - [Dart / Flutter](#dart--flutter)
  - [Rust](#rust)
  - [Documentation](#documentation)
- [Testing](#testing)
- [Issue Workflow](#issue-workflow)
- [Community](#community)

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [support@barruu.com](mailto:support@barruu.com).

## Getting Started

### Development Environment

1. **Install Flutter SDK** (>= 3.8.1)
   - Follow the [official Flutter installation guide](https://flutter.dev/docs/get-started/install)

2. **Install Rust** (optional, for future backend components)
   - Via [rustup](https://rustup.rs/): `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

3. **Clone and set up**
   ```bash
   git clone https://github.com/Barruuapps/barruu.git
   cd barruu
   flutter pub get
   ```

4. **Install IDE plugins**
   - VS Code: Flutter, Dart, Rust Analyzer
   - Android Studio / IntelliJ: Flutter, Dart

### Building the Project

```bash
# Generate code (required after model changes)
dart run build_runner build --delete-conflicting-outputs

# Run on desktop
flutter run -d linux    # Linux
flutter run -d macos    # macOS
flutter run -d windows  # Windows

# Run on mobile
flutter run -d android
flutter run -d ios
```

## Development Workflow

### Branches

- `main` — Production-ready code. Protected branch.
- `dev` — Integration branch for feature testing.
- `feat/<name>` — New features (e.g., `feat/code-execution-block`)
- `fix/<name>` — Bug fixes (e.g., `fix/graph-rendering-crash`)
- `docs/<name>` — Documentation changes
- `chore/<name>` — Maintenance tasks, CI, dependencies

Always branch from `dev` for new work.

### Commit Conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build`

**Examples**:
```
feat(editor): add slash command for quiz block insertion
fix(blocks): resolve graph rendering crash on empty data
docs(readme): update installation instructions for Linux
chore(deps): bump flutter_riverpod to ^3.3.1
```

**Rules**:
- Use imperative mood ("add" not "added" or "adds")
- Keep the subject line under 72 characters
- Reference issues with `Closes #123` or `Fixes #456` in the footer if applicable
- Breaking changes must include `BREAKING CHANGE:` in the footer

### Pull Request Process

1. **Create a feature branch** from `dev`
   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feat/my-feature
   ```

2. **Make your changes** and ensure they meet coding standards

3. **Run quality checks** before pushing:
   ```bash
   flutter analyze          # Dart static analysis
   dart format lib/ test/   # Format code
   flutter test             # Run tests
   ```

4. **Push your branch** and open a Pull Request against `dev`
   - Use the PR template
   - Link related issues
   - Add appropriate labels
   - Request review from maintainers

5. **Address review feedback**
   - All conversations must be resolved before merging
   - At least one approving review is required
   - CI must pass (formatting, analysis, tests)

6. **Merge**
   - Use **Squash and Merge** for a clean history
   - The merge commit should follow Conventional Commits format

### Code Review

Code review is a collaborative process. Reviewers will check for:

- **Correctness** — Does the code do what it claims?
- **Design** — Is the code well-structured and maintainable?
- **Style** — Does it follow project conventions?
- **Tests** — Are there adequate tests?
- **Documentation** — Are public APIs documented?
- **Performance** — Are there obvious performance issues?

As a reviewer, be respectful and constructive. As an author, be open to feedback.

## Coding Standards

### Dart / Flutter

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter analyze` to check for issues
- Format with `dart format lib/ test/`
- Use `const` constructors where possible
- Prefer composition over inheritance
- Use Riverpod for state management
- Use Freezed for immutable models
- Follow the project's feature-based folder structure
- Use `analysis_options.yaml` lint rules (do not disable without justification)

### Rust

- Follow the [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- Format with `rustfmt`
- Lint with `clippy` (`cargo clippy -- -D warnings`)
- Write doc comments for public items (`///`)
- Use `Result` and `Option` properly — avoid `unwrap()` in production code
- Follow the standard module structure

### Documentation

- Public classes and methods should have `///` doc comments
- Complex logic should have inline comments explaining *why*, not *what*
- Update the README or relevant docs when adding features
- Use `TODO(username): description` for temporary workarounds

## Testing

- **Unit tests** for business logic (`test/`)
- **Widget tests** for UI components (`test/`)
- Write tests for new features
- Maintain or improve coverage for modified code
- Run `flutter test` before pushing

Test naming convention:
```dart
group('MyWidget', () {
  testWidgets('should render correctly with given props', (tester) async {
    // ...
  });
});
```

## Issue Workflow

### Bug Reports

Please include:
- Barruu version
- Operating system and version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots or logs if applicable

Use the **Bug Report** template when creating issues.

### Feature Requests

Please include:
- Clear description of the feature
- Use case or problem it solves
- Proposed solution (optional)
- Alternatives considered (optional)

Use the **Feature Request** template.

### Picking Up Issues

1. Find an issue you'd like to work on
2. Comment on the issue to express interest
3. Wait for a maintainer to assign it to you (prevents duplicate work)
4. Start working and reference the issue in your commits

## Community

- **Discord**: [Join our Discord server](https://discord.gg/MtUgbVYMw)
- **Website**: [barruu.com](https://www.barruu.com/)
- **GitHub Discussions**: [Ask questions](https://github.com/Barruuapps/barruu/discussions)
- **Issue Tracker**: [Report issues](https://github.com/Barruuapps/barruu/issues)

---

Thank you for contributing to Barruu! Every contribution helps build a better platform for interactive knowledge. 🚀