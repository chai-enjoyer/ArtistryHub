class Post {
  final String? id;
  final String username;
  final String content;
  final String? musicSnippetUrl;
  final String? musicTitle;
  final String? musicArtist;
  final String? musicCoverUrl;
  final DateTime timestamp;

  Post({
    this.id,
    required this.username,
    required this.content,
    this.musicSnippetUrl,
    this.musicTitle,
    this.musicArtist,
    this.musicCoverUrl,
    required this.timestamp,
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
      'timestamp': timestamp.toIso8601String(),
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
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}