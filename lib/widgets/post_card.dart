import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/post.dart';
import '../screens/detailed_post_page.dart';
import '../utils/audio_utils.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'post-${post.id}',
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailedPostPage(post: post),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    post.userPhotoUrl != null && post.userPhotoUrl!.isNotEmpty
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(post.userPhotoUrl!),
                          )
                        : const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.username,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Share feature coming soon!',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (post.musicSnippetUrl != null) ...[
                  const SizedBox(height: 12),
                  _MusicPlayer(
                    filePath: post.musicSnippetUrl!,
                    title: post.musicTitle,
                    artist: post.musicArtist,
                    coverPath: post.musicCoverUrl,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  AudioUtils.formatTimestamp(post.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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