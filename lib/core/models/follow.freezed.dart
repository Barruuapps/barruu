// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Follow {

/// Unique follow relationship ID (Firestore document ID)
 String get id;/// User ID of the follower (the person who follows)
 String get followerId;/// User ID of the user being followed
 String get followingId;/// Timestamp when the follow relationship was created
@FollowTimestampConverter() DateTime get createdAt;// Optional denormalized data for efficient display
/// Follower's display name (optional, for efficient UI)
 String? get followerDisplayName;/// Follower's username (optional, for efficient UI)
 String? get followerUsername;/// Follower's avatar URL (optional, for efficient UI)
 String? get followerAvatarUrl;/// Following user's display name (optional, for efficient UI)
 String? get followingDisplayName;/// Following user's username (optional, for efficient UI)
 String? get followingUsername;/// Following user's avatar URL (optional, for efficient UI)
 String? get followingAvatarUrl;
/// Create a copy of Follow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowCopyWith<Follow> get copyWith => _$FollowCopyWithImpl<Follow>(this as Follow, _$identity);

  /// Serializes this Follow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Follow&&(identical(other.id, id) || other.id == id)&&(identical(other.followerId, followerId) || other.followerId == followerId)&&(identical(other.followingId, followingId) || other.followingId == followingId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.followerDisplayName, followerDisplayName) || other.followerDisplayName == followerDisplayName)&&(identical(other.followerUsername, followerUsername) || other.followerUsername == followerUsername)&&(identical(other.followerAvatarUrl, followerAvatarUrl) || other.followerAvatarUrl == followerAvatarUrl)&&(identical(other.followingDisplayName, followingDisplayName) || other.followingDisplayName == followingDisplayName)&&(identical(other.followingUsername, followingUsername) || other.followingUsername == followingUsername)&&(identical(other.followingAvatarUrl, followingAvatarUrl) || other.followingAvatarUrl == followingAvatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,followerId,followingId,createdAt,followerDisplayName,followerUsername,followerAvatarUrl,followingDisplayName,followingUsername,followingAvatarUrl);

@override
String toString() {
  return 'Follow(id: $id, followerId: $followerId, followingId: $followingId, createdAt: $createdAt, followerDisplayName: $followerDisplayName, followerUsername: $followerUsername, followerAvatarUrl: $followerAvatarUrl, followingDisplayName: $followingDisplayName, followingUsername: $followingUsername, followingAvatarUrl: $followingAvatarUrl)';
}


}

/// @nodoc
abstract mixin class $FollowCopyWith<$Res>  {
  factory $FollowCopyWith(Follow value, $Res Function(Follow) _then) = _$FollowCopyWithImpl;
@useResult
$Res call({
 String id, String followerId, String followingId,@FollowTimestampConverter() DateTime createdAt, String? followerDisplayName, String? followerUsername, String? followerAvatarUrl, String? followingDisplayName, String? followingUsername, String? followingAvatarUrl
});




}
/// @nodoc
class _$FollowCopyWithImpl<$Res>
    implements $FollowCopyWith<$Res> {
  _$FollowCopyWithImpl(this._self, this._then);

  final Follow _self;
  final $Res Function(Follow) _then;

/// Create a copy of Follow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? followerId = null,Object? followingId = null,Object? createdAt = null,Object? followerDisplayName = freezed,Object? followerUsername = freezed,Object? followerAvatarUrl = freezed,Object? followingDisplayName = freezed,Object? followingUsername = freezed,Object? followingAvatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,followerId: null == followerId ? _self.followerId : followerId // ignore: cast_nullable_to_non_nullable
as String,followingId: null == followingId ? _self.followingId : followingId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,followerDisplayName: freezed == followerDisplayName ? _self.followerDisplayName : followerDisplayName // ignore: cast_nullable_to_non_nullable
as String?,followerUsername: freezed == followerUsername ? _self.followerUsername : followerUsername // ignore: cast_nullable_to_non_nullable
as String?,followerAvatarUrl: freezed == followerAvatarUrl ? _self.followerAvatarUrl : followerAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,followingDisplayName: freezed == followingDisplayName ? _self.followingDisplayName : followingDisplayName // ignore: cast_nullable_to_non_nullable
as String?,followingUsername: freezed == followingUsername ? _self.followingUsername : followingUsername // ignore: cast_nullable_to_non_nullable
as String?,followingAvatarUrl: freezed == followingAvatarUrl ? _self.followingAvatarUrl : followingAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Follow].
extension FollowPatterns on Follow {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Follow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Follow() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Follow value)  $default,){
final _that = this;
switch (_that) {
case _Follow():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Follow value)?  $default,){
final _that = this;
switch (_that) {
case _Follow() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String followerId,  String followingId, @FollowTimestampConverter()  DateTime createdAt,  String? followerDisplayName,  String? followerUsername,  String? followerAvatarUrl,  String? followingDisplayName,  String? followingUsername,  String? followingAvatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Follow() when $default != null:
return $default(_that.id,_that.followerId,_that.followingId,_that.createdAt,_that.followerDisplayName,_that.followerUsername,_that.followerAvatarUrl,_that.followingDisplayName,_that.followingUsername,_that.followingAvatarUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String followerId,  String followingId, @FollowTimestampConverter()  DateTime createdAt,  String? followerDisplayName,  String? followerUsername,  String? followerAvatarUrl,  String? followingDisplayName,  String? followingUsername,  String? followingAvatarUrl)  $default,) {final _that = this;
switch (_that) {
case _Follow():
return $default(_that.id,_that.followerId,_that.followingId,_that.createdAt,_that.followerDisplayName,_that.followerUsername,_that.followerAvatarUrl,_that.followingDisplayName,_that.followingUsername,_that.followingAvatarUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String followerId,  String followingId, @FollowTimestampConverter()  DateTime createdAt,  String? followerDisplayName,  String? followerUsername,  String? followerAvatarUrl,  String? followingDisplayName,  String? followingUsername,  String? followingAvatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _Follow() when $default != null:
return $default(_that.id,_that.followerId,_that.followingId,_that.createdAt,_that.followerDisplayName,_that.followerUsername,_that.followerAvatarUrl,_that.followingDisplayName,_that.followingUsername,_that.followingAvatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Follow implements Follow {
  const _Follow({required this.id, required this.followerId, required this.followingId, @FollowTimestampConverter() required this.createdAt, this.followerDisplayName, this.followerUsername, this.followerAvatarUrl, this.followingDisplayName, this.followingUsername, this.followingAvatarUrl});
  factory _Follow.fromJson(Map<String, dynamic> json) => _$FollowFromJson(json);

/// Unique follow relationship ID (Firestore document ID)
@override final  String id;
/// User ID of the follower (the person who follows)
@override final  String followerId;
/// User ID of the user being followed
@override final  String followingId;
/// Timestamp when the follow relationship was created
@override@FollowTimestampConverter() final  DateTime createdAt;
// Optional denormalized data for efficient display
/// Follower's display name (optional, for efficient UI)
@override final  String? followerDisplayName;
/// Follower's username (optional, for efficient UI)
@override final  String? followerUsername;
/// Follower's avatar URL (optional, for efficient UI)
@override final  String? followerAvatarUrl;
/// Following user's display name (optional, for efficient UI)
@override final  String? followingDisplayName;
/// Following user's username (optional, for efficient UI)
@override final  String? followingUsername;
/// Following user's avatar URL (optional, for efficient UI)
@override final  String? followingAvatarUrl;

/// Create a copy of Follow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowCopyWith<_Follow> get copyWith => __$FollowCopyWithImpl<_Follow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Follow&&(identical(other.id, id) || other.id == id)&&(identical(other.followerId, followerId) || other.followerId == followerId)&&(identical(other.followingId, followingId) || other.followingId == followingId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.followerDisplayName, followerDisplayName) || other.followerDisplayName == followerDisplayName)&&(identical(other.followerUsername, followerUsername) || other.followerUsername == followerUsername)&&(identical(other.followerAvatarUrl, followerAvatarUrl) || other.followerAvatarUrl == followerAvatarUrl)&&(identical(other.followingDisplayName, followingDisplayName) || other.followingDisplayName == followingDisplayName)&&(identical(other.followingUsername, followingUsername) || other.followingUsername == followingUsername)&&(identical(other.followingAvatarUrl, followingAvatarUrl) || other.followingAvatarUrl == followingAvatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,followerId,followingId,createdAt,followerDisplayName,followerUsername,followerAvatarUrl,followingDisplayName,followingUsername,followingAvatarUrl);

@override
String toString() {
  return 'Follow(id: $id, followerId: $followerId, followingId: $followingId, createdAt: $createdAt, followerDisplayName: $followerDisplayName, followerUsername: $followerUsername, followerAvatarUrl: $followerAvatarUrl, followingDisplayName: $followingDisplayName, followingUsername: $followingUsername, followingAvatarUrl: $followingAvatarUrl)';
}


}

/// @nodoc
abstract mixin class _$FollowCopyWith<$Res> implements $FollowCopyWith<$Res> {
  factory _$FollowCopyWith(_Follow value, $Res Function(_Follow) _then) = __$FollowCopyWithImpl;
@override @useResult
$Res call({
 String id, String followerId, String followingId,@FollowTimestampConverter() DateTime createdAt, String? followerDisplayName, String? followerUsername, String? followerAvatarUrl, String? followingDisplayName, String? followingUsername, String? followingAvatarUrl
});




}
/// @nodoc
class __$FollowCopyWithImpl<$Res>
    implements _$FollowCopyWith<$Res> {
  __$FollowCopyWithImpl(this._self, this._then);

  final _Follow _self;
  final $Res Function(_Follow) _then;

/// Create a copy of Follow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? followerId = null,Object? followingId = null,Object? createdAt = null,Object? followerDisplayName = freezed,Object? followerUsername = freezed,Object? followerAvatarUrl = freezed,Object? followingDisplayName = freezed,Object? followingUsername = freezed,Object? followingAvatarUrl = freezed,}) {
  return _then(_Follow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,followerId: null == followerId ? _self.followerId : followerId // ignore: cast_nullable_to_non_nullable
as String,followingId: null == followingId ? _self.followingId : followingId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,followerDisplayName: freezed == followerDisplayName ? _self.followerDisplayName : followerDisplayName // ignore: cast_nullable_to_non_nullable
as String?,followerUsername: freezed == followerUsername ? _self.followerUsername : followerUsername // ignore: cast_nullable_to_non_nullable
as String?,followerAvatarUrl: freezed == followerAvatarUrl ? _self.followerAvatarUrl : followerAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,followingDisplayName: freezed == followingDisplayName ? _self.followingDisplayName : followingDisplayName // ignore: cast_nullable_to_non_nullable
as String?,followingUsername: freezed == followingUsername ? _self.followingUsername : followingUsername // ignore: cast_nullable_to_non_nullable
as String?,followingAvatarUrl: freezed == followingAvatarUrl ? _self.followingAvatarUrl : followingAvatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
