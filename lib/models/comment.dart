class Comment {
  final String id;
  final String postId;
  final String username;
  final String content;
  final DateTime timestamp;
  final String? musicSnippetUrl;
  final String? musicTitle;
  final String? musicArtist;
  final String? musicCoverUrl;
  final String? userPhotoUrl;

  Comment({
    required this.id,
    required this.postId,
    required this.username,
    required this.content,
    required this.timestamp,
    this.musicSnippetUrl,
    this.musicTitle,
    this.musicArtist,
    this.musicCoverUrl,
    this.userPhotoUrl,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      username: json['username'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      musicSnippetUrl: json['musicSnippetUrl'] as String?,
      musicTitle: json['musicTitle'] as String?,
      musicArtist: json['musicArtist'] as String?,
      musicCoverUrl: json['musicCoverUrl'] as String?,
      userPhotoUrl: json['userPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'username': username,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'musicSnippetUrl': musicSnippetUrl,
      'musicTitle': musicTitle,
      'musicArtist': musicArtist,
      'musicCoverUrl': musicCoverUrl,
      'userPhotoUrl': userPhotoUrl,
    };
  }
}