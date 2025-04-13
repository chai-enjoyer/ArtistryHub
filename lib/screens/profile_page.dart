import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,

                    child: Icon(Icons.person, size: 50,)),
            const SizedBox(height: 20),
            Text(
              'Username',
              style: Theme.of(context).textTheme.headlineMedium, 
            ),
            const Text('Bio: Aspiring musician'),
            const Text('Posts: 10 | Followers: 100'),
          ],
        ),
      ),
    );
  }
}