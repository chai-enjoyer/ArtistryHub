import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';

class PostProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
      final snapshot = await _firestore.collection('posts').limit(100).get();
      _posts = snapshot.docs.map((doc) => Post.fromJson(doc.data())).toList();
      // Always sort by timestamp descending
      _posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
      await _firestore.collection('posts').doc(post.id).set(post.toJson());
      _posts.add(post);
      // Keep posts sorted by newest first
      _posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addComment(Comment comment) async {
    try {
      await _firestore.collection('comments').doc(comment.id).set(comment.toJson());
      _comments.add(comment);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<Comment>> getCommentsForPost(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .limit(50)
          .get();
      return snapshot.docs.map((doc) => Comment.fromJson(doc.data())).toList();
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