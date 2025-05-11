import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/post.dart';
import '../screens/detailed_post_page.dart';
import '../utils/audio_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final bool sharpStyle;

  const PostCard({super.key, required this.post, this.sharpStyle = true});

  @override
  Widget build(BuildContext context) {
    final safeUsername = post.username.isNotEmpty ? post.username : 'Unknown';
    final safeContent = post.content.isNotEmpty ? post.content : '[No content]';
    final safeTimestamp = post.timestamp;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedSlide(
      offset: const Offset(0, 0.08),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 400),
        child: InkWell(
          borderRadius: BorderRadius.zero,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailedPostPage(post: post),
              ),
            );
          },
          highlightColor: Colors.black.withOpacity(0.03),
          splashColor: Colors.black.withOpacity(0.04),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12), // Add horizontal margin
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              border: Border(bottom: BorderSide(color: Colors.black12, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String?>(
                      future: post.userId != null ? _getUserPhotoUrl(post.userId!) : Future.value(null),
                      builder: (context, snapshot) {
                        final photoUrl = snapshot.data;
                        if (photoUrl != null && photoUrl.isNotEmpty) {
                          return CircleAvatar(
                            backgroundImage: NetworkImage(photoUrl),
                            radius: 20,
                            backgroundColor: Colors.black12,
                          );
                        } else {
                          return CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.black12,
                            child: Icon(Icons.person, size: 20, color: Colors.black),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            safeUsername,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 17,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            safeContent,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: isDark ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.more_vert, color: isDark ? Colors.white54 : Colors.black54, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 13, color: Colors.black38),
                    Text(
                      '  ${AudioUtils.formatTimestamp(safeTimestamp)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black38,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        icon: Icon(Icons.favorite_border, color: Colors.red, size: 24),
                        onPressed: () {
                          // TODO: Add like animation logic
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chat_bubble_outline, size: 16, color: Colors.black54),
                  ],
                ),
                if (post.musicSnippetUrl != null && post.musicSnippetUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _MusicPlayer(
                      filePath: post.musicSnippetUrl!,
                      title: post.musicTitle ?? 'Music Snippet',
                      artist: post.musicArtist ?? 'Unknown Artist',
                      coverPath: post.musicCoverUrl,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _getUserPhotoUrl(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.from('profiles').select('photo_url').eq('id', userId).single();
      return res['photo_url'] as String?;
    } catch (_) {}
    return null;
  }
}

class _MusicPlayer extends StatefulWidget {
  final String filePath;
  final String? title;
  final String? artist;
  final String? coverPath;

  const _MusicPlayer({
    required this.filePath,
    this.title,
    this.artist,
    this.coverPath,
  });

  @override
  _MusicPlayerState createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<_MusicPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.setFilePath(widget.filePath);
        await _audioPlayer.play();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error playing audio: $e',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.coverPath != null && widget.coverPath!.isNotEmpty)
          widget.coverPath!.startsWith('http')
              ? ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  child: Image.network(
                    widget.coverPath!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/song_cover_placeholder.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  child: Image.file(
                    File(widget.coverPath!),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/song_cover_placeholder.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
        else
          Image.asset(
            'assets/song_cover_placeholder.png',
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? 'Music Snippet',
                style: Theme.of(context).textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.artist != null)
                Text(
                  widget.artist!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            size: 32,
          ),
          onPressed: _togglePlay,
        ),
      ],
    );
  }
}