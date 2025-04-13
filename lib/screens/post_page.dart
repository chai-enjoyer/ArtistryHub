import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/post.dart';
import '../providers/post_provider.dart';
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
  String? _fileName;
  AudioMetadata? _audioMetadata;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    print('Pick audio file button pressed');
    try {
      print('Opening file picker...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      print('File picker result: $result');
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        print('Selected file path: ${file.path}');
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = result.files.single.name;
        final newPath = '${appDir.path}/music_snippets/$fileName';
        print('Copying file to: $newPath');
        await Directory('${appDir.path}/music_snippets').create(recursive: true);
        await file.copy(newPath);
        
        final metadata = await AudioUtils.extractMetadata(newPath);
        
        setState(() {
          _selectedFilePath = newPath;
          _fileName = fileName;
          _audioMetadata = metadata;
          _errorMessage = null;
        });
        print('File copied successfully');
      } else {
        setState(() {
          _errorMessage = 'No file selected.';
          _audioMetadata = null;
        });
        print('No file selected');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: $e';
        _audioMetadata = null;
      });
      print('Error picking file: $e');
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.isNotEmpty) {
      setState(() {
        _errorMessage = null;
      });
      try {
        final post = Post(
          id: DateTime.now().toIso8601String(),
          username: 'user',
          content: _contentController.text,
          musicSnippetUrl: _selectedFilePath,
          musicTitle: _audioMetadata?.title,
          musicArtist: _audioMetadata?.artist,
          musicCoverUrl: _audioMetadata?.coverPath,
          timestamp: DateTime.now(),
        );
        await Provider.of<PostProvider>(context, listen: false).insertPost(post);
        _contentController.clear();
        setState(() {
          _selectedFilePath = null;
          _fileName = null;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: 'Share your music or thoughts...',
                      hintStyle: GoogleFonts.poppins(),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(color: Theme.of(context).primaryColor),
                    maxLines: 5,
                  ),
                ),
              ),
              if (_audioMetadata != null)
                Card(
                  child: ListTile(
                    leading: _audioMetadata?.coverPath != null
                        ? Image.file(
                            File(_audioMetadata!.coverPath!),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.music_note),
                    title: Text(
                      _audioMetadata?.title ?? 'Unknown Title',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _audioMetadata?.artist ?? 'Unknown Artist',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedFilePath = null;
                          _fileName = null;
                          _audioMetadata = null;
                        });
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickAudioFile,
                    icon: const Icon(Icons.music_note, size: 28),
                    label: Text(
                      _audioMetadata != null ? 'Change Music' : 'Add Music',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _submitPost,
                    child: Text(
                      'Post',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).highlightColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}