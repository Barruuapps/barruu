import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow.freezed.dart';
part 'follow.g.dart';

/// Converter for DateTime to/from JSON (ISO 8601 strings).
class FollowTimestampConverter implements JsonConverter<DateTime, dynamic> {
  const FollowTimestampConverter();

  @override
  DateTime fromJson(dynamic timestamp) {
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is DateTime) {
      return timestamp;
    }
    throw ArgumentError('Cannot convert $timestamp to DateTime');
  }

  @override
  dynamic toJson(DateTime dateTime) => dateTime.toIso8601String();
}

/// Represents a follow relationship between two users.
/// 
/// The follower is the user who initiated the follow action.
/// The following is the user being followed.
@freezed
abstract class Follow with _$Follow {
  const factory Follow({
    /// Unique follow relationship ID (Firestore document ID)
    required String id,
    
    /// User ID of the follower (the person who follows)
    required String followerId,
    
    /// User ID of the user being followed
    required String followingId,
    
    /// Timestamp when the follow relationship was created
    @FollowTimestampConverter() required DateTime createdAt,
    
    // Optional denormalized data for efficient display
    /// Follower's display name (optional, for efficient UI)
    String? followerDisplayName,
    
    /// Follower's username (optional, for efficient UI)
    String? followerUsername,
    
    /// Follower's avatar URL (optional, for efficient UI)
    String? followerAvatarUrl,
    
    /// Following user's display name (optional, for efficient UI)
    String? followingDisplayName,
    
    /// Following user's username (optional, for efficient UI)
    String? followingUsername,
    
    /// Following user's avatar URL (optional, for efficient UI)
    String? followingAvatarUrl,
  }) = _Follow;

  /// Creates a Follow from JSON data (Firestore document)
  factory Follow.fromJson(Map<String, dynamic> json) =>
      _$FollowFromJson(json);

  /// Creates a new follow relationship with minimal data
  factory Follow.create({
    required String id,
    required String followerId,
    required String followingId,
  }) {
    return Follow(
      id: id,
      followerId: followerId,
      followingId: followingId,
      createdAt: DateTime.now(),
    );
  }
  
  /// Creates a follow relationship with denormalized user data
  factory Follow.createWithUserData({
    required String id,
    required String followerId,
    required String followingId,
    String? followerDisplayName,
    String? followerUsername,
    String? followerAvatarUrl,
    String? followingDisplayName,
    String? followingUsername,
    String? followingAvatarUrl,
  }) {
    return Follow(
      id: id,
      followerId: followerId,
      followingId: followingId,
      createdAt: DateTime.now(),
      followerDisplayName: followerDisplayName,
      followerUsername: followerUsername,
      followerAvatarUrl: followerAvatarUrl,
      followingDisplayName: followingDisplayName,
      followingUsername: followingUsername,
      followingAvatarUrl: followingAvatarUrl,
    );
  }
}
