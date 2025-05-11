class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final String? bio;
  final int postCount;
  final int followerCount;
  final int followingCount;
  final String? spotifyId;
  final Map<String, dynamic>? metadata;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.bio,
    this.postCount = 0,
    this.followerCount = 0,
    this.followingCount = 0,
    this.spotifyId,
    this.metadata,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['id'] ?? map['uid'],
      email: map['email'] ?? '',
      displayName: map['display_name'],
      photoURL: map['photo_url'],
      bio: map['bio'],
      postCount: map['post_count'] ?? 0,
      followerCount: map['follower_count'] ?? 0,
      followingCount: map['following_count'] ?? 0,
      spotifyId: map['spotify_id'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoURL,
      'bio': bio,
      'post_count': postCount,
      'follower_count': followerCount,
      'following_count': followingCount,
      'spotify_id': spotifyId,
      'metadata': metadata,
    };
  }
}