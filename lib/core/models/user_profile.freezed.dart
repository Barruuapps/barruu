// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserProfile {

/// Unique user identifier (Firebase Auth UID)
 String get uid;/// Unique username for the user (e.g., @username)
/// Must be unique across the platform
 String get username;/// Display name shown on profile and posts
 String get displayName;/// User bio/description (max 500 characters)
 String? get bio;/// Profile avatar URL (stored in R2)
 String? get avatarUrl;/// Profile cover image URL (stored in R2)
 String? get coverImageUrl;/// Professional title or role
 String? get professionalTitle;/// Organization or company affiliation
 String? get organization;/// Website URL
 String? get websiteUrl;/// Social media links
 Map<String, String>? get socialLinks;/// Number of followers
 int get followersCount;/// Number of users being followed
 int get followingCount;/// Number of published posts
 int get postsCount;/// Verification status (for verified accounts)
 bool get isVerified;/// Account type: 'regular' (read-only consumer), 'professional' (expert with knowledge), 'organization' (company/news outlet)
 String get accountType;/// Profession/field of expertise (required for professional accounts)
/// Examples: "Doctor", "Scientist", "Engineer", "Journalist", etc.
 String? get profession;/// User interests for personalized content feed
/// Examples: ["Science", "Technology", "Medicine", "Sports"]
 List<String> get interests;/// Active subscription tier: 'free', 'pro', 'premium'
 String get subscriptionTier;/// Account creation timestamp
@TimestampConverter() DateTime get createdAt;/// Last profile update timestamp
@TimestampConverter() DateTime get updatedAt;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.professionalTitle, professionalTitle) || other.professionalTitle == professionalTitle)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.websiteUrl, websiteUrl) || other.websiteUrl == websiteUrl)&&const DeepCollectionEquality().equals(other.socialLinks, socialLinks)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.postsCount, postsCount) || other.postsCount == postsCount)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.profession, profession) || other.profession == profession)&&const DeepCollectionEquality().equals(other.interests, interests)&&(identical(other.subscriptionTier, subscriptionTier) || other.subscriptionTier == subscriptionTier)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,uid,username,displayName,bio,avatarUrl,coverImageUrl,professionalTitle,organization,websiteUrl,const DeepCollectionEquality().hash(socialLinks),followersCount,followingCount,postsCount,isVerified,accountType,profession,const DeepCollectionEquality().hash(interests),subscriptionTier,createdAt,updatedAt]);

