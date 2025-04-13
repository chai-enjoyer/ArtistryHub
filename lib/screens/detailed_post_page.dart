import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../providers/post_provider.dart';
import '../widgets/comment_card.dart';
import '../utils/audio_utils.dart';
import 'package:path_provider/path_provider.dart';

class DetailedPostPage extends StatefulWidget {
  final Post post;

  const DetailedPostPage({super.key, required this.post});

  @override
  _DetailedPostPageState createState() => _DetailedPostPageState();
}

class _DetailedPostPageState extends State<DetailedPostPage> {
  final _commentController = TextEditingController();
  String? _errorMessage;
  String? _audioFilePath;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _audioFilePath = result.files.first.path;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking audio file: $e';
      });
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.isNotEmpty || _audioFilePath != null) {
      try {
        String? finalAudioPath;
        AudioMetadata? metadata;
        
        if (_audioFilePath != null) {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = _audioFilePath!.split('/').last;
          final newPath = '${appDir.path}/music_snippets/$fileName';
          await Directory('${appDir.path}/music_snippets').create(recursive: true);
          await File(_audioFilePath!).copy(newPath);
          finalAudioPath = newPath;
          
          // Extract metadata from the audio file
          metadata = await AudioUtils.extractMetadata(newPath);
        }

        final comment = Comment(
          id: DateTime.now().toIso8601String(),
          postId: widget.post.id!,
          username: 'user',
          content: _commentController.text,
          timestamp: DateTime.now(),
          musicSnippetUrl: finalAudioPath,
          musicTitle: metadata?.title,
          musicArtist: metadata?.artist,
          musicCoverUrl: metadata?.coverPath,
        );

        await Provider.of<PostProvider>(context, listen: false).addComment(comment);
        _commentController.clear();
        setState(() {
          _errorMessage = null;
          _audioFilePath = null;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to add comment: $e';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Comment cannot be empty';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Post Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<PostProvider>(
        builder: (context, provider, child) {
          final comments = widget.post.id != null 
              ? provider.getCommentsForPost(widget.post.id!)
              : <Comment>[];
          return Column(
            children: [
              // Post details
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post.username,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.post.content,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    if (widget.post.musicSnippetUrl != null) ...[
                      const SizedBox(height: 8),
                      _MusicPlayer(
                        filePath: widget.post.musicSnippetUrl!,
                        title: widget.post.musicTitle ?? 'Music Snippet',
                        artist: widget.post.musicArtist ?? 'Unknown Artist',
                        coverPath: widget.post.musicCoverUrl,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      AudioUtils.formatTimestamp(widget.post.timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    
                  ],
                ),
              ),
              const Divider(),
              // Comments header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Comments (${comments.length})',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              // Comments list
              Expanded(
                child: comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet.',
                          style: GoogleFonts.poppins(),
                        ),
                      )
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return CommentCard(comment: comments[index]);
                        },
                      ),
              ),
              // Comment input
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    if (_audioFilePath != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.audio_file,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FutureBuilder<AudioMetadata>(
                                future: AudioUtils.extractMetadata(_audioFilePath!),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          snapshot.data!.title,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          snapshot.data!.artist,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Theme.of(context).primaryColor.withOpacity(0.7),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    );
                                  }
                                  return Text(
                                    _audioFilePath!.split('/').last,
                                    style: GoogleFonts.poppins(),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _audioFilePath = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          onPressed: _pickAudio,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: GoogleFonts.poppins(),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addComment,
                          child: Text(
                            'Post',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MusicPlayer extends StatefulWidget {
  final String filePath;
  final String title;
  final String artist;
  final String? coverPath;

  const _MusicPlayer({
    required this.filePath,
    required this.title,
    required this.artist,
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
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/song_cover_placeholder.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/song_cover_placeholder.png',
                      width: 80,
                      height: 80,
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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.artist,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).primaryColor.withOpacity(0.7),
                  fontSize: 12,
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