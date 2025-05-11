import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';

class PostProvider with ChangeNotifier {
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
      // TODO: Fetch posts from Supabase
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
      // TODO: Insert post to Supabase
      _posts.add(post);
      _posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addComment(Comment comment) async {
    try {
      // TODO: Add comment to Supabase
      _comments.add(comment);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<Comment>> getCommentsForPost(String postId) async {
    try {
      // TODO: Fetch comments for post from Supabase
      return [];
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