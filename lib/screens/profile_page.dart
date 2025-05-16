import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _userProfile = authProvider.user;
      _isLoading = false;
    });
  }

  void _editProfile() {
    final displayNameController = TextEditingController(text: _userProfile?.displayName);
    final bioController = TextEditingController(text: _userProfile?.bio);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Display Name'),
                controller: displayNameController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Bio'),
                controller: bioController,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final user = authProvider.user;
                  if (user != null) {
                    final updates = {
                      'display_name': displayNameController.text,
                      'bio': bioController.text,
                    };
                    await Supabase.instance.client.from('profiles').update(updates).eq('id', user.uid);
                    await authProvider.reloadUserProfile(user.uid);
                    setState(() {
                      _userProfile = authProvider.user;
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Lottie.asset(
            'assets/lottie/loading_music.json',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            repeat: true,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        title: Text(
          'Profile',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 26),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundImage: _userProfile?.photoURL != null ? NetworkImage(_userProfile!.photoURL!) : null,
              child: _userProfile?.photoURL == null ? const Icon(Icons.person, size: 48) : null,
            ),
            const SizedBox(height: 16),
            Text(_userProfile?.displayName ?? _userProfile?.email ?? '', style: theme.textTheme.headlineSmall),
            Text(_userProfile?.bio ?? '', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(children: [Text('${_userProfile?.postCount ?? 0}'), const Text('Posts')]),
                const SizedBox(width: 24),
                Column(children: [Text('${_userProfile?.followerCount ?? 0}'), const Text('Followers')]),
                const SizedBox(width: 24),
                Column(children: [Text('${_userProfile?.followingCount ?? 0}'), const Text('Following')]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}