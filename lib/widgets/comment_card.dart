import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../models/comment.dart';
import '../utils/audio_utils.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;

  const CommentCard({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      //margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(

                    child: Icon(Icons.person)
                ),
                const SizedBox(width: 8),
                Text(
                  comment.username,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).primaryColor,
              ),
            ),
            if (comment.musicSnippetUrl != null) ...[
              const SizedBox(height: 8),
              _MusicPlayer(
                filePath: comment.musicSnippetUrl!,
                title: comment.musicTitle ?? 'Music Snippet',
                artist: comment.musicArtist ?? 'Unknown Artist',
                coverPath: comment.musicCoverUrl,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              AudioUtils.formatTimestamp(comment.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(),
          ], 
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
        SnackBar(content: Text('Error playing audio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: widget.coverPath != null
                  ? Image.file(
                      File(widget.coverPath!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/song_cover_placeholder.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/song_cover_placeholder.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
            ),
            MouseRegion(
              child: GestureDetector(
                onTap: _togglePlay,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isPlaying ? 1.0 : 0.0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 48,
                      color: Theme.of(context).cardColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? 'Music Snippet',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.artist != null)
                Text(
                  widget.artist!,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}