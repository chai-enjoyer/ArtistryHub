class Post {
  final String? id;
  final String username;
  final String content;
  final String? musicSnippetUrl;
  final String? musicTitle;
  final String? musicArtist;
  final String? musicCoverUrl;
  final String? userPhotoUrl;
  final DateTime timestamp;
  final String? userId;
  final int likeCount;
  final int commentCount;

  Post({
    this.id,
    required this.username,
    required this.content,
    this.musicSnippetUrl,
    this.musicTitle,
    this.musicArtist,
    this.musicCoverUrl,
    this.userPhotoUrl,
    required this.timestamp,
    this.userId,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'content': content,
      'musicSnippetUrl': musicSnippetUrl,
      'musicTitle': musicTitle,
      'musicArtist': musicArtist,
      'musicCoverUrl': musicCoverUrl,
      'userPhotoUrl': userPhotoUrl,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'like_count': likeCount,
      'comment_count': commentCount,
    };
  }

  factory Post.fromJson(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      username: map['username'],
      content: map['content'],
      musicSnippetUrl: map['musicSnippetUrl'],
      musicTitle: map['musicTitle'],
      musicArtist: map['musicArtist'],
      musicCoverUrl: map['musicCoverUrl'],
      userPhotoUrl: map['userPhotoUrl'],
      timestamp: DateTime.parse(map['timestamp']),
      userId: map['userId'],
      likeCount: map['like_count'] ?? 0,
      commentCount: map['comment_count'] ?? 0,
    );
  }
}