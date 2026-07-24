// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => _UserProfile(
  uid: json['uid'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String,
  bio: json['bio'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  coverImageUrl: json['coverImageUrl'] as String?,
  professionalTitle: json['professionalTitle'] as String?,
  organization: json['organization'] as String?,
  websiteUrl: json['websiteUrl'] as String?,
  socialLinks: (json['socialLinks'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
  followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
  postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
  isVerified: json['isVerified'] as bool? ?? false,
  accountType: json['accountType'] as String? ?? 'regular',
  profession: json['profession'] as String?,
  interests:
      (json['interests'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  subscriptionTier: json['subscriptionTier'] as String? ?? 'free',
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$UserProfileToJson(_UserProfile instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'username': instance.username,
      'displayName': instance.displayName,
      'bio': instance.bio,
      'avatarUrl': instance.avatarUrl,
      'coverImageUrl': instance.coverImageUrl,
      'professionalTitle': instance.professionalTitle,
      'organization': instance.organization,
      'websiteUrl': instance.websiteUrl,
      'socialLinks': instance.socialLinks,
      'followersCount': instance.followersCount,
      'followingCount': instance.followingCount,
      'postsCount': instance.postsCount,
      'isVerified': instance.isVerified,
      'accountType': instance.accountType,
      'profession': instance.profession,
      'interests': instance.interests,
      'subscriptionTier': instance.subscriptionTier,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };
