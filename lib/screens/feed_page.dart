import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../widgets/post_card.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).fetchPosts();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ArtistryHub',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
        ),
        // actions: [
        //   Padding(
        //     padding: const EdgeInsets.only(right: 16.0),
        //     child: Badge(
        //       label: const Text('8'), // Example streak count
        //       backgroundColor: Theme.of(context).highlightColor, 
        //       textColor: Colors.black,
        //       child: IconButton(
        //         icon: const Icon(Icons.star, size: 28),
        //         color: Theme.of(context).highlightColor,
        //         onPressed: () {
        //           ScaffoldMessenger.of(context).showSnackBar(
        //             const SnackBar(content: Text('Share Streak: 3 days! Keep sharing!')),
        //           );
        //         },
        //       ),
        //     ),
        //   ),
        // ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: GoogleFonts.poppins(),
                  ),
                  ElevatedButton(
                    onPressed: () => provider.fetchPosts(),
                    child: Text(
                      'Retry',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          }
          if (provider.posts.isEmpty) {
            return Center(
              child: Text(
                'No posts yet. Share something!',
                style: GoogleFonts.poppins(),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchPosts(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              itemCount: provider.posts.length,
              itemBuilder: (context, index) {
                final post = provider.posts[index];
                return PostCard(post: post);
              },
            ),
          );
        },
      ),
    );
  }
}