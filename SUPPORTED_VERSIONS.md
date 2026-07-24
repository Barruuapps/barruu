# Supported Versions

This document outlines the versioning and support policy for Barruu.

## Versioning

Barruu follows [Semantic Versioning](https://semver.org/) (SemVer):

- **MAJOR** version (`X.0.0`): Incompatible API or data format changes
- **MINOR** version (`0.X.0`): New features, backward-compatible
- **PATCH** version (`0.0.X`): Bug fixes, backward-compatible

During the `0.x` phase (pre-1.0), breaking changes may occur in **MINOR** releases. After 1.0, breaking changes will only occur in **MAJOR** releases.

## Current Support

| Version            | Status               | Released   | End of Support |
| ------------------ | -------------------- | ---------- | -------------- |
| 0.1.x              | Current (supported)  | 2024-01    | TBD            |

## Support Tiers

### Active Support

The current version receives:

- Security patches
- Critical bug fixes
- Community support via GitHub Issues and Discussions

### End of Life (EOL)

Versions that have reached EOL:

- Do not receive any updates
- Issues reported against EOL versions will be closed
- Users are encouraged to upgrade to the latest version

## Platform Support

| Platform        | Version           | Status      |
| --------------- | ----------------- | ----------- |
| Linux (x86_64)  | Latest Flutter stable | Supported |
| macOS           | Latest Flutter stable | Supported |
| Windows 10/11   | Latest Flutter stable | Supported |
| Android         | API 24+ (Android 7.0+) | Supported |
| iOS             | 15.0+              | Supported |
| Web             | Any modern browser | Planned     |

## Data Migration

Barruu stores data locally in SQLite. When upgrading:

- **MINOR and PATCH upgrades**: Data is automatically migrated
- **MAJOR upgrades** (post-1.0): Migration scripts will be provided

We recommend backing up your data before any version upgrade.

## Reporting Compatibility Issues

If you encounter issues with a specific platform or version, please file a bug report through [GitHub Issues](https://github.com/Barruuapps/barruu/issues) using the Bug Report template.