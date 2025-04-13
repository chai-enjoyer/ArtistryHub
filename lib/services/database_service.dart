import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/post.dart';
import '../models/comment.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'artistry_hub.db');
      print('Initializing database at: $path');
      return await openDatabase(
        path,
        version: 3,
        onCreate: (db, version) async {
          print('Creating tables');
          await db.execute('''
            CREATE TABLE posts (
              id TEXT PRIMARY KEY,
              username TEXT,
              content TEXT,
              musicSnippetUrl TEXT,
              musicTitle TEXT,
              musicArtist TEXT,
              musicCoverUrl TEXT,
              timestamp TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE comments (
              id TEXT PRIMARY KEY,
              postId TEXT,
              username TEXT,
              content TEXT,
              musicSnippetUrl TEXT,
              musicTitle TEXT,
              musicArtist TEXT,
              musicCoverUrl TEXT,
              timestamp TEXT,
              FOREIGN KEY (postId) REFERENCES posts (id)
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              ALTER TABLE comments ADD COLUMN musicSnippetUrl TEXT
            ''');
          }
          if (oldVersion < 3) {
            // Add new columns for music metadata
            await db.execute('''
              ALTER TABLE posts ADD COLUMN musicTitle TEXT;
              ALTER TABLE posts ADD COLUMN musicArtist TEXT;
              ALTER TABLE posts ADD COLUMN musicCoverUrl TEXT;
            ''');
            await db.execute('''
              ALTER TABLE comments ADD COLUMN musicTitle TEXT;
              ALTER TABLE comments ADD COLUMN musicArtist TEXT;
              ALTER TABLE comments ADD COLUMN musicCoverUrl TEXT;
            ''');
          }
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      throw Exception('Database init failed: $e');
    }
  }

  Future<void> insertPost(Post post) async {
    final db = await database;
    try {
      final id = await db.insert('posts', post.toJson());
      print('Inserted post with ID: $id, content: ${post.content}');
    } catch (e) {
      print('Error inserting post: $e');
      throw Exception('Insert failed: $e');
    }
  }

  Future<List<Post>> getPosts() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('posts');
      return List.generate(maps.length, (i) => Post.fromJson(maps[i]));
    } catch (e) {
      print('Error querying posts: $e');
      throw Exception('Query failed: $e');
    }
  }

  Future<void> updatePost(Post post) async {
    final db = await database;
    try {
      await db.update(
        'posts',
        post.toJson(),
        where: 'id = ?',
        whereArgs: [post.id],
      );
    } catch (e) {
      print('Error updating post: $e');
      throw Exception('Update failed: $e');
    }
  }

  Future<void> deletePost(String id) async {
    final db = await database;
    try {
      await db.delete('posts', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      print('Error deleting post: $e');
      throw Exception('Delete failed: $e');
    }
  }

  // Comment methods
  Future<void> insertComment(Comment comment) async {
    final db = await database;
    try {
      final id = await db.insert('comments', comment.toJson());
      print('Inserted comment with ID: $id, content: ${comment.content}');
    } catch (e) {
      print('Error inserting comment: $e');
      throw Exception('Insert failed: $e');
    }
  }

  Future<List<Comment>> getAllComments() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('comments');
      return List.generate(maps.length, (i) => Comment.fromJson(maps[i]));
    } catch (e) {
      print('Error querying comments: $e');
      throw Exception('Query failed: $e');
    }
  }
}