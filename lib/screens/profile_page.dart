import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart' as local_auth_provider;
import '../models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  final _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = Provider.of<local_auth_provider.AuthProvider>(context, listen: false).user;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        if (!mounted) return;
        setState(() {
          _userProfile = UserProfile.fromFirestore(doc);
          _isLoading = false;
        });
      } else {
        // Create new user profile if it doesn't exist
        final newProfile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoURL: user.photoURL,
        );
        await _firestore.collection('users').doc(user.uid).set(newProfile.toMap());
        if (!mounted) return;
        setState(() {
          _userProfile = newProfile;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      if (pickedFile == null) return;

      // Crop the image before uploading
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
            aspectRatioPickerButtonHidden: false,
          ),
        ],
      );
      if (croppedFile == null || croppedFile.path.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image cropping failed. Please try again.')),
        );
        return;
      }
      debugPrint('Cropped file path: \\${croppedFile.path}');
      final croppedImageFile = File(croppedFile.path);
      if (!croppedImageFile.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cropped file does not exist.')),
        );
        return;
      }
      // Copy to temp directory before upload
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = await croppedImageFile.copy(tempPath);
      debugPrint('Temp file for upload: \\${tempFile.path}');
      if (!tempFile.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Temp file does not exist.')),
        );
        return;
      }

      final user = Provider.of<local_auth_provider.AuthProvider>(context, listen: false).user;
      if (user == null) return;

      setState(() => _isLoading = true);

      // --- Supabase Storage Upload ---
      final supabase = Supabase.instance.client;
      final fileBytes = await tempFile.readAsBytes();
      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageResponse = await supabase.storage.from('profile-pictures').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
      if (storageResponse.isEmpty) {
        throw Exception('Supabase upload failed: Empty response received.');
      }
      // Get public URL
      final publicUrl = supabase.storage.from('profile-pictures').getPublicUrl(fileName);

      // Update user profile in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': publicUrl,
      });

      // Update local state
      if (!mounted) return;
      setState(() {
        _userProfile = UserProfile(
          uid: _userProfile!.uid,
          email: _userProfile!.email,
          displayName: _userProfile!.displayName,
          photoURL: publicUrl,
          bio: _userProfile!.bio,
          postCount: _userProfile!.postCount,
          followerCount: _userProfile!.followerCount,
          followingCount: _userProfile!.followingCount,
        );
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading profile picture: \\${e.toString()}')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _editProfile() {
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
                controller: TextEditingController(text: _userProfile?.displayName),
                onChanged: (value) async {
                  if (_userProfile != null) {
                    await _firestore.collection('users').doc(_userProfile!.uid).update({
                      'displayName': value,
                    });
                    setState(() {
                      _userProfile = UserProfile(
                        uid: _userProfile!.uid,
                        email: _userProfile!.email,
                        displayName: value,
                        photoURL: _userProfile!.photoURL,
                        bio: _userProfile!.bio,
                        postCount: _userProfile!.postCount,
                        followerCount: _userProfile!.followerCount,
                        followingCount: _userProfile!.followingCount,
                      );
                    });
                  }
                },
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Bio'),
                controller: TextEditingController(text: _userProfile?.bio),
                onChanged: (value) async {
                  if (_userProfile != null) {
                    await _firestore.collection('users').doc(_userProfile!.uid).update({
                      'bio': value,
                    });
                    setState(() {
                      _userProfile = UserProfile(
                        uid: _userProfile!.uid,
                        email: _userProfile!.email,
                        displayName: _userProfile!.displayName,
                        photoURL: _userProfile!.photoURL,
                        bio: value,
                        postCount: _userProfile!.postCount,
                        followerCount: _userProfile!.followerCount,
                        followingCount: _userProfile!.followingCount,
                      );
                    });
                  }
                },
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
        centerTitle: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            'Profile',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -1.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _uploadProfilePicture,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundImage: _userProfile?.photoURL != null
                                ? NetworkImage(_userProfile!.photoURL!)
                                : null,
                            backgroundColor: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
                            child: _userProfile?.photoURL == null
                                ? const Icon(Icons.person, size: 44, color: Colors.black)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userProfile?.displayName ?? 'No Name',
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 22),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _userProfile?.bio ?? 'No bio yet',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text('Posts: ${_userProfile?.postCount ?? 0}', style: theme.textTheme.bodySmall),
                              const SizedBox(width: 12),
                              Text('Followers: ${_userProfile?.followerCount ?? 0}', style: theme.textTheme.bodySmall),
                              const SizedBox(width: 12),
                              Text('Following: ${_userProfile?.followingCount ?? 0}', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Divider(color: theme.dividerColor, thickness: 1, height: 1),
                const SizedBox(height: 18),
                DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        labelStyle: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                        unselectedLabelStyle: theme.textTheme.bodyMedium,
                        labelColor: theme.colorScheme.primary,
                        unselectedLabelColor: theme.hintColor,
                        indicatorColor: theme.colorScheme.primary,
                        tabs: const [
                          Tab(text: 'Posts'),
                          Tab(text: 'Followers'),
                          Tab(text: 'Following'),
                        ],
                      ),
                      SizedBox(
                        height: 400,
                        child: TabBarView(
                          children: [
                            _buildPostsTab(),
                            _buildFollowersTab(),
                            _buildFollowingTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('posts')
          .where('userId', isEqualTo: _userProfile?.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          if (snapshot.error.toString().contains('FAILED_PRECONDITION')) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Setting up posts...'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      launchUrl(Uri.parse(
                        'https://console.firebase.google.com/v1/r/project/artistryhub-d82a4/firestore/indexes?create_composite=Ck9wcm9qZWN0cy9hcnRpc3RyeWh1Yi1kODJhNC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvcG9zdHMvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaDQoJdGltZXN0YW1wEAIaDAoIX19uYW1lX18QAg',
                      ));
                    },
                    child: const Text('Create Index'),
                  ),
                ],
              ),
            );
          }
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }

        final posts = snapshot.data!.docs
            .map((doc) => Post.fromJson(doc.data() as Map<String, dynamic>))
            .toList();

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // Add extra bottom padding
            itemCount: posts.length,
            physics: const AlwaysScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                child: PostCard(post: post),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFollowersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_userProfile?.uid)
          .collection('followers')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No followers yet'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final follower = snapshot.data!.docs[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(follower['photoURL'] ?? ''),
              ),
              title: Text(follower['displayName'] ?? ''),
            );
          },
        );
      },
    );
  }

  Widget _buildFollowingTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_userProfile?.uid)
          .collection('following')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Not following anyone yet'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final following = snapshot.data!.docs[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(following['photoURL'] ?? ''),
              ),
              title: Text(following['displayName'] ?? ''),
            );
          },
        );
      },
    );
  }
}