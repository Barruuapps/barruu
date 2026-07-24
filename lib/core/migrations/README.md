# Document Social Metadata Migration

## Overview

This migration adds social metadata fields to existing documents to prepare them for the publishing workflow in Phase 2 of the Barrugram roadmap.

## What This Migration Does

The migration adds the following fields to each document's `meta.json` file:

### New Fields

1. **authorId** (string): Firebase Auth UID of the document creator
   - Uses current user ID or provided default
   - Essential for publishing workflow and attribution

1. **visibility** (string): Document visibility setting
   - Values: `'private'`, `'public'`, `'followers'`
   - Default: `'private'`
   - Controls who can see the document when published

1. **published** (boolean): Publication status
   - Default: `false`
   - Indicates whether document is published to the social feed

1. **publishedAt** (string | null): Publication timestamp
   - ISO 8601 format or null for unpublished documents
   - Default: `null`
   - Records when document was first published

1. **Engagement Counters** (integers): Denormalized counters for performance
   - **views**: Number of times document has been viewed (default: 0)
   - **likes**: Number of likes received (default: 0)
   - **comments**: Number of comments (default: 0)
   - **shares**: Number of shares (default: 0)

## Usage

### Running the Migration

The migration can be run programmatically:

```dart
import 'package:barruu/core/migrations/document_social_metadata_migration.dart';
import 'package:barruu/features/workspace/data/sources/user_identity_service.dart';

// Initialize the migration service
final migration = DocumentSocialMetadataMigration();

// Get current user ID (or provide a default)
final userService = UserIdentityService(ref);
final userId = await userService.getUserId();

// Run migration on all documents
final results = await migration.migrateAllDocuments(
  defaultAuthorId: userId,
);

// Check results
print('Total documents: ${results['total']}');
print('Migrated: ${results['migrated']}');
print('Skipped: ${results['skipped']}');
print('Failed: ${results['failed']}');
```

### Migrating a Single Document

You can also migrate individual documents:

```dart
final docDir = Directory('/path/to/document');
final migrated = await migration.migrateSingleDocument(
  docDir,
  'user-id-123',
);

if (migrated) {
  print('Document migrated successfully');
} else {
  print('Document already has social metadata or migration skipped');
}
```

### Checking Migration Status

To check if a document has complete social metadata:

```dart
final docDir = Directory('/path/to/document');
final hasMetadata = await migration.hasCompleteSocialMetadata(docDir);

if (hasMetadata) {
  print('Document has complete social metadata');
} else {
  print('Document needs migration');
}
```

## Migration Behavior

### Idempotency

The migration is **idempotent** - it can be run multiple times safely:

- Documents that already have social metadata are skipped
- Only missing fields are added
- Existing values are never overwritten
- Original document metadata is preserved

### Data Preservation

The migration preserves all existing metadata fields:

- Original fields like `name`, `description`, `tags`, etc. are unchanged
- Custom fields added by other parts of the app are preserved
- Only new social metadata fields are added

### Error Handling

The migration handles errors gracefully:

- Documents without metadata files are skipped
- Individual document failures don't stop the migration
- All errors are logged and returned in the results
- Failed documents can be retried individually

## Integration Points

### Automatic Migration

Consider running the migration automatically on app startup for existing users:

```dart
// In app initialization
final migration = DocumentSocialMetadataMigration();
final userService = ref.read(userIdentityServiceProvider);
final userId = await userService.getUserId();

// Run migration in background
unawaited(migration.migrateAllDocuments(defaultAuthorId: userId));
```

### New Documents

New documents automatically include social metadata when created:

- `DocumentService.createDocument()` now includes all social metadata fields
- No migration needed for documents created after this update

## Testing

Comprehensive tests are provided in `test/core/migrations/document_social_metadata_migration_test.dart`:

```bash
flutter test test/core/migrations/document_social_metadata_migration_test.dart
```

Test coverage includes:

- Migration of legacy documents without social metadata
- Skipping documents that already have social metadata
- Mixed document scenarios (some legacy, some modern)
- Single document migration
- Metadata completeness validation
- Field preservation
- Idempotency verification

## Example: Before and After

### Before Migration

```json
{
  "id": "doc-123",
  "name": "My Document",
  "description": "A document about X",
  "tags": "important, work",
  "cover": "",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-02T00:00:00.000Z",
  "author": "Barruu"
}
```

### After Migration

```json
{
  "id": "doc-123",
  "name": "My Document",
  "description": "A document about X",
  "tags": "important, work",
  "cover": "",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-02T00:00:00.000Z",
  "author": "Barruu",
  "authorId": "firebase-user-uid-123",
  "visibility": "private",
  "published": false,
  "publishedAt": null,
  "views": 0,
  "likes": 0,
  "comments": 0,
  "shares": 0
}
```

## Performance Considerations

- Migration processes documents sequentially to avoid overwhelming the file system
- Each document is read and written once
- No network calls required (purely local operation)
- For large document libraries, consider showing a progress indicator

## Rollback

If you need to rollback the migration:

1. The original fields are never modified, so documents remain functional
1. Simply remove the new fields from `meta.json` files:
   - `authorId`, `visibility`, `published`, `publishedAt`
   - `views`, `likes`, `comments`, `shares`
1. Or restore from backup if available

## Future Enhancements

- Add progress callback for UI updates during migration
- Support for batch processing with configurable batch size
- Add dry-run mode to preview changes without applying them
- Generate migration report with detailed statistics

## Related Files

- **Constants**: `lib/features/workspace/constants/meta_file.dart`
- **Migration Service**: `lib/core/migrations/document_social_metadata_migration.dart`
- **Document Service**: `lib/features/workspace/data/sources/document_local_source.dart`
- **Tests**: `test/core/migrations/document_social_metadata_migration_test.dart`

## Support

For issues or questions about the migration:

1. Check the test cases for usage examples
1. Review error messages in the migration results
1. Check app logs for detailed error information
1. Open an issue in the repository with migration results and logs
