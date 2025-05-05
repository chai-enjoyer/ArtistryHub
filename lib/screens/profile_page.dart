import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
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
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: false,
            aspectRatioPickerButtonHidden: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          // No aspectRatioPresets for other platforms
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

      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      setState(() => _isLoading = true);

      // Upload image to Firebase Storage
      final ref = _storage.ref().child('profile_pictures/${user.uid}');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': croppedFile.path},
      );
      await ref.putFile(tempFile, metadata);
      final photoURL = await ref.getDownloadURL();

      // Update user profile in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': photoURL,
      });

      // Update local state
      setState(() {
        _userProfile = UserProfile(
          uid: _userProfile!.uid,
          email: _userProfile!.email,
          displayName: _userProfile!.displayName,
          photoURL: photoURL,
          bio: _userProfile!.bio,
          postCount: _userProfile!.postCount,
          followerCount: _userProfile!.followerCount,
          followingCount: _userProfile!.followingCount,
        );
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading profile picture: $e')),
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editProfile,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploadProfilePicture,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: _userProfile?.photoURL != null
                              ? NetworkImage(_userProfile!.photoURL!)
                              : null,
                          child: _userProfile?.photoURL == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _userProfile?.displayName ?? 'No Name',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userProfile?.bio ?? 'No bio yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Posts: ${_userProfile?.postCount ?? 0} | '
                    'Followers: ${_userProfile?.followerCount ?? 0} | '
                    'Following: ${_userProfile?.followingCount ?? 0}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        TabBar(
                          labelStyle: Theme.of(context).textTheme.bodyLarge,
                          unselectedLabelStyle:
                              Theme.of(context).textTheme.bodyMedium,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Theme.of(context).hintColor,
                          indicatorColor: Theme.of(context).primaryColor,
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
          .limit(20)
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
                      // Open the Firebase Console URL to create the index
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

        // Use PostCard for consistent style
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final post = Post.fromJson(snapshot.data!.docs[index].data() as Map<String, dynamic>);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: PostCard(post: post),
            );
          },
        );
      },
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';
    if (timestamp is Timestamp) {
      return DateFormat('MMM d, y').format(timestamp.toDate());
    }
    return 'Unknown date';
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