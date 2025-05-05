import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      appBar: AppBar(
        title: Text(
          'ArtistryHub',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          PopupMenuButton<String>(
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
      body: Consumer<PostProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 5,
              itemBuilder: (context, index) => AnimatedOpacity(
                opacity: 0.3,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).hintColor,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                ),
              ),
            );
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => provider.fetchPosts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.posts.isEmpty) {
            return Center(
              child: Text(
                'No posts yet.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchPosts(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.posts.length,
              itemBuilder: (context, index) {
                final post = provider.posts[index];
                return AnimatedSlide(
                  offset: Offset(0, index * 0.05),
                  duration: Duration(milliseconds: 300 + index * 100),
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