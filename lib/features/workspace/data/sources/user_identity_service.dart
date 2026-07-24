import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Provider for user identity service
final userIdentityServiceProvider = Provider<UserIdentityService>((ref) {
  return UserIdentityService();
});

/// Service for managing user identity locally across app sessions.
/// Uses SharedPreferences with UUID for persistent local identity.
class UserIdentityService {
  static const String _userIdKey = 'user_identity_id';
  static const String _userNameKey = 'user_identity_name';
  static const String _userAvatarKey = 'user_identity_avatar';
  final Uuid _uuid = const Uuid();

  String? _cachedUserId;
  String? _cachedUserName;
  String? _cachedUserAvatar;

  UserIdentityService();

  /// Gets the current user ID, creating a UUID if it doesn't exist.
  /// Persisted in SharedPreferences across sessions.
  Future<String> getUserId() async {
    if (_cachedUserId != null) {
      return _cachedUserId!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString(_userIdKey);

      if (userId == null || userId.isEmpty) {
        userId = _uuid.v4();
        await prefs.setString(_userIdKey, userId);
        logger.i('Created new local user ID: $userId');
      }

      _cachedUserId = userId;
      return userId;
    } catch (e, stackTrace) {
      logger.e('Failed to get user ID', error: e, stackTrace: stackTrace);
      return _uuid.v4();
    }
  }

  /// Gets the stored user display name.
  Future<String?> getUserName() async {
    if (_cachedUserName != null) {
      return _cachedUserName;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString(_userNameKey);
      _cachedUserName = userName;
      return userName;
    } catch (e, stackTrace) {
      logger.e('Failed to get user name', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Sets and persists the user display name locally.
  Future<bool> setUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userNameKey, name);
      _cachedUserName = name;
      logger.i('Set user name locally: $name');
      return true;
    } catch (e, stackTrace) {
      logger.e('Failed to set user name', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Gets the stored avatar key (file path or URL).
  Future<String?> getUserAvatarKey() async {
    if (_cachedUserAvatar != null) return _cachedUserAvatar;
    try {
      final prefs = await SharedPreferences.getInstance();
      final avatar = prefs.getString(_userAvatarKey);
      _cachedUserAvatar = avatar;
      return avatar;
    } catch (e, stackTrace) {
      logger.e('Failed to get user avatar', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Returns the stored avatar URL/key directly (no cloud resolution needed).
  Future<String?> getUserAvatarUrl() async {
    return getUserAvatarKey();
  }

  /// Stores avatar reference locally.
  Future<bool> setUserAvatar(String avatarKeyOrUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userAvatarKey, avatarKeyOrUrl);
      _cachedUserAvatar = avatarKeyOrUrl;
      logger.i('Set user avatar locally: $avatarKeyOrUrl');
      return true;
    } catch (e, stackTrace) {
      logger.e('Failed to set user avatar', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Clears all cached values.
  void clearCache() {
    _cachedUserId = null;
    _cachedUserName = null;
    _cachedUserAvatar = null;
  }
}
