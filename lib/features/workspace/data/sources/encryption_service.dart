import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
/// - The BIPY encryption key is loaded from BARRUU_BIPY_KEY in .env.
/// - Device-specific keys are generated once and stored in SharedPreferences.
/// - No encryption secrets are hardcoded in source code.
/// - Uses AES-256-CBC with random IVs.
/// - For document-level encryption, user passwords should be used (future enhancement).
class EncryptionService {
  static const String _keyStorageKey = 'barruu_encryption_key_v1';

  // BIPY encryption key — loaded from environment variable.
  // Must be a 32-character string set in your .env file as:
  //   BARRUU_BIPY_KEY=your-32-character-key-here
  // This key must be identical across all app installations so
  // .bipy files can be opened on any device running Barruu.
  static String get _envBipyKey => dotenv.env['BARRUU_BIPY_KEY'] ?? '';

  static bool get _isBipyKeyConfigured => _envBipyKey.length >= 32;

  // Legacy BIPY keys for backward compatibility with files created by
  // older or differently-configured builds. Comma-separated in:
  //   BARRUU_BIPY_LEGACY_KEYS=key1,key2,key3
  static List<String> get _envLegacyBipyKeys {
    final raw = dotenv.env['BARRUU_BIPY_LEGACY_KEYS'];
    if (raw == null || raw.trim().isEmpty) return [];
    return raw.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList();
  }

  enc.Key? _cachedKey;
  enc.Key? _cachedBipyKey;

  /// Gets or generates a device-specific encryption key.
  ///
  /// The key is generated once and stored in SharedPreferences.
  /// If generation/storage fails, an error is thrown — no fallback key.
  Future<enc.Key> get _key async {
    if (_cachedKey != null) return _cachedKey!;

    final prefs = await SharedPreferences.getInstance();
    String? storedKey = prefs.getString(_keyStorageKey);

    if (storedKey == null) {
      storedKey = _generateSecureKey();
      await prefs.setString(_keyStorageKey, storedKey);
      logger.i('Generated and stored new device encryption key');
    }

    _cachedKey = enc.Key.fromUtf8(storedKey.padRight(32, '0').substring(0, 32));
    return _cachedKey!;
  }

  /// Generates a cryptographically secure random 32-character key.
  String _generateSecureKey() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Gets the app-wide encryption key for .bipy files.
  ///
  /// Loaded from the BARRUU_BIPY_KEY environment variable. Throws
  /// [StateError] if the key is not configured.
  enc.Key get _bipyKey {
    if (_cachedBipyKey != null) return _cachedBipyKey!;
    if (!_isBipyKeyConfigured) {
      throw StateError(
        'BARRUU_BIPY_KEY is not set in .env. Add a 32-character key to enable BIPY encryption.',
      );
    }
    _cachedBipyKey = enc.Key.fromUtf8(
      _envBipyKey.padRight(32, '0').substring(0, 32),
    );
    return _cachedBipyKey!;
  }

  // ---------------------------------------------------------------------------
  // Encrypt / Decrypt — small data (device key)
  // ---------------------------------------------------------------------------

  /// Encrypts a small amount of data. Returns IV + ciphertext.
  Future<List<int>> encryptBytes(List<int> data) async {
    final key = await _key;
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    logger.i('Encrypted ${data.length} bytes');
    return iv.bytes + encrypted.bytes;
  }

