import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Username',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bio: Aspiring musician',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posts: 10 | Followers: 100',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
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
                          height: 200,
                          child: TabBarView(
                            children: [
                              Center(
                                  child: Text(
                                'Posts',
                                style: Theme.of(context).textTheme.bodyMedium,
                              )),
                              Center(
                                  child: Text(
                                'Followers',
                                style: Theme.of(context).textTheme.bodyMedium,
                              )),
                              Center(
                                  child: Text(
                                'Following',
                                style: Theme.of(context).textTheme.bodyMedium,
                              )),
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
}