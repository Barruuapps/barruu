# R2 Storage Service Documentation

## Overview

The `R2StorageService` provides a complete solution for file storage using Cloudflare R2 (S3-compatible storage). It includes automatic image optimization, avatar/cover image handling, and batch operations.

## Features

### 1. Image Optimization

- Automatic resizing and compression
- WebP conversion for optimal file sizes
- Quality optimization

### 2. Avatar Upload

- Resizes to 200x200 pixels (square crop from center)
- Converts to WebP format
- Compresses to approximately 20KB
- Stores in `avatars/` directory with user ID

```dart
final result = await r2Service.uploadAvatar(imageFile, userId);
result.when(
  success: (key) => print('Avatar uploaded: $key'),
  error: (msg) => print('Error: $msg'),
);
```text

### 3. Cover Image Upload

- Resizes to max 1200x630 pixels (maintains aspect ratio)
- Converts to WebP format
- Optimized compression
- Stores in `covers/{entityType}/` directory

```dart
final result = await r2Service.uploadCoverImage(imageFile, postId, 'post');
result.when(
  success: (key) => print('Cover uploaded: $key'),
  error: (msg) => print('Error: $msg'),
);
```text

### 4. Generic File Upload

- Supports any file type
- Auto-detects content type from extension
- Custom content type override available

```dart
final result = await r2Service.uploadFile(file, 'documents/doc.pdf');
```text

### 5. App (.bipy) File Upload

- Specialized for .bipy document files
- Includes custom metadata
- Organized in `apps/` directory

```dart
final result = await r2Service.uploadApp(
  bipyFile,
  appName,
  {'version': '1.0.0', 'author': 'username'},
);
```text

### 6. File Download

- Single file download
- Batch download support with error tracking

```dart
// Single download
final result = await r2Service.downloadFile(key, localPath);

// Batch download
final downloads = [
  {'key': 'file1.txt', 'localPath': '/path/to/file1.txt'},
  {'key': 'file2.txt', 'localPath': '/path/to/file2.txt'},
];
final result = await r2Service.batchDownload(downloads);
result.when(
  success: (batchResult) {
    print('Successful: ${batchResult.successful.length}');
    print('Failed: ${batchResult.failed.length}');
  },
  error: (msg) => print('Batch failed: $msg'),
);
```text

### 7. File Deletion

- Delete files by key

```dart
final result = await r2Service.deleteFile(key);
```text

### 8. CDN URL Generation

- Get public CDN URLs for files

```dart
final url = r2Service.getCdnUrl('avatars/user123-1234567890.webp');
```text

## Result Type Pattern

All operations return a `Result<T>` type for type-safe error handling:

```dart
// Using when
result.when(
  success: (value) {
    // Handle success
  },
  error: (message) {
    // Handle error
  },
);

// Using getOrNull
final value = result.getOrNull();
if (value != null) {
  // Use value
}

// Using map for transformation
final urlResult = uploadResult.map((key) => r2Service.getCdnUrl(key));
```text

## Image Optimization Details

### Avatar Optimization

1. **Input**: Any image format (PNG, JPEG, etc.)
1. **Process**:
   - Square crop from center
   - Resize to 200x200 pixels
   - Convert to WebP format
   - Quality: 85%
1. **Output**: WebP image (~20KB)

### Cover Image Optimization

1. **Input**: Any image format
1. **Process**:
   - Resize to max 1200x630 (maintains aspect ratio)
   - Convert to WebP format
   - Quality: 85%
1. **Output**: Optimized WebP image

## Storage Structure

Files are organized in R2 with the following structure:

```text
bucket/
├── avatars/
│   └── {userId}-{timestamp}.webp
├── covers/
│   ├── post/
│   │   └── {postId}-{timestamp}.webp
│   └── profile/
│       └── {userId}-{timestamp}.webp
└── apps/
    └── {appName}-{timestamp}-{filename}.bipy
```text

## Configuration

The service uses configuration from `Environment`:

- `r2Endpoint`: R2 storage endpoint
- `r2AccessKeyId`: Access key ID
- `r2SecretAccessKey`: Secret access key
- `r2BucketName`: Bucket name
- `r2PublicUrl`: Public CDN URL

## Authentication

Uses AWS Signature V4 authentication for R2 compatibility. Authentication is handled automatically for all requests.

## Error Handling

All operations use the Result type pattern:

- **Success**: Contains the value (file key, file, or BatchDownloadResult)
- **Error**: Contains a descriptive error message

Common error scenarios:

- File doesn't exist
- Network failures
- Authentication errors
- Invalid image format
- Upload/download failures

## Testing

Comprehensive tests cover:

- Image optimization logic
- Error handling
- Result type usage
- Batch operations
- Content type detection

To run tests:

```bash
flutter test test/core/services/r2_storage_service_test.dart
```text

## Dependencies

- `pointycastle`: AWS Signature V4 authentication
- `image`: Image processing and optimization
- `http`: HTTP client for R2 API
- `result`: Type-safe error handling

## Performance Considerations

1. **Image Optimization**: Processing happens on the client before upload, reducing upload size and time
1. **Batch Downloads**: Parallel downloads for better performance
1. **CDN URLs**: Use CDN URLs for faster content delivery
1. **WebP Format**: Superior compression compared to PNG/JPEG

## Cost Optimization

Using Cloudflare R2 for file storage provides:

- No egress fees (unlike AWS S3)
- Low storage costs
- CDN integration included

Image optimization reduces:

- Storage costs (smaller files)
- Bandwidth usage
- Load times

## Best Practices

1. **Always use Result type pattern** for error handling
1. **Use avatar upload** for user profile images (optimized size)
1. **Use cover image upload** for post/profile covers
1. **Use batch download** for multiple files to track success/failure
1. **Check CDN URL validity** before use (placeholder domain)
1. **Handle errors gracefully** in the UI

## Migration from Legacy Service

If migrating from the old `lib/features/home/data/r2_storage_service.dart`:

1. Update imports:

   ```dart
   // Old
   import 'package:barruu/features/home/data/r2_storage_service.dart';
   
   // New
   import 'package:barruu/core/services/r2_storage_service.dart';
   ```

1. Update method signatures (now return Result):

   ```dart
   // Old
   final key = await r2Service.uploadApp(file, name, metadata);
   if (key == null) { /* handle error */ }
   
   // New
   final result = await r2Service.uploadApp(file, name, metadata);
   result.when(
     success: (key) { /* use key */ },
     error: (msg) { /* handle error */ },
   );
   ```

1. Use new avatar/cover image methods:

   ```dart
   // Instead of generic uploadFile for avatars
   final result = await r2Service.uploadAvatar(file, userId);
   ```

## Future Enhancements

Potential improvements:

- [ ] Progress callbacks for large uploads
- [ ] Resume interrupted downloads
- [ ] Client-side caching
- [ ] Automatic retry logic
- [ ] Bandwidth throttling options
- [ ] Pre-signed URLs for secure uploads

## Support

For issues or questions about the R2 Storage Service:

1. Check this documentation
1. Review the code comments in `r2_storage_service.dart`
1. Check the test file for usage examples
1. Consult the AI Agent Roadmap for related tasks