  /// Decrypts data encrypted with [encryptBytes].
  ///
  /// Tries AES-CBC first, then AES-SIC for legacy data.
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
      logger.w('CBC decryption failed, retrying with legacy SIC mode');
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.sic));
      final decrypted = encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: iv);
      logger.i('Decrypted ${encryptedData.length} bytes (SIC legacy)');
      return decrypted;
    }
  }

  // ---------------------------------------------------------------------------
  // Encrypt / Decrypt — BIPY files (app-wide key)
  // ---------------------------------------------------------------------------

  /// Encrypts data for .bipy files using the app-wide BIPY key.
  /// Returns IV + ciphertext.
  Future<List<int>> encryptBipyBytes(List<int> data) async {
    final key = _bipyKey;
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    logger.i('Encrypted ${data.length} bytes for .bipy file');
    return iv.bytes + encrypted.bytes;
  }

  /// Decrypts data from .bipy files.
  ///
  /// Tries the primary key (from BARRUU_BIPY_KEY) with AES-CBC and AES-SIC,
  /// then each legacy key (from BARRUU_BIPY_LEGACY_KEYS) with both modes.
  /// Validates output starts with ZIP magic bytes (0x50 0x4B).
  Future<List<int>> decryptBipyBytes(List<int> encryptedData) async {
    if (encryptedData.length < 16) {
      throw Exception('Invalid data: too short for IV');
    }
    final iv = enc.IV(Uint8List.fromList(encryptedData.sublist(0, 16)));
    final encryptedBytes = Uint8List.fromList(encryptedData.sublist(16));

    // Build candidate (key, mode, label) tuples.
    final candidates = <(enc.Key, enc.AESMode, String)>[];

    if (_isBipyKeyConfigured) {
      final primary = _bipyKey;
      candidates.add((primary, enc.AESMode.cbc, 'primary CBC'));
      candidates.add((primary, enc.AESMode.sic, 'primary SIC legacy'));
    }

    for (final rawKey in _envLegacyBipyKeys) {
      final legacyKey = enc.Key.fromUtf8(
        rawKey.padRight(32, '0').substring(0, 32),
      );
      candidates.add((legacyKey, enc.AESMode.cbc, 'legacy "$rawKey" CBC'));
      candidates.add((legacyKey, enc.AESMode.sic, 'legacy "$rawKey" SIC'));
    }

    Object? lastError;
    for (final (key, mode, label) in candidates) {
      try {
        final encrypter = enc.Encrypter(enc.AES(key, mode: mode));
        final decrypted =
            encrypter.decryptBytes(enc.Encrypted(encryptedBytes), iv: iv);
        // Valid ZIP starts with PK magic bytes (0x50 0x4B).
        if (decrypted.length >= 2 &&
            decrypted[0] == 0x50 &&
            decrypted[1] == 0x4B) {
          logger.i('Decrypted .bipy (${encryptedData.length} bytes) with $label');
          return decrypted;
        }
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

  // ---------------------------------------------------------------------------
  // Large file encryption / decryption
  // ---------------------------------------------------------------------------

  static const int _maxFileSize = 100 * 1024 * 1024; // 100 MB

  Future<File> encryptLargeFile(File inputFile, {Function(double)? onProgress}) async {
    if (kIsWeb) throw Exception('File encryption not supported on web');

    final key = await _key;
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final tempDir = await getTemporaryDirectory();
    final outputFile = File(
      '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_encrypted.tmp',
    );
    final inputSize = await inputFile.length();

    if (inputSize > _maxFileSize) {
      throw Exception('File too large: $inputSize bytes (max: $_maxFileSize)');
    }

    int bytesProcessed = 0;
    final inputStream = inputFile.openRead();
    final outputSink = outputFile.openWrite();
    outputSink.add(iv.bytes);

    await inputStream
        .transform(StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            final encrypted = encrypter.encryptBytes(data, iv: iv);
            sink.add(encrypted.bytes);
            bytesProcessed += data.length;
            onProgress?.call(bytesProcessed / inputSize);
          },
          handleDone: (sink) => sink.close(),
        ))
        .pipe(outputSink);

    await outputSink.close();
    logger.i('Encrypted file: ${outputFile.path}');
    return outputFile;
  }

  Future<File> decryptLargeFile(File encryptedFile, {Function(double)? onProgress}) async {
    if (kIsWeb) throw Exception('File decryption not supported on web');

    final ivBytes =
        await encryptedFile.openRead(0, 16).reduce((a, b) => a + b);
    if (ivBytes.length < 16) {
      throw Exception('Invalid encrypted file: IV incomplete');
    }

    final key = await _key;
    final iv = enc.IV(Uint8List.fromList(ivBytes));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final tempDir = await getTemporaryDirectory();
    final outputFile = File(
      '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_decrypted.tmp',
    );
    final inputSize = await encryptedFile.length() - 16;

    int bytesProcessed = 0;
    final dataStream = encryptedFile.openRead(16);
    final outputSink = outputFile.openWrite();

    await dataStream
        .transform(StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (data, sink) {
            final decrypted = encrypter.decryptBytes(
              enc.Encrypted(Uint8List.fromList(data)),
              iv: iv,
            );
            sink.add(decrypted);
            bytesProcessed += data.length;
            onProgress?.call(bytesProcessed / inputSize);
          },
          handleDone: (sink) => sink.close(),
        ))
        .pipe(outputSink);

    await outputSink.close();
    logger.i('Decrypted file: ${outputFile.path}');
    return outputFile;
  }

  // ---------------------------------------------------------------------------
  // Text encryption / decryption
  // ---------------------------------------------------------------------------

  /// Encrypts text — returns base64-encoded IV + ciphertext.
  Future<String> encryptText(String text) async {
    final key = await _key;
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(text, iv: iv);
    return base64Encode(iv.bytes + encrypted.bytes);
  }

  /// Decrypts text. Tries AES-CBC then AES-SIC (legacy).
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
      return encrypter.decrypt(enc.Encrypted(encryptedBytes), iv: iv);
    } catch (_) {
      logger.w('CBC decryption failed for text, retrying with legacy SIC mode');
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.sic));
      return encrypter.decrypt(enc.Encrypted(encryptedBytes), iv: iv);
    }
  }

  bool isEncrypted(List<int> data) => data.length >= 16;

  void clearCache() {
    _cachedKey = null;
    _cachedBipyKey = null;
    logger.i('Encryption key cache cleared');
  }
}

// Extension for easy access to encryption service
extension EncryptionServiceExtension on WidgetRef {
  EncryptionService get encryptionService => read(encryptionServiceProvider);
}

const _base64 = Base64Codec();

/// Base64 encode.
String base64Encode(List<int> data) => _base64.encode(data);

/// Base64 decode.
List<int> base64Decode(String data) => _base64.decode(data);