import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// Converter for DateTime to/from JSON (ISO 8601 strings).
class TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const TimestampConverter();

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

/// User profile model representing a user in the social platform
///
/// This model contains all profile information including:
/// - Basic user information (uid, username, display name)
/// - Profile customization (bio, avatar, cover image)
/// - Social stats (followers, following, posts count)
/// - Professional information (title, organization, profession)
/// - Account metadata (creation date, verification status, account type)
/// - User interests for content personalization
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    /// Unique user identifier (Firebase Auth UID)
    required String uid,

    /// Unique username for the user (e.g., @username)
    /// Must be unique across the platform
    required String username,

    /// Display name shown on profile and posts
    required String displayName,

    /// User bio/description (max 500 characters)
    String? bio,

    /// Profile avatar URL (stored in R2)
    String? avatarUrl,

    /// Profile cover image URL (stored in R2)
    String? coverImageUrl,

    /// Professional title or role
    String? professionalTitle,

    /// Organization or company affiliation
    String? organization,

    /// Website URL
    String? websiteUrl,

    /// Social media links
    Map<String, String>? socialLinks,

    /// Number of followers
    @Default(0) int followersCount,

    /// Number of users being followed
    @Default(0) int followingCount,

    /// Number of published posts
    @Default(0) int postsCount,

    /// Verification status (for verified accounts)
    @Default(false) bool isVerified,

    /// Account type: 'regular' (read-only consumer), 'professional' (expert with knowledge), 'organization' (company/news outlet)
    @Default('regular') String accountType,

    /// Profession/field of expertise (required for professional accounts)
    /// Examples: "Doctor", "Scientist", "Engineer", "Journalist", etc.
    String? profession,

    /// User interests for personalized content feed
    /// Examples: ["Science", "Technology", "Medicine", "Sports"]
    @Default([]) List<String> interests,

    /// Active subscription tier: 'free', 'pro', 'premium'
    @Default('free') String subscriptionTier,

    /// Account creation timestamp
    @TimestampConverter() required DateTime createdAt,

    /// Last profile update timestamp
    @TimestampConverter() required DateTime updatedAt,
  }) = _UserProfile;

  /// Creates a UserProfile from JSON data (Firestore document)
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  /// Creates a new user profile with default values
  factory UserProfile.create({
    required String uid,
    required String username,
    required String displayName,
  }) {
    final now = DateTime.now();
    return UserProfile(
      uid: uid,
      username: username,
      displayName: displayName,
      createdAt: now,
      updatedAt: now,
    );
  }
}
