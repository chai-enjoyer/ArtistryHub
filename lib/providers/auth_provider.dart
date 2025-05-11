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
    final res = await _supabase.from('profiles').select().eq('id', uid).single();
    _userProfile = UserProfile.fromMap(res);
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
      redirectTo: null, // Set if you use a custom scheme
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _userProfile = null;
    notifyListeners();
  }
}