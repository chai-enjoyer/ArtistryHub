import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../models/comment.dart';

class PostProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPosts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _supabase.from('posts').select().order('timestamp', ascending: false);
      _posts = (res as List).map((e) => Post.fromJson(e)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> insertPost(Post post) async {
    try {
      final res = await _supabase.from('posts').insert(post.toJson()).select().single();
      final newPost = Post.fromJson(res);
      _posts.insert(0, newPost);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addComment(Comment comment) async {
    try {
      await _supabase.from('comments').insert(comment.toJson());
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<Comment>> getCommentsForPost(String postId) async {
    try {
      final res = await _supabase.from('comments').select().eq('post_id', postId).order('timestamp');
      return (res as List).map((e) => Comment.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void sortPostsByTimestamp({bool ascending = true}) {
    _posts.sort((a, b) => ascending
        ? a.timestamp.compareTo(b.timestamp)
        : b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  void sortPostsByUsername() {
    _posts.sort((a, b) => a.username.compareTo(b.username));
    notifyListeners();
  }
}