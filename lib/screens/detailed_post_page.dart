import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/comment_card.dart';
import '../utils/audio_utils.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

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

          metadata = await AudioUtils.extractMetadata(newPath);
        }

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.user;
        if (user == null) {
          setState(() {
            _errorMessage = 'User not logged in.';
          });
          return;
        }
        // Fetch user profile from Firestore
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        String displayName = user.displayName ?? user.email ?? 'anonymous';
        String? photoURL = user.photoURL;
        if (doc.exists) {
          final profile = UserProfile.fromFirestore(doc);
          if (profile.displayName != null && profile.displayName!.isNotEmpty) {
            displayName = profile.displayName!;
          }
          if (profile.photoURL != null && profile.photoURL!.isNotEmpty) {
            photoURL = profile.photoURL;
          }
        }
        final comment = Comment(
          id: DateTime.now().toIso8601String(),
          postId: widget.post.id!,
          username: displayName,
          userPhotoUrl: photoURL,
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

  Future<String?> _getUserPhotoUrl(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['photoURL'] as String?;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        title: Text(
          'Post',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 26),
        ),
      ),
      body: FutureBuilder<List<Comment>>(
        future: Provider.of<PostProvider>(context, listen: false)
            .getCommentsForPost(widget.post.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Lottie.asset(
                'assets/lottie/loading_music.json',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                repeat: true,
              ),
            );
          }
          final comments = snapshot.data ?? [];
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                widget.post.userId != null
                                    ? FutureBuilder<String?>(
                                        future: _getUserPhotoUrl(widget.post.userId!),
                                        builder: (context, snapshot) {
                                          final photoUrl = snapshot.data;
                                          if (photoUrl != null && photoUrl.isNotEmpty) {
                                            return CircleAvatar(
                                              backgroundImage: NetworkImage(photoUrl),
                                            );
                                          } else {
                                            return const CircleAvatar(
                                              child: Icon(Icons.person),
                                            );
                                          }
                                        },
                                      )
                                    : (widget.post.userPhotoUrl != null && widget.post.userPhotoUrl!.isNotEmpty
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(widget.post.userPhotoUrl!),
                                          )
                                        : const CircleAvatar(child: Icon(Icons.person))),
                                const SizedBox(width: 8),
                                Text(
                                  widget.post.username,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.post.content,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (widget.post.musicSnippetUrl != null) ...[
                              const SizedBox(height: 12),
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
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Comments (${comments.length})',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      comments.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No comments yet.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                return AnimatedSlide(
                                  offset: Offset(0, index * 0.05),
                                  duration:
                                      Duration(milliseconds: 300 + index * 100),
                                  child: CommentCard(comment: comments[index]),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_errorMessage != null)
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (_audioFilePath != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.audio_file,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
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
                                          style: Theme.of(context).textTheme.bodyLarge,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          snapshot.data!.artist,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    );
                                  }
                                  return Text(
                                    _audioFilePath!.split('/').last,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 32,
                              ),
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
                          icon: const Icon(
                            Icons.attach_file,
                            size: 32,
                          ),
                          onPressed: _pickAudio,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: const InputDecoration(
                              hintText: 'Add a comment...',
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _addComment,
                          child: const Text('Post'),
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
        if (widget.coverPath != null)
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: Image.file(
              File(widget.coverPath!),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.music_note,
                size: 64,
              ),
            ),
          )
        else
          const Icon(
            Icons.music_note,
            size: 64,
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.artist,
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