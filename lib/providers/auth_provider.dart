import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  // TODO: Use Supabase Auth for user management
  dynamic _user;

  dynamic get user => _user;

  AuthProvider() {
    // TODO: Listen to Supabase auth state changes
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      // TODO: Supabase sign-in
    } catch (e) {
      throw Exception('Email sign-in failed: $e');
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      // TODO: Supabase sign-up
    } catch (e) {
      throw Exception('Sign-up failed: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // TODO: Supabase Google sign-in
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<void> signInWithGitHub() async {
    try {
      // TODO: Supabase GitHub sign-in
    } catch (e) {
      throw Exception('GitHub sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    // TODO: Supabase sign-out
  }
}