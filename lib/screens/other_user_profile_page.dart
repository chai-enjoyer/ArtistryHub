import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;
  const OtherUserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isFollowing = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkFollowing();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final res = await _supabase.from('profiles').select().eq('id', widget.userId).single();
    setState(() {
      _userProfile = UserProfile.fromMap(res);
      _isLoading = false;
    });
  }

  Future<void> _checkFollowing() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final res = await _supabase.from('follows').select().eq('follower_id', user.id).eq('following_id', widget.userId).maybeSingle();
    setState(() {
      _isFollowing = res != null;
    });
  }

  Future<void> _toggleFollow() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (_isFollowing) {
      await _supabase.from('follows').delete().eq('follower_id', user.id).eq('following_id', widget.userId);
    } else {
      await _supabase.from('follows').insert({
        'follower_id': user.id,
        'following_id': widget.userId,
      });
    }
    await _checkFollowing();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_userProfile == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: Text('User not found.')),
      );
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        title: Text(_userProfile!.displayName ?? _userProfile!.email),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: _userProfile!.photoURL != null ? NetworkImage(_userProfile!.photoURL!) : null,
              child: _userProfile!.photoURL == null ? const Icon(Icons.person, size: 48) : null,
            ),
            const SizedBox(height: 16),
            Text(_userProfile!.displayName ?? '', style: theme.textTheme.headlineSmall),
            Text(_userProfile!.bio ?? '', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(children: [Text('${_userProfile!.postCount}'), const Text('Posts')]),
                const SizedBox(width: 24),
                Column(children: [Text('${_userProfile!.followerCount}'), const Text('Followers')]),
                const SizedBox(width: 24),
                Column(children: [Text('${_userProfile!.followingCount}'), const Text('Following')]),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _toggleFollow,
              child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
            ),
          ],
        ),
      ),
    );
  }
}
