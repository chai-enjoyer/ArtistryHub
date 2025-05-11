import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart';
import '../utils/audio_utils.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;
  final bool sharpStyle;

  const CommentCard({super.key, required this.comment, this.sharpStyle = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedSlide(
      offset: const Offset(0, 0.08),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 400),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12), // Add horizontal margin
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
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
                    future: _getUserPhotoUrl(comment.id),
                    builder: (context, snapshot) {
                      final photoUrl = snapshot.data;
                      if (photoUrl != null && photoUrl.isNotEmpty) {
                        return CircleAvatar(
                          backgroundImage: NetworkImage(photoUrl),
                          radius: 16,
                          backgroundColor: Colors.black12,
                        );
                      } else {
                        return CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black12,
                          child: Icon(Icons.person, size: 16, color: Colors.black),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.username.isNotEmpty ? comment.username : 'Unknown',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          comment.content.isNotEmpty ? comment.content : '[No comment]',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.access_time, size: 13, color: Colors.black38),
                  Text(
                    '  ${AudioUtils.formatTimestamp(comment.timestamp)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black38,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (comment.musicSnippetUrl != null && comment.musicSnippetUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _MusicPlayer(
                    filePath: comment.musicSnippetUrl!,
                    title: comment.musicTitle ?? 'Music Snippet',
                    artist: comment.musicArtist ?? 'Unknown Artist',
                    coverPath: comment.musicCoverUrl,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _getUserPhotoUrl(String userId) async {
    // Fetch user photo URL from Firestore by userId
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['photoURL'] as String?;
      }
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
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/song_cover_placeholder.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  child: Image.file(
                    File(widget.coverPath!),
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/song_cover_placeholder.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
        else
          Image.asset(
            'assets/song_cover_placeholder.png',
            width: 40,
            height: 40,
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