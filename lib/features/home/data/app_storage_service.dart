import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/constants/meta_file.dart';
import 'package:barruu/features/workspace/data/sources/encryption_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Provider for app storage service
final appStorageServiceProvider = Provider<AppStorageService>((ref) {
  final encryptionService = ref.read(encryptionServiceProvider);
  return AppStorageService(encryptionService);
});

/// Service for managing installed .bipy app files
class AppStorageService {
  final EncryptionService _encryptionService;

  AppStorageService(this._encryptionService);

  /// Gets the directory where installed apps (.bipy files) are stored
  Future<Directory> getAppsDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('App storage not supported on web');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final appsDir = Directory('${appDir.path}/apps');

    if (!await appsDir.exists()) {
      await appsDir.create(recursive: true);
    }

    return appsDir;
  }

  /// Gets all installed .bipy app files
  Future<List<File>> getInstalledApps() async {
    try {
      final appsDir = await getAppsDirectory();

      if (!await appsDir.exists()) {
        return [];
      }

      final entities = await appsDir.list().toList();
      final bipyFiles = entities
          .whereType<File>()
          .where((file) => file.path.endsWith('.${AppFile.extension}'))
          .toList();

      // Sort by modified date (newest first)
      bipyFiles.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      return bipyFiles;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to get installed apps',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Installs an app by copying the .bipy file to the apps directory
  Future<File?> installApp(File sourceFile, {String? customName}) async {
    try {
      if (!sourceFile.path.endsWith('.${AppFile.extension}')) {
        logger.w('Source file is not a .bipy file: ${sourceFile.path}');
        return null;
      }

      if (!await sourceFile.exists()) {
        logger.w('Source file does not exist: ${sourceFile.path}');
        return null;
      }

      final appsDir = await getAppsDirectory();

      // Use custom name if provided, otherwise use original file name
      final fileName = customName ?? path.basename(sourceFile.path);
      final targetPath = '${appsDir.path}/$fileName';

      // Check if file already exists and create unique name if needed
      var finalPath = targetPath;
      var counter = 1;
      while (await File(finalPath).exists()) {
        final nameWithoutExt = fileName.replaceAll('.${AppFile.extension}', '');
        finalPath =
            '${appsDir.path}/${nameWithoutExt}_$counter.${AppFile.extension}';
        counter++;
        if (counter > 100) {
          logger.e('Too many attempts to find unique filename');
          return null;
        }
      }

      // Copy the file
      final targetFile = await sourceFile.copy(finalPath);
      logger.i('App installed successfully: $finalPath');

      return targetFile;
    } catch (e, stackTrace) {
      logger.e('Failed to install app', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Uninstalls an app by deleting the .bipy file
  Future<bool> uninstallApp(File appFile) async {
    try {
      final appsDir = await getAppsDirectory();

      // Verify the file is in the apps directory for safety
      if (!appFile.path.startsWith(appsDir.path)) {
        logger.w(
          'Attempt to delete file outside apps directory: ${appFile.path}',
        );
        return false;
      }

      if (!await appFile.exists()) {
        logger.w('App file does not exist: ${appFile.path}');
        return false;
      }

      // Delete the app file
      await appFile.delete();

      // Delete associated metadata file if it exists
      try {
        final metadataPath = _getAppMetadataFilePath(appFile);
        final metadataFile = File(metadataPath);
        if (await metadataFile.exists()) {
          await metadataFile.delete();
          logger.i('Deleted app metadata: $metadataPath');
        }
      } catch (e) {
        logger.w('Failed to delete metadata file', error: e);
      }

      logger.i('App uninstalled successfully: ${appFile.path}');

      return true;
    } catch (e, stackTrace) {
      logger.e('Failed to uninstall app', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Gets the file size of an app
  Future<int> getAppSize(File appFile) async {
    try {
      if (!await appFile.exists()) {
        return 0;
      }
      final stat = await appFile.stat();
      return stat.size;
    } catch (e) {
      logger.w('Failed to get app size: ${appFile.path}', error: e);
      return 0;
    }
  }

  /// Gets the installation date of an app
  Future<DateTime> getInstallDate(File appFile) async {
    try {
      if (!await appFile.exists()) {
        return DateTime.now();
      }
      final stat = await appFile.stat();
      return stat.modified;
    } catch (e) {
      logger.w('Failed to get install date: ${appFile.path}', error: e);
      return DateTime.now();
    }
  }

  /// Gets a display name for the app from the file name
  String getAppDisplayName(File appFile) {
    final fileName = path.basenameWithoutExtension(appFile.path);
    // Format the name
    return fileName.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  }

  /// Extracts metadata from a .bipy file without fully extracting it
  /// Returns a map with 'name', 'description', 'coverPath' (local path after extraction) etc.
  Future<Map<String, dynamic>?> extractAppMetadata(File appFile) async {
    try {
      if (!await appFile.exists()) {
        logger.w('App file does not exist: ${appFile.path}');
        return null;
      }

      final allBytes = await appFile.readAsBytes();

      // Try decrypting with app-wide key first, fallback to device-specific key
      List<int> decrypted;
      try {
        decrypted = await _encryptionService.decryptBipyBytes(allBytes);
        logger.i('Successfully decrypted .bipy file with app-wide key');
      } catch (e) {
        logger.w(
          'Failed to decrypt with app-wide key, trying device-specific key',
        );
        // Try legacy decryption
        try {
          decrypted = await _encryptionService.decryptBytes(allBytes);
          logger.i(
            'Successfully decrypted .bipy file with device-specific key',
          );
        } catch (e2) {
          logger.e('Failed to decrypt .bipy file with both keys', error: e2);
          throw Exception(
            'Failed to decrypt .bipy file. File may be corrupted or from an incompatible source.',
          );
        }
      }

      // Try to decode the archive - will throw if not a valid ZIP
      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(Uint8List.fromList(decrypted));
      } catch (e) {
        logger.e(
          'Failed to load .bipy file - not a valid ZIP archive',
          error: e,
        );
        return null;
      }

      // Build a filename-to-file mapping for efficient lookup
      final fileMap = <String, ArchiveFile>{};
      for (final file in archive.files) {
        if (file.isFile) {
          final fileName = file.name.split('/').last;
          fileMap[fileName] = file;
        }
      }

      // Find and parse meta.json
      for (final file in archive.files) {
        if (file.name.endsWith('/${MetaFile.fileName}') ||
            file.name == MetaFile.fileName) {
          try {
            final metaContent = utf8.decode(file.content as List<int>);
            final metaData = jsonDecode(metaContent) as Map<String, dynamic>;

            // Extract cover image path from archive using the file map
            String? coverImagePath;
            final coverKey = metaData[MetaFile.coverKey] as String?;
            if (coverKey != null && coverKey.isNotEmpty) {
              final coverFileName = coverKey.split('/').last;
              final imageFile = fileMap[coverFileName];
              if (imageFile != null) {
                // Use app documents directory for persistent cache
                final appDocsDir = await getApplicationDocumentsDirectory();
                final appId = path.basenameWithoutExtension(appFile.path);
                final coverCachePath =
                    '${appDocsDir.path}/app_covers/$appId/$coverFileName';
                final coverFile = File(coverCachePath);

                // Only write if not already cached
                if (!await coverFile.exists()) {
                  await coverFile.parent.create(recursive: true);
                  await coverFile.writeAsBytes(imageFile.content as List<int>);
                }
                coverImagePath = coverCachePath;
              }
            }

            return {
              MetaFile.nameKey:
                  metaData[MetaFile.nameKey] ?? getAppDisplayName(appFile),
              MetaFile.descriptionKey: metaData[MetaFile.descriptionKey] ?? '',
              MetaFile.coverKey: coverImagePath,
              MetaFile.authorKey: metaData[MetaFile.authorKey] ?? 'Unknown',
              MetaFile.createdAtKey: metaData[MetaFile.createdAtKey],
              MetaFile.updatedAtKey: metaData[MetaFile.updatedAtKey],
            };
          } catch (e) {
            logger.w('Failed to parse metadata from .bipy file', error: e);
          }
        }
      }

      // Fallback to file name if no metadata found
      return {
        MetaFile.nameKey: getAppDisplayName(appFile),
        MetaFile.descriptionKey: '',
        MetaFile.coverKey: null,
        MetaFile.authorKey: 'Unknown',
      };
    } catch (e, stackTrace) {
      logger.e(
        'Failed to extract app metadata',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Cache for extracted app metadata
  final Map<String, Map<String, dynamic>> _metadataCache = {};

  /// Gets cached metadata for an app, extracting it if not cached
  Future<Map<String, dynamic>?> getCachedAppMetadata(File appFile) async {
    final cacheKey = appFile.path;
    if (_metadataCache.containsKey(cacheKey)) {
      return _metadataCache[cacheKey];
    }

    final metadata = await extractAppMetadata(appFile);
    if (metadata != null) {
      _metadataCache[cacheKey] = metadata;
    }
    return metadata;
  }

  /// Clears the metadata cache
  void clearMetadataCache() {
    _metadataCache.clear();
  }

  /// Gets the metadata file path for an app
  String _getAppMetadataFilePath(File appFile) {
    final appPath = appFile.path;
    final metadataPath = appPath.replaceAll(
      '.${AppFile.extension}',
      '.meta.json',
    );
    return metadataPath;
  }

  /// Saves additional app metadata (like icon URL and app name)
  Future<void> saveAppMetadata(
    File appFile, {
    String? iconUrl,
    String? appName,
    String? version,
    String? storeAppId,
  }) async {
    try {
      final metadataPath = _getAppMetadataFilePath(appFile);
      final metadataFile = File(metadataPath);

      // Load existing metadata if it exists
      Map<String, dynamic> metadata = {};
      if (await metadataFile.exists()) {
        try {
          final content = await metadataFile.readAsString();
          metadata = jsonDecode(content) as Map<String, dynamic>;
        } catch (e) {
          logger.w('Failed to read existing metadata, creating new', error: e);
        }
      }

      // Update metadata
      if (iconUrl != null) {
        metadata['icon_url'] = iconUrl;
      }
      if (appName?.isNotEmpty ?? false) {
        metadata['app_name'] = appName;
      }
      if (version?.isNotEmpty ?? false) {
        metadata['version'] = version;
      }
      if (storeAppId?.isNotEmpty ?? false) {
        metadata['store_app_id'] = storeAppId;
      }
      metadata['updated_at'] = DateTime.now().toIso8601String();

      // Save metadata
      await metadataFile.writeAsString(jsonEncode(metadata));
      logger.i('Saved app metadata: $metadataPath');
    } catch (e, stackTrace) {
      logger.e('Failed to save app metadata', error: e, stackTrace: stackTrace);
    }
  }

  /// Loads additional app metadata (like icon URL from server)
  Future<Map<String, dynamic>?> loadAppMetadata(File appFile) async {
    try {
      final metadataPath = _getAppMetadataFilePath(appFile);
      final metadataFile = File(metadataPath);

      if (!await metadataFile.exists()) {
        return null;
      }

      final content = await metadataFile.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e, stackTrace) {
      logger.e('Failed to load app metadata', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Gets the icon URL for an installed app
  /// Returns the icon URL from server metadata if available, null otherwise
  Future<String?> getAppIconUrl(File appFile) async {
    try {
      final metadata = await loadAppMetadata(appFile);
      return metadata?['icon_url'] as String?;
    } catch (e) {
      logger.w('Failed to get app icon URL', error: e);
      return null;
    }
  }

  /// Gets the human-readable display name for an installed app.
  ///
  /// Resolution order:
  /// 1. `app_name` field in the sidecar `.meta.json` (written at install time – fast).
  /// 2. `name` field inside the `.bipy` archive's `meta.json` (cached after
  ///    first load – handles apps installed before this field was saved).
  /// 3. Falls back to a name derived from the filename as a last resort.
  Future<String> getAppName(File appFile) async {
    try {
      // 1. Fast path – sidecar metadata written during install
      final sidecar = await loadAppMetadata(appFile);
      final sidecarName = sidecar?['app_name'] as String?;
      if (sidecarName != null && sidecarName.isNotEmpty) {
        return sidecarName;
      }
    } catch (e) {
      logger.w('Failed to read sidecar app_name', error: e);
    }
    try {
      // 2. Slower path – read from inside the .bipy archive (cached)
      final archiveMeta = await getCachedAppMetadata(appFile);
      final archiveName = archiveMeta?[MetaFile.nameKey] as String?;
      if (archiveName != null && archiveName.isNotEmpty) {
        return archiveName;
      }
    } catch (e) {
      logger.w('Failed to read archive app name', error: e);
    }
    // 3. Last resort – derive from filename
    return getAppDisplayName(appFile);
  }

  /// Checks if an app with the given name is already installed
  /// Returns the installed app file if found, null otherwise
  Future<File?> findInstalledAppByName(String appName) async {
    try {
      final installedApps = await getInstalledApps();

      for (final appFile in installedApps) {
        // 1. Check sidecar .meta.json app_name (fast, written at install time)
        try {
          final sidecar = await loadAppMetadata(appFile);
          final sidecarName = sidecar?['app_name'] as String?;
          if (sidecarName != null &&
              sidecarName.isNotEmpty &&
              sidecarName.toLowerCase() == appName.toLowerCase()) {
            return appFile;
          }
        } catch (_) {}

        // 2. Check name inside the .bipy archive's meta.json (cached)
        final metadata = await getCachedAppMetadata(appFile);
        if (metadata != null) {
          final installedAppName = metadata[MetaFile.nameKey] as String?;
          if (installedAppName != null && installedAppName == appName) {
            return appFile;
          }
        }

        // 3. Fall back to filename-derived display name
        final fileName = getAppDisplayName(appFile);
        if (fileName.toLowerCase() == appName.toLowerCase()) {
          return appFile;
        }
      }

      return null;
    } catch (e, stackTrace) {
      logger.e(
        'Failed to check if app is installed',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Checks if an app with the given name is already installed
  Future<bool> isAppInstalled(String appName) async {
    final installedApp = await findInstalledAppByName(appName);
    return installedApp != null;
  }

  /// Updates an existing installed app with a new version
  /// Returns the updated app file if successful, null otherwise
  Future<File?> updateApp(File sourceFile, File existingApp) async {
    try {
      if (!sourceFile.path.endsWith('.${AppFile.extension}')) {
        logger.w('Source file is not a .bipy file: ${sourceFile.path}');
        return null;
      }

      if (!await sourceFile.exists()) {
        logger.w('Source file does not exist: ${sourceFile.path}');
        return null;
      }

      if (!await existingApp.exists()) {
        logger.w('Existing app file does not exist: ${existingApp.path}');
        return null;
      }

      final appsDir = await getAppsDirectory();

      // Verify the existing file is in the apps directory for safety
      if (!existingApp.path.startsWith(appsDir.path)) {
        logger.w(
          'Attempt to update file outside apps directory: ${existingApp.path}',
        );
        return null;
      }

      // Delete the old app file
      await existingApp.delete();

      // Clear metadata cache for the old file
      _metadataCache.remove(existingApp.path);

      // Copy the new version to the same location
      final updatedFile = await sourceFile.copy(existingApp.path);
      logger.i('App updated successfully: ${existingApp.path}');

      return updatedFile;
    } catch (e, stackTrace) {
      logger.e('Failed to update app', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}
