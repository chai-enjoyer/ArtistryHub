import 'dart:io';
import 'package:audiotags/audiotags.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class AudioMetadata {
  final String title;
  final String artist;
  final String? coverPath;

  AudioMetadata({
    required this.title,
    required this.artist,
    this.coverPath,
  });
}

class AudioUtils {
  static Future<AudioMetadata> extractMetadata(String filePath) async {
    try {
      final tag = await AudioTags.read(filePath);
      String title = tag?.title ?? path.basename(filePath);
      String artist = tag?.trackArtist ?? 'Unknown Artist';
      String? coverPath;

      if (tag?.pictures != null && tag!.pictures!.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final coverDir = Directory('${appDir.path}/covers');
        await coverDir.create(recursive: true);
        
        final coverFile = File('${coverDir.path}/${path.basenameWithoutExtension(filePath)}_cover.jpg');
        await coverFile.writeAsBytes(tag.pictures!.first.bytes);
        coverPath = coverFile.path;
      }

      return AudioMetadata(
        title: title,
        artist: artist,
        coverPath: coverPath,
      );
    } catch (e) {
      print('Error extracting metadata: $e');
      return AudioMetadata(
        title: path.basename(filePath),
        artist: 'Unknown Artist',
      );
    }
  }

  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
} 