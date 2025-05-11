import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0.5,
        title: Text(
          'Settings',
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 26),
        ),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: Text(
                  'Dark Mode',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                trailing: AnimatedScale(
                  scale: themeProvider.isDarkMode ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Notifications coming soon!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(
                  'Sign Out',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () async {
                  await Provider.of<AuthProvider>(context, listen: false).signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}