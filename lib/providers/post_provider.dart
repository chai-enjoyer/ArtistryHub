import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../models/comment.dart';

class PostProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Post> _posts = [];
  final List<Comment> _comments = [];
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
      final data = post.toJson();
      data.removeWhere((key, value) => value == null);
      await _supabase.from('posts').insert(data);
      _posts.add(post);
      _posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    try {
      updates.removeWhere((key, value) => value == null);
      await _supabase.from('posts').update(updates).eq('id', postId);
      await fetchPosts();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update post: $e';
      notifyListeners();
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _supabase.from('posts').delete().eq('id', postId);
      await fetchPosts();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete post: $e';
      notifyListeners();
    }
  }

  Future<void> addComment(Comment comment) async {
    try {
      final data = comment.toJson();
      data.removeWhere((key, value) => value == null);
      await _supabase.from('comments').insert(data);
      _comments.add(comment);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateComment(String commentId, Map<String, dynamic> updates) async {
    try {
      updates.removeWhere((key, value) => value == null);
      await _supabase.from('comments').update(updates).eq('id', commentId);
      await fetchPosts();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update comment: $e';
      notifyListeners();
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _supabase.from('comments').delete().eq('id', commentId);
      await fetchPosts();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete comment: $e';
      notifyListeners();
    }
  }

  Future<List<Comment>> getCommentsForPost(String postId) async {
    try {
      final res = await _supabase.from('comments').select().eq('postId', postId).order('timestamp', ascending: true);
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

  Future<void> likePost(String postId) async {
    try {
      final res = await _supabase.from('posts').select('like_count').eq('id', postId).single();
      final current = (res['like_count'] ?? 0) as int;
      await _supabase.from('posts').update({'like_count': current + 1}).eq('id', postId);
      await fetchPosts();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to like post: $e';
      notifyListeners();
    }
  }

  Future<void> unlikePost(String postId) async {
    try {
      final res = await _supabase.from('posts').select('like_count').eq('id', postId).single();
      final current = (res['like_count'] ?? 0) as int;
      final newCount = current > 0 ? current - 1 : 0;
      await _supabase.from('posts').update({'like_count': newCount}).eq('id', postId);
      await fetchPosts();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to unlike post: $e';
      notifyListeners();
    }
  }

  Future<void> likeComment(String commentId) async {
    try {
      final res = await _supabase.from('comments').select('like_count').eq('id', commentId).single();
      final current = (res['like_count'] ?? 0) as int;
      await _supabase.from('comments').update({'like_count': current + 1}).eq('id', commentId);
      await fetchPosts();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to like comment: $e';
      notifyListeners();
    }
  }

  Future<void> unlikeComment(String commentId) async {
    try {
      final res = await _supabase.from('comments').select('like_count').eq('id', commentId).single();
      final current = (res['like_count'] ?? 0) as int;
      final newCount = current > 0 ? current - 1 : 0;
      await _supabase.from('comments').update({'like_count': newCount}).eq('id', commentId);
      await fetchPosts();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to unlike comment: $e';
      notifyListeners();
    }
  }

  // Removed followUser and unfollowUser from PostProvider. This logic should be handled in the user profile or a dedicated provider.
}