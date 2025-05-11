import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Email sign-in failed: $e');
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Sign-up failed: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      if (e.toString().contains('is not a subtype of type')) {
        throw Exception('Google sign-in failed due to a platform bug. Please close and restart the app, then try again.');
      }
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> signInWithGitHub() async {
    try {
      final provider = GithubAuthProvider();
      await _auth.signInWithProvider(provider);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw FirebaseAuthException(
          code: e.code,
          email: e.email,
          credential: e.credential,
          message: 'Account exists with different sign-in method. Please sign in with the original provider first, then link your GitHub account from your profile settings.',
        );
      } else {
        throw Exception('GitHub sign-in failed: $e');
      }
    } catch (e) {
      throw Exception('GitHub sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Remove all local profile data
  }
}