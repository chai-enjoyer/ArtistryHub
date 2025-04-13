import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/database_service.dart';

class PostProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Post> _posts = [];
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPosts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _posts = await _dbService.getPosts();
      _comments = await _dbService.getAllComments();
      _error = null;
      print('Fetched ${_posts.length} posts, ${_comments.length} comments');
    } catch (e) {
      _error = e.toString();
      print('Error fetching data: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> insertPost(Post post) async {
    try {
      await _dbService.insertPost(post);
      print('Post added: ${post.content}');
      await fetchPosts();
    } catch (e) {
      print('Error adding post: $e');
      throw Exception('Failed to add post: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> updatePost(Post post) async {
    try {
      await _dbService.updatePost(post);
      await fetchPosts();
    } catch (e) {
      print('Error updating post: $e');
      throw Exception('Failed to update post: $e');
    }
  }

  Future<void> deletePost(String id) async {
    try {
      await _dbService.deletePost(id);
      await fetchPosts();
    } catch (e) {
      print('Error deleting post: $e');
      throw Exception('Failed to delete post: $e');
    }
  }

  Future<void> addComment(Comment comment) async {
    try {
      await _dbService.insertComment(comment);
      print('Comment added: ${comment.content}');
      _comments = await _dbService.getAllComments();
      notifyListeners();
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  List<Comment> getCommentsForPost(String postId) {
    return _comments.where((comment) => comment.postId == postId).toList();
  }
}