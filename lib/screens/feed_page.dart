import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/post_provider.dart';
import '../widgets/post_card.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).fetchPosts();
      // Always sort posts by newest first after fetching
      Provider.of<PostProvider>(context, listen: false).sortPostsByTimestamp(ascending: false);
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0.5,
          centerTitle: false,
          titleSpacing: 0,
          title: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(
              'ArtistryHub',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -1.5,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.pushNamed(context, '/search');
              },
              tooltip: 'Search',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.tune),
              onSelected: (value) {
                final provider = Provider.of<PostProvider>(context, listen: false);
                if (value == 'time_asc') {
                  provider.sortPostsByTimestamp(ascending: true);
                } else if (value == 'time_desc') {
                  provider.sortPostsByTimestamp(ascending: false);
                } else if (value == 'username') {
                  provider.sortPostsByUsername();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'time_asc',
                  child: Text('Sort by Time (Ascending)'),
                ),
                const PopupMenuItem(
                  value: 'time_desc',
                  child: Text('Sort by Time (Descending)'),
                ),
                const PopupMenuItem(
                  value: 'username',
                  child: Text('Sort by Username'),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Consumer<PostProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Lottie.asset(
                'assets/lottie/loading_music.json',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                repeat: true,
              ),
            );
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red),
                  ),
                ],
              ),
            );
          }
          if (provider.posts.isEmpty) {
            return Center(
              child: Text(
                'No posts yet.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchPosts(),
            color: Colors.black,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 0),
              itemCount: provider.posts.length,
              itemBuilder: (context, index) {
                final post = provider.posts[index];
                return AnimatedSlide(
                  offset: const Offset(0, 0.1),
                  duration: Duration(milliseconds: 300 + index * 50),
                  curve: Curves.easeOut,
                  child: PostCard(post: post),
                );
              },
            ),
          );
        },
      ),
    );
  }
}