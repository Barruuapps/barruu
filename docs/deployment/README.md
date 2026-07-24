# Deployment

This document describes how to build and deploy Barruu for various platforms.

## Building Releases

### Linux

```bash
flutter build linux --release
```

The build output is located at `build/linux/x64/release/bundle/`.

### macOS

```bash
flutter build macos --release
```

The `.app` bundle is at `build/macos/Build/Products/Release/Barruu.app`.

### Windows

```bash
flutter build windows --release
```

The executable is at `build/windows/x64/runner/Release/`.

### Android

```bash
# APK
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

Requires Xcode to create an archive for App Store distribution.

## CI/CD Deployment

See the [release workflow](../../.github/workflows/release.yml) for automated builds.

## Publishing

- **Google Play Store**: Use the Android App Bundle
- **Apple App Store**: Use Xcode archive
- **Snap Store** (Linux): Snap configuration TBD
- **Flathub** (Linux): Flatpak configuration TBD
- **Microsoft Store** (Windows): MSIX packaging TBD

---

*Deployment documentation is being expanded.*
