import 'package:barruu/core/models/user_profile.dart';
import 'package:barruu/core/utils/result.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:barruu/features/workspace/data/sources/user_identity_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for UserService (local-first, no Firebase)
final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.read(userIdentityServiceProvider));
});

/// Local-first user profile service.
/// Stores a single local user profile backed by SharedPreferences.
/// No cloud backend — all data lives on-device.
class UserService {
  final UserIdentityService? _identityService;

  UserService([this._identityService]);

  Future<Result<UserProfile>> createProfile(UserProfile profile) async {
    try {
      await _identityService?.setUserName(profile.displayName);
      logger.i('Local user profile created: ${profile.uid}');
      return Result.success(profile);
    } catch (e, stackTrace) {
      logger.e('Error creating user profile', error: e, stackTrace: stackTrace);
      return Result.error('Failed to create profile: ${e.toString()}');
    }
  }

  Future<Result<UserProfile>> updateProfile(UserProfile profile) async {
    try {
      await _identityService?.setUserName(profile.displayName);
      logger.i('Local user profile updated: ${profile.uid}');
      return Result.success(profile.copyWith(updatedAt: DateTime.now()));
    } catch (e, stackTrace) {
      logger.e('Error updating user profile', error: e, stackTrace: stackTrace);
      return Result.error('Failed to update profile: ${e.toString()}');
    }
  }

  Future<Result<UserProfile>> getProfile(String uid) async {
    try {
      final userId = _identityService != null
          ? await _identityService!.getUserId()
          : uid;
      if (uid != userId) {
        return Result.error('User profile not found');
      }
      final name = _identityService != null
          ? await _identityService!.getUserName()
          : null;
      final profile = UserProfile.create(
        uid: userId,
        username: 'local_user',
        displayName: name ?? 'Local User',
      );
      return Result.success(profile);
    } catch (e, stackTrace) {
      logger.e('Error getting user profile', error: e, stackTrace: stackTrace);
      return Result.error('Failed to load profile: ${e.toString()}');
    }
  }

  Future<Result<UserProfile>> getProfileByUsername(String username) async {
    try {
      final userId = _identityService != null
          ? await _identityService!.getUserId()
          : 'local';
      final name = _identityService != null
          ? await _identityService!.getUserName()
          : null;
      if (username == 'local_user') {
        final profile = UserProfile.create(
          uid: userId,
          username: 'local_user',
          displayName: name ?? 'Local User',
        );
        return Result.success(profile);
      }
      return Result.error('User not found');
    } catch (e, stackTrace) {
      logger.e('Error getting user by username', error: e, stackTrace: stackTrace);
      return Result.error('Failed to load profile: ${e.toString()}');
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    if (username == 'local_user') return true;
    return false;
  }

  Future<Result<void>> deleteProfile(String uid) async {
    return Result.success(null);
  }

  Future<Result<List<UserProfile>>> batchGetProfiles(List<String> uids) async {
    return Result.success([]);
  }

  Future<Result<List<UserProfile>>> searchUsers(String query, {int limit = 20}) async {
    return Result.success([]);
  }

  Future<Result<void>> updateFollowCounts({
    required String uid,
    int? followersIncrement,
    int? followingIncrement,
  }) async {
    return Result.success(null);
  }

  Future<Result<void>> updatePostCount(String uid, int increment) async {
    return Result.success(null);
  }
}