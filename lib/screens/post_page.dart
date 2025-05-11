import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../models/post.dart';
import '../models/user_profile.dart';
import '../providers/post_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/audio_utils.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _contentController = TextEditingController();
  String? _errorMessage;
  String? _selectedFilePath;
  AudioMetadata? _audioMetadata;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = result.files.single.name;
        final newPath = '${appDir.path}/music_snippets/$fileName';
        await Directory('${appDir.path}/music_snippets').create(recursive: true);
        await file.copy(newPath);

        final metadata = await AudioUtils.extractMetadata(newPath);

        setState(() {
          _selectedFilePath = newPath;
          _audioMetadata = metadata;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'No file selected.';
          _audioMetadata = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: $e';
        _audioMetadata = null;
      });
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.isNotEmpty) {
      setState(() {
        _errorMessage = null;
      });
      try {
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
        final post = Post(
          id: DateTime.now().toIso8601String(),
          username: displayName,
          userPhotoUrl: photoURL,
          content: _contentController.text,
          musicSnippetUrl: _selectedFilePath,
          musicTitle: _audioMetadata?.title,
          musicArtist: _audioMetadata?.artist,
          musicCoverUrl: _audioMetadata?.coverPath,
          timestamp: DateTime.now(),
          userId: user.uid, // Add userId for filtering
        );
        await Provider.of<PostProvider>(context, listen: false).insertPost(post);
        _contentController.clear();
        setState(() {
          _selectedFilePath = null;
          _audioMetadata = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post added successfully!')),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to add post: $e';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Please enter some content';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        title: Text(
          'Create Post',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 26),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        border: InputBorder.none,
                        filled: true,
                        fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface,
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      style: theme.textTheme.bodyLarge,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      opacity: _audioMetadata != null ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _audioMetadata != null
                          ? ListTile(
                              leading: _audioMetadata?.coverPath != null
                                  ? Image.file(
                                      File(_audioMetadata!.coverPath!),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.music_note),
                              title: Text(
                                _audioMetadata?.title ?? 'Unknown Title',
                                style: theme.textTheme.bodyMedium,
                              ),
                              subtitle: Text(
                                _audioMetadata?.artist ?? 'Unknown Artist',
                                style: theme.textTheme.bodySmall,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedFilePath = null;
                                    _audioMetadata = null;
                                  });
                                },
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.music_note),
                          label: const Text('Add Music'),
                          onPressed: _pickAudioFile,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(color: theme.colorScheme.primary),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _submitPost,
                          child: const Text('Post'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage != null && _errorMessage!.contains('loading'))
                      Center(
                        child: Lottie.asset(
                          'assets/lottie/loading_music.json',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                    if (_errorMessage != null && !_errorMessage!.contains('loading'))
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}