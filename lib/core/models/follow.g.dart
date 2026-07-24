// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Follow _$FollowFromJson(Map<String, dynamic> json) => _Follow(
  id: json['id'] as String,
  followerId: json['followerId'] as String,
  followingId: json['followingId'] as String,
  createdAt: const FollowTimestampConverter().fromJson(json['createdAt']),
  followerDisplayName: json['followerDisplayName'] as String?,
  followerUsername: json['followerUsername'] as String?,
  followerAvatarUrl: json['followerAvatarUrl'] as String?,
  followingDisplayName: json['followingDisplayName'] as String?,
  followingUsername: json['followingUsername'] as String?,
  followingAvatarUrl: json['followingAvatarUrl'] as String?,
);

Map<String, dynamic> _$FollowToJson(_Follow instance) => <String, dynamic>{
  'id': instance.id,
  'followerId': instance.followerId,
  'followingId': instance.followingId,
  'createdAt': const FollowTimestampConverter().toJson(instance.createdAt),
  'followerDisplayName': instance.followerDisplayName,
  'followerUsername': instance.followerUsername,
  'followerAvatarUrl': instance.followerAvatarUrl,
  'followingDisplayName': instance.followingDisplayName,
  'followingUsername': instance.followingUsername,
  'followingAvatarUrl': instance.followingAvatarUrl,
};
