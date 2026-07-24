import 'package:barruu/core/models/follow.dart';
import 'package:barruu/core/utils/result.dart';
import 'package:barruu/core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for FollowService (local-first stub, no backend)
final followServiceProvider = Provider<FollowService>((ref) {
  return FollowService();
});

/// Local-first follow service stub.
/// Social follow features are disabled in local-only mode.
/// All methods return empty/no-op results.
class FollowService {
  FollowService();

  Future<Result<Follow>> followUser({
    required String followerId,
    required String followingId,
    dynamic followerProfile,
    dynamic followingProfile,
  }) async {
    logger.w('Follow feature not available in local-first mode');
    return Result.error('Follow feature requires cloud backend');
  }

  Future<Result<void>> unfollowUser(String followerId, String followingId) async {
    return Result.error('Follow feature requires cloud backend');
  }

  Future<bool> isFollowingUser(String followerId, String followingId) async {
    return false;
  }

  Future<Result<List<Follow>>> getFollowers(
    String userId, {
    int limit = 20,
    dynamic startAfterDoc,
  }) async {
    return Result.success([]);
  }

  Future<Result<List<Follow>>> getFollowing(
    String userId, {
    int limit = 20,
    dynamic startAfterDoc,
  }) async {
    return Result.success([]);
  }

  Future<Result<List<String>>> getFollowerIds(String userId) async {
    return Result.success([]);
  }

  Future<Result<List<String>>> getFollowingIds(String userId) async {
    return Result.success([]);
  }

  Future<Result<int>> getFollowerCount(String userId) async {
    return Result.success(0);
  }

  Future<Result<int>> getFollowingCount(String userId) async {
    return Result.success(0);
  }

  Future<Result<Map<String, bool>>> batchCheckFollowing(
    String followerId,
    List<String> userIds,
  ) async {
    final map = <String, bool>{};
    for (final id in userIds) {
      map[id] = false;
    }
    return Result.success(map);
  }
}