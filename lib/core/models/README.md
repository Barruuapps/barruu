# Core Models

This directory contains the data models for Barrugram's core features.

## Models

### UserProfile

User profile model for the social platform. Contains:

- Basic user information (uid, username, display name)
- Profile customization (bio, avatar, cover image)
- Professional information (title, organization, website)
- Social stats (followers, following, posts count)
- Verification and account type

See `user_profile.dart` for complete model definition.

## Code Generation

The models in this directory use `freezed` and `json_serializable` for code generation.

### Running Code Generation

After creating or modifying models, run:

```bash
# Generate code for all models
flutter pub run build_runner build --delete-conflicting-outputs

# Or watch for changes (recommended during development)
flutter pub run build_runner watch --delete-conflicting-outputs
```

### What Gets Generated

For each model file (e.g., `user_profile.dart`), the following files are generated:

- `*.freezed.dart` - Freezed code (immutability, copy
With, equality, toString)
- `*.g.dart` - JSON serialization code (fromJson, toJson)

**Note**: Generated files are automatically created and should not be manually edited.

### Dependencies

The following packages are required for code generation:

- `freezed_annotation` - Freezed annotations (runtime)
- `json_annotation` - JSON annotations (runtime)
- `freezed` - Freezed code generator (dev)
- `json_serializable` - JSON serialization generator (dev)
- `build_runner` - Build system (dev)

These are already configured in `pubspec.yaml`.

## Adding New Models

When adding a new model:

1. Create the model file following the freezed pattern:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_model.freezed.dart';
part 'my_model.g.dart';

@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String id,
    // ... other fields
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) =>
      _$MyModelFromJson(json);
}
```

1. Run code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

1. The generated files will appear in the same directory.

## Testing Models

Models should have corresponding test files in `test/core/models/` to verify:

- JSON serialization/deserialization
- Copy with functionality
- Equality comparison
- Factory constructors

See existing test files for examples.
