import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:path/path.dart' as path;

/// Utility class for common file system operations
class FileSystemUtils {
  /// Recursively copies a directory from source to target
  static Future<void> copyDirectory(Directory source, Directory target) async {
    if (!await target.exists()) {
      await target.create(recursive: true);
    }

    await for (var entity in source.list(recursive: false)) {
      if (entity is File) {
        final newPath = path.join(target.path, path.basename(entity.path));
        await entity.copy(newPath);
      } else if (entity is Directory) {
        final newDir = Directory(
          path.join(target.path, path.basename(entity.path)),
        );
        await copyDirectory(entity, newDir);
      }
    }
  }

  /// Calculates the total size of a directory in bytes
  static Future<int> getDirectorySize(Directory dir) async {
    int size = 0;

    await for (var entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          final stat = await entity.stat();
          size += stat.size;
        } catch (e) {
          // Skip files we can't access
          logger.w('Failed to get file size: ${entity.path}', error: e);
        }
      }
    }

    return size;
  }

  /// Gets the stat of a file or directory synchronously with error handling
  /// Returns null if stat fails
  static FileStat? statSync(FileSystemEntity entity) {
    try {
      return entity.statSync();
    } catch (e) {
      logger.w('Failed to get stat for: ${entity.path}', error: e);
      return null;
    }
  }
}
