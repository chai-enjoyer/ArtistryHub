import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  UserProfile? _userProfile;

  UserProfile? get user => _userProfile;

  AuthProvider() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session?.user != null) {
        await _loadUserProfile(session!.user.id);
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _loadUserProfile(user.id);
    }
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final res = await _supabase.from('profiles').select().eq('id', uid).single();
      _userProfile = UserProfile.fromMap(res);
    } catch (e) {
      // If not found, create a new profile with minimal info
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final newProfile = {
          'id': user.id,
          'email': user.email,
        };
        await _supabase.from('profiles').insert(newProfile);
        _userProfile = UserProfile.fromMap(newProfile);
      }
    }
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(email: email, password: password);
    if (response.user != null) {
      await _loadUserProfile(response.user!.id);
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    final response = await _supabase.auth.signUp(email: email, password: password);
    if (response.user != null) {
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'email': email,
      });
      await _loadUserProfile(response.user!.id);
    }
  }

  Future<void> signInWithSpotify() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.spotify,
      // No redirectTo for mobile! Supabase will use the correct callback
    );
  }

  Future<void> signInWithGoogle() async {
    // Use OAuthProvider.google for supabase_flutter <2.0.0, which matches your codebase
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      // No redirectTo for mobile! Supabase will use the correct callback
    );
  }

  Future<void> signUpWithGoogle() async {
    await signInWithGoogle();
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _userProfile = null;
    notifyListeners();
  }

  // Public method to reload user profile
  Future<void> reloadUserProfile(String uid) async {
    await _loadUserProfile(uid);
  }
}