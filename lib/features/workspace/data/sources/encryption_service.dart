import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/constants/app_constants.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show Random;

// Provider for encryption service
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService();
});

/// Manages encryption and decryption operations for documents and data
/// 
/// Security Notes:
/// - Uses app-wide encryption key for .bipy file exports (for cross-device compatibility)
/// - Uses device-specific encryption keys for local data storage
/// - Keys are stored securely in device storage
/// - Uses AES-256 encryption with random IVs
/// - For document-level encryption, user passwords should be used (future enhancement)
class EncryptionService {
  static const String _keyStorageKey = 'barruu_encryption_key_v1';
  
  // App-wide encryption key for .bipy files - consistent across all Barruu installations
  // This allows .bipy files to be opened on any device running Barruu.
  // NOTE: The web app must use the same key + same 32-byte padding scheme.
  // If the web app key ever changes, add the OLD key to [_legacyBipyKeys] so
  // Flutter can still open files created before the change.
  static const String _appWideBipyKey = 'BarruuApp2025SecureKeyV1Fixed';

  /// Legacy candidate keys tried during decryption to maintain backward
  /// compatibility with .bipy files created by older or differently-configured
  /// app builds (e.g. a web version that padded the key differently).
  /// Keys are tried in order; the first that decrypts successfully wins.
  static const List<String> _legacyBipyKeys = [
    // Alternate padding: no trailing zeros (32 chars via different padding char)
    'BarruuApp2025SecureKeyV1Fixed000',
    // Version-bumped key the web app may have adopted
    'BarruuApp2025SecureKeyV2Fixed000',
    'BarruuApp2025SecureKeyV2Fixed',
  ];
  
  enc.Key? _cachedKey;
  enc.Key? _cachedBipyKey;

  /// Gets or generates a device-specific encryption key
  /// 
  /// The key is generated once and stored securely on the device.
  /// This provides basic protection for local data storage.
  Future<enc.Key> get _key async {
    if (_cachedKey != null) return _cachedKey!;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      String? storedKey = prefs.getString(_keyStorageKey);
      
      if (storedKey == null) {
        // Generate a new secure random key
        storedKey = _generateSecureKey();
        await prefs.setString(_keyStorageKey, storedKey);
        logger.i('Generated and stored new encryption key');
      }
      
      _cachedKey = enc.Key.fromUtf8(storedKey.padRight(32, '0').substring(0, 32));
      return _cachedKey!;
    } catch (e, stackTrace) {
      logger.e('Failed to get encryption key, using fallback', error: e, stackTrace: stackTrace);
      // Fallback to a derived key from salt (not ideal but better than hardcoded)
      final fallbackKey = _deriveKeyFromSalt(AppConstants.defaultEncryptionSalt);
      _cachedKey = enc.Key.fromUtf8(fallbackKey.padRight(32, '0').substring(0, 32));
      return _cachedKey!;
    }
  }

  /// Generates a cryptographically secure random key
  String _generateSecureKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';
    final random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Derives a key from a salt (used as fallback only)
  String _deriveKeyFromSalt(String salt) {
    // Simple key derivation - in production, use PBKDF2 or similar
    final hash = salt.codeUnits.fold(0, (sum, byte) => sum + byte * 31);
    return 'derived_key_${hash}_$salt'.padRight(32, '0').substring(0, 32);
  }

  /// Gets the app-wide encryption key for .bipy files
  /// 
  /// This key is consistent across all Barruu installations,
  /// allowing .bipy files to be shared and opened on any device.
  enc.Key get _bipyKey {
    if (_cachedBipyKey != null) return _cachedBipyKey!;
    _cachedBipyKey = enc.Key.fromUtf8(_appWideBipyKey.padRight(32, '0').substring(0, 32));
    return _cachedBipyKey!;
  }

  /// Encrypts a small amount of data
  /// 
  /// Returns encrypted data with IV prepended.
  /// Throws an exception if encryption fails.
  Future<List<int>> encryptBytes(List<int> data) async {
    try {
      final key = await _key;
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(data, iv: iv);
      logger.i('Encrypted ${data.length} bytes');
      return iv.bytes + encrypted.bytes;
    } catch (e, stackTrace) {
      logger.e('Failed to encrypt bytes', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Decrypts data encrypted with [encryptBytes]
  /// 
  /// Expects data with IV prepended (first 16 bytes).
  /// Throws an exception if decryption fails.
  ///
  /// Tries AES-CBC first (current standard). Falls back to AES-SIC for data
  /// encrypted by older app versions that used the encrypt v5 default (SIC mode).
  Future<List<int>> decryptBytes(List<int> encryptedData) async {
    if (encryptedData.length < 16) {
      throw Exception('Invalid data: too short for IV');
    }
    final key = await _key;
    final iv = enc.IV(Uint8List.fromList(encryptedData.sublist(0, 16)));
    final encryptedBytes = Uint8List.fromList(encryptedData.sublist(16));
    try {
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: iv);
      logger.i('Decrypted ${encryptedData.length} bytes (CBC)');
      return decrypted;
    } catch (_) {
      // Fallback: try SIC mode for data written by older app versions.
      logger.w('CBC decryption failed, retrying with legacy SIC mode');
      try {
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.sic));
        final decrypted = encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: iv);
        logger.i('Decrypted ${encryptedData.length} bytes (SIC legacy)');
        return decrypted;
      } catch (e, stackTrace) {
        logger.e('Failed to decrypt bytes', error: e, stackTrace: stackTrace);
        rethrow;
      }
    }
  }

  /// Encrypts data for .bipy files using app-wide key
  /// 
  /// This method uses a consistent app-wide encryption key,
  /// allowing .bipy files to be opened on any Barruu installation.
  /// Returns encrypted data with IV prepended.
  /// Throws an exception if encryption fails.
  Future<List<int>> encryptBipyBytes(List<int> data) async {
    try {
      final key = _bipyKey;
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(data, iv: iv);
      logger.i('Encrypted ${data.length} bytes for .bipy file');
      return iv.bytes + encrypted.bytes;
    } catch (e, stackTrace) {
      logger.e('Failed to encrypt .bipy bytes', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Decrypts data from .bipy files using app-wide key.
  ///
  /// Tries the primary key first with AES-CBC, then AES-SIC (legacy mode),
  /// then each key in [_legacyBipyKeys] with both modes, to support .bipy
  /// files created by older or differently-configured builds (including the
  /// React web app if its key ever diverged).
  ///
  /// Expects data with IV prepended (first 16 bytes).
  /// Throws an exception if ALL candidates fail.
  Future<List<int>> decryptBipyBytes(List<int> encryptedData) async {
    if (encryptedData.length < 16) {
      throw Exception('Invalid data: too short for IV');
    }
    final iv = enc.IV(Uint8List.fromList(encryptedData.sublist(0, 16)));
    final encryptedBytes = Uint8List.fromList(encryptedData.sublist(16));

    // Build the ordered list of candidate (key, mode, label) tuples.
    final candidates = <(enc.Key, enc.AESMode, String)>[
      (_bipyKey, enc.AESMode.cbc, 'primary CBC'),
      (_bipyKey, enc.AESMode.sic, 'primary SIC legacy'),
      for (final rawKey in _legacyBipyKeys) ...[
        (
          enc.Key.fromUtf8(rawKey.padRight(32, '0').substring(0, 32)),
          enc.AESMode.cbc,
          'legacy "$rawKey" CBC',
        ),
        (
          enc.Key.fromUtf8(rawKey.padRight(32, '0').substring(0, 32)),
          enc.AESMode.sic,
          'legacy "$rawKey" SIC',
        ),
      ],
    ];

    Object? lastError;
    for (final (key, mode, label) in candidates) {
      try {
        final encrypter = enc.Encrypter(enc.AES(key, mode: mode));
        final decrypted = encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: iv);
        // Quick sanity check: a valid ZIP starts with PK magic bytes (0x50 0x4B).
        if (decrypted.length >= 2 &&
            decrypted[0] == 0x50 &&
            decrypted[1] == 0x4B) {
          logger.i('Decrypted .bipy (${encryptedData.length} bytes) with $label');
          return decrypted;
        }
        // Decryption "succeeded" but output is not a ZIP — keep trying.
        logger.w('$label produced non-ZIP output; trying next candidate');
      } catch (e) {
        lastError = e;
        logger.w('$label failed: $e');
      }
    }
    logger.e('All decryption candidates exhausted for .bipy file');
    throw Exception(
      'Failed to decrypt .bipy file. '
      'The file may have been created with a different encryption key. '
      'Last error: $lastError',
    );
  }

  /// Encrypts a large file with progress tracking
  /// 
  /// Creates a temporary encrypted file and returns it.
  /// The caller is responsible for managing the temporary file.
  /// 
  /// [onProgress] Optional callback for tracking encryption progress (0.0 to 1.0)
  Future<File> encryptLargeFile(File inputFile, {Function(double)? onProgress}) async {
    try {
      if (kIsWeb) {
        throw Exception('File encryption not supported on web');
      }
      
      final key = await _key;
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final tempDir = await getTemporaryDirectory();
      final outputFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_encrypted.tmp');
      final inputSize = await inputFile.length();
      
      // Validate file size
      if (inputSize > AppConstants.maxFileSize) {
        throw Exception('File too large: $inputSize bytes (max: ${AppConstants.maxFileSize})');
      }
      
      int bytesProcessed = 0;
      final inputStream = inputFile.openRead();
      final outputSink = outputFile.openWrite();
      
      // Write IV at the beginning
      outputSink.add(iv.bytes);
      
      await inputStream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            try {
              final encrypted = encrypter.encryptBytes(data, iv: iv);
              sink.add(encrypted.bytes);
              bytesProcessed += data.length;
              if (onProgress != null) {
                onProgress(bytesProcessed / inputSize);
                logger.i('Encryption progress: ${(bytesProcessed / inputSize * 100).toStringAsFixed(1)}%');
              }
            } catch (e) {
              sink.addError(e);
            }
          },
          handleError: (error, stackTrace, sink) {
            logger.e('Encryption stream error', error: error, stackTrace: stackTrace);
            sink.addError(error, stackTrace);
          },
          handleDone: (sink) {
            sink.close();
          },
        ),
      ).pipe(outputSink);
      
      await outputSink.close();
      logger.i('Encrypted file: ${outputFile.path}');
      return outputFile;
    } catch (e, stackTrace) {
      logger.e('Failed to encrypt file: ${inputFile.path}', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Decrypts a large file with progress tracking
  /// 
  /// Creates a temporary decrypted file and returns it.
  /// The caller is responsible for managing the temporary file.
  /// 
  /// [onProgress] Optional callback for tracking decryption progress (0.0 to 1.0)
  Future<File> decryptLargeFile(File encryptedFile, {Function(double)? onProgress}) async {
    try {
      if (kIsWeb) {
        throw Exception('File decryption not supported on web');
      }
      
      // Read and validate IV
      final ivBytes = await encryptedFile.openRead(0, 16).reduce((a, b) => a + b);
      if (ivBytes.length < 16) {
        throw Exception('Invalid encrypted file: IV incomplete');
      }
      
      final key = await _key;
      final iv = enc.IV(Uint8List.fromList(ivBytes));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final tempDir = await getTemporaryDirectory();
      final outputFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_decrypted.tmp');
      final inputSize = await encryptedFile.length() - 16;
      int bytesProcessed = 0;
      
      final dataStream = encryptedFile.openRead(16);
      final outputSink = outputFile.openWrite();
      
      await dataStream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            try {
              final decrypted = encrypter.decryptBytes(enc.Encrypted(Uint8List.fromList(data)), iv: iv);
              sink.add(decrypted);
              bytesProcessed += data.length;
              if (onProgress != null) {
                onProgress(bytesProcessed / inputSize);
                logger.i('Decryption progress: ${(bytesProcessed / inputSize * 100).toStringAsFixed(1)}%');
              }
            } catch (e) {
              sink.addError(e);
            }
          },
          handleError: (error, stackTrace, sink) {
            logger.e('Decryption stream error', error: error, stackTrace: stackTrace);
            sink.addError(error, stackTrace);
          },
          handleDone: (sink) {
            sink.close();
          },
        ),
      ).pipe(outputSink);
      
      await outputSink.close();
      logger.i('Decrypted file: ${outputFile.path}');
      return outputFile;
    } catch (e, stackTrace) {
      logger.e('Failed to decrypt file: ${encryptedFile.path}', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Encrypts text data
  /// 
  /// Returns base64-encoded encrypted text with IV prepended.
  Future<String> encryptText(String text) async {
    try {
      final key = await _key;
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(text, iv: iv);
      final combined = iv.bytes + encrypted.bytes;
      logger.i('Encrypted text of length ${text.length}');
      return base64Encode(combined);
    } catch (e, stackTrace) {
      logger.e('Failed to encrypt text', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Decrypts text encrypted with [encryptText]
  /// 
  /// Expects base64-encoded data with IV prepended.
  ///
  /// Tries AES-CBC first (current standard). Falls back to AES-SIC for data
  /// encrypted by older app versions that used the encrypt v5 default (SIC mode).
  Future<String> decryptText(String encryptedText) async {
    final combined = base64Decode(encryptedText);
    if (combined.length < 16) {
      throw Exception('Invalid encrypted text: too short for IV');
    }
    final key = await _key;
    final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
    final encryptedBytes = Uint8List.fromList(combined.sublist(16));
    try {
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt(enc.Encrypted(encryptedBytes), iv: iv);
      logger.i('Decrypted text of length ${decrypted.length} (CBC)');
      return decrypted;
    } catch (_) {
      // Fallback: try SIC mode for text encrypted by older app versions.
      logger.w('CBC decryption failed for text, retrying with legacy SIC mode');
      try {
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.sic));
        final decrypted = encrypter.decrypt(enc.Encrypted(encryptedBytes), iv: iv);
        logger.i('Decrypted text of length ${decrypted.length} (SIC legacy)');
        return decrypted;
      } catch (e, stackTrace) {
        logger.e('Failed to decrypt text', error: e, stackTrace: stackTrace);
        rethrow;
      }
    }
  }

  /// Checks if data appears to be encrypted
  /// 
  /// This is a basic check based on data length.
  /// Not foolproof but useful for quick validation.
  bool isEncrypted(List<int> data) {
    final result = data.length >= 16;
    logger.d('Checked encryption status: $result');
    return result;
  }
  
  /// Clears the cached encryption key
  /// 
  /// Forces regeneration on next use. Used primarily for testing.
  void clearCache() {
    _cachedKey = null;
    logger.i('Encryption key cache cleared');
  }
}

// Extension for easy access to encryption service
extension EncryptionServiceExtension on WidgetRef {
  EncryptionService get encryptionService => read(encryptionServiceProvider);
}

// Base64 encoding/decoding utilities
const _base64 = Base64Codec();

String base64Encode(List<int> data) => _base64.encode(data);
List<int> base64Decode(String data) => _base64.decode(data);