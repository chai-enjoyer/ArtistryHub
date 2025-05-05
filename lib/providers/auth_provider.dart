import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    throw Exception('Google sign-in failed: $e');
  }
}

  Future<void> signInWithMicrosoft(BuildContext context) async {
    try {
      final provider = OAuthProvider('microsoft.com');
      provider.addScope('User.Read');
      provider.setCustomParameters({
        'tenant': '158f15f3-83e0-4906-824c-69bdc50d9d61',
      });
      
      final credential = await _auth.signInWithPopup(provider);
      if (credential.user == null) {
        throw Exception('Microsoft sign-in failed');
      }
    } catch (e) {
      throw Exception('Microsoft sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}