@override
String toString() {
  return 'UserProfile(uid: $uid, username: $username, displayName: $displayName, bio: $bio, avatarUrl: $avatarUrl, coverImageUrl: $coverImageUrl, professionalTitle: $professionalTitle, organization: $organization, websiteUrl: $websiteUrl, socialLinks: $socialLinks, followersCount: $followersCount, followingCount: $followingCount, postsCount: $postsCount, isVerified: $isVerified, accountType: $accountType, profession: $profession, interests: $interests, subscriptionTier: $subscriptionTier, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String uid, String username, String displayName, String? bio, String? avatarUrl, String? coverImageUrl, String? professionalTitle, String? organization, String? websiteUrl, Map<String, String>? socialLinks, int followersCount, int followingCount, int postsCount, bool isVerified, String accountType, String? profession, List<String> interests, String subscriptionTier,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? username = null,Object? displayName = null,Object? bio = freezed,Object? avatarUrl = freezed,Object? coverImageUrl = freezed,Object? professionalTitle = freezed,Object? organization = freezed,Object? websiteUrl = freezed,Object? socialLinks = freezed,Object? followersCount = null,Object? followingCount = null,Object? postsCount = null,Object? isVerified = null,Object? accountType = null,Object? profession = freezed,Object? interests = null,Object? subscriptionTier = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,professionalTitle: freezed == professionalTitle ? _self.professionalTitle : professionalTitle // ignore: cast_nullable_to_non_nullable
as String?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String?,websiteUrl: freezed == websiteUrl ? _self.websiteUrl : websiteUrl // ignore: cast_nullable_to_non_nullable
as String?,socialLinks: freezed == socialLinks ? _self.socialLinks : socialLinks // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,postsCount: null == postsCount ? _self.postsCount : postsCount // ignore: cast_nullable_to_non_nullable
as int,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,profession: freezed == profession ? _self.profession : profession // ignore: cast_nullable_to_non_nullable
as String?,interests: null == interests ? _self.interests : interests // ignore: cast_nullable_to_non_nullable
as List<String>,subscriptionTier: null == subscriptionTier ? _self.subscriptionTier : subscriptionTier // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uid,  String username,  String displayName,  String? bio,  String? avatarUrl,  String? coverImageUrl,  String? professionalTitle,  String? organization,  String? websiteUrl,  Map<String, String>? socialLinks,  int followersCount,  int followingCount,  int postsCount,  bool isVerified,  String accountType,  String? profession,  List<String> interests,  String subscriptionTier, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.uid,_that.username,_that.displayName,_that.bio,_that.avatarUrl,_that.coverImageUrl,_that.professionalTitle,_that.organization,_that.websiteUrl,_that.socialLinks,_that.followersCount,_that.followingCount,_that.postsCount,_that.isVerified,_that.accountType,_that.profession,_that.interests,_that.subscriptionTier,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uid,  String username,  String displayName,  String? bio,  String? avatarUrl,  String? coverImageUrl,  String? professionalTitle,  String? organization,  String? websiteUrl,  Map<String, String>? socialLinks,  int followersCount,  int followingCount,  int postsCount,  bool isVerified,  String accountType,  String? profession,  List<String> interests,  String subscriptionTier, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.uid,_that.username,_that.displayName,_that.bio,_that.avatarUrl,_that.coverImageUrl,_that.professionalTitle,_that.organization,_that.websiteUrl,_that.socialLinks,_that.followersCount,_that.followingCount,_that.postsCount,_that.isVerified,_that.accountType,_that.profession,_that.interests,_that.subscriptionTier,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uid,  String username,  String displayName,  String? bio,  String? avatarUrl,  String? coverImageUrl,  String? professionalTitle,  String? organization,  String? websiteUrl,  Map<String, String>? socialLinks,  int followersCount,  int followingCount,  int postsCount,  bool isVerified,  String accountType,  String? profession,  List<String> interests,  String subscriptionTier, @TimestampConverter()  DateTime createdAt, @TimestampConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.uid,_that.username,_that.displayName,_that.bio,_that.avatarUrl,_that.coverImageUrl,_that.professionalTitle,_that.organization,_that.websiteUrl,_that.socialLinks,_that.followersCount,_that.followingCount,_that.postsCount,_that.isVerified,_that.accountType,_that.profession,_that.interests,_that.subscriptionTier,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserProfile implements UserProfile {
  const _UserProfile({required this.uid, required this.username, required this.displayName, this.bio, this.avatarUrl, this.coverImageUrl, this.professionalTitle, this.organization, this.websiteUrl, final  Map<String, String>? socialLinks, this.followersCount = 0, this.followingCount = 0, this.postsCount = 0, this.isVerified = false, this.accountType = 'regular', this.profession, final  List<String> interests = const [], this.subscriptionTier = 'free', @TimestampConverter() required this.createdAt, @TimestampConverter() required this.updatedAt}): _socialLinks = socialLinks,_interests = interests;
  factory _UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);

/// Unique user identifier (Firebase Auth UID)
@override final  String uid;
/// Unique username for the user (e.g., @username)
/// Must be unique across the platform
@override final  String username;
/// Display name shown on profile and posts
@override final  String displayName;
/// User bio/description (max 500 characters)
@override final  String? bio;
/// Profile avatar URL (stored in R2)
@override final  String? avatarUrl;
/// Profile cover image URL (stored in R2)
@override final  String? coverImageUrl;
/// Professional title or role
@override final  String? professionalTitle;
/// Organization or company affiliation
@override final  String? organization;
/// Website URL
@override final  String? websiteUrl;
/// Social media links
 final  Map<String, String>? _socialLinks;
/// Social media links
@override Map<String, String>? get socialLinks {
  final value = _socialLinks;
  if (value == null) return null;
  if (_socialLinks is EqualUnmodifiableMapView) return _socialLinks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Number of followers
@override@JsonKey() final  int followersCount;
/// Number of users being followed
@override@JsonKey() final  int followingCount;
/// Number of published posts
@override@JsonKey() final  int postsCount;
/// Verification status (for verified accounts)
@override@JsonKey() final  bool isVerified;
/// Account type: 'regular' (read-only consumer), 'professional' (expert with knowledge), 'organization' (company/news outlet)
@override@JsonKey() final  String accountType;
/// Profession/field of expertise (required for professional accounts)
/// Examples: "Doctor", "Scientist", "Engineer", "Journalist", etc.
@override final  String? profession;
/// User interests for personalized content feed
/// Examples: ["Science", "Technology", "Medicine", "Sports"]
 final  List<String> _interests;
/// User interests for personalized content feed
/// Examples: ["Science", "Technology", "Medicine", "Sports"]
@override@JsonKey() List<String> get interests {
  if (_interests is EqualUnmodifiableListView) return _interests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_interests);
}

/// Active subscription tier: 'free', 'pro', 'premium'
@override@JsonKey() final  String subscriptionTier;
/// Account creation timestamp
@override@TimestampConverter() final  DateTime createdAt;
/// Last profile update timestamp
@override@TimestampConverter() final  DateTime updatedAt;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&(identical(other.professionalTitle, professionalTitle) || other.professionalTitle == professionalTitle)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.websiteUrl, websiteUrl) || other.websiteUrl == websiteUrl)&&const DeepCollectionEquality().equals(other._socialLinks, _socialLinks)&&(identical(other.followersCount, followersCount) || other.followersCount == followersCount)&&(identical(other.followingCount, followingCount) || other.followingCount == followingCount)&&(identical(other.postsCount, postsCount) || other.postsCount == postsCount)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.accountType, accountType) || other.accountType == accountType)&&(identical(other.profession, profession) || other.profession == profession)&&const DeepCollectionEquality().equals(other._interests, _interests)&&(identical(other.subscriptionTier, subscriptionTier) || other.subscriptionTier == subscriptionTier)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,uid,username,displayName,bio,avatarUrl,coverImageUrl,professionalTitle,organization,websiteUrl,const DeepCollectionEquality().hash(_socialLinks),followersCount,followingCount,postsCount,isVerified,accountType,profession,const DeepCollectionEquality().hash(_interests),subscriptionTier,createdAt,updatedAt]);

@override
String toString() {
  return 'UserProfile(uid: $uid, username: $username, displayName: $displayName, bio: $bio, avatarUrl: $avatarUrl, coverImageUrl: $coverImageUrl, professionalTitle: $professionalTitle, organization: $organization, websiteUrl: $websiteUrl, socialLinks: $socialLinks, followersCount: $followersCount, followingCount: $followingCount, postsCount: $postsCount, isVerified: $isVerified, accountType: $accountType, profession: $profession, interests: $interests, subscriptionTier: $subscriptionTier, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String uid, String username, String displayName, String? bio, String? avatarUrl, String? coverImageUrl, String? professionalTitle, String? organization, String? websiteUrl, Map<String, String>? socialLinks, int followersCount, int followingCount, int postsCount, bool isVerified, String accountType, String? profession, List<String> interests, String subscriptionTier,@TimestampConverter() DateTime createdAt,@TimestampConverter() DateTime updatedAt
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? username = null,Object? displayName = null,Object? bio = freezed,Object? avatarUrl = freezed,Object? coverImageUrl = freezed,Object? professionalTitle = freezed,Object? organization = freezed,Object? websiteUrl = freezed,Object? socialLinks = freezed,Object? followersCount = null,Object? followingCount = null,Object? postsCount = null,Object? isVerified = null,Object? accountType = null,Object? profession = freezed,Object? interests = null,Object? subscriptionTier = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_UserProfile(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,bio: freezed == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,professionalTitle: freezed == professionalTitle ? _self.professionalTitle : professionalTitle // ignore: cast_nullable_to_non_nullable
as String?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as String?,websiteUrl: freezed == websiteUrl ? _self.websiteUrl : websiteUrl // ignore: cast_nullable_to_non_nullable
as String?,socialLinks: freezed == socialLinks ? _self._socialLinks : socialLinks // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,followersCount: null == followersCount ? _self.followersCount : followersCount // ignore: cast_nullable_to_non_nullable
as int,followingCount: null == followingCount ? _self.followingCount : followingCount // ignore: cast_nullable_to_non_nullable
as int,postsCount: null == postsCount ? _self.postsCount : postsCount // ignore: cast_nullable_to_non_nullable
as int,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,profession: freezed == profession ? _self.profession : profession // ignore: cast_nullable_to_non_nullable
as String?,interests: null == interests ? _self._interests : interests // ignore: cast_nullable_to_non_nullable
as List<String>,subscriptionTier: null == subscriptionTier ? _self.subscriptionTier : subscriptionTier // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
