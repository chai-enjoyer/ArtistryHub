import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/post_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/feed_page.dart';
import 'screens/profile_page.dart';
import 'screens/post_page.dart';
import 'screens/settings_page.dart';
import 'screens/search_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const ArtistryHubApp(),
    ),
  );
}

class ArtistryHubApp extends StatelessWidget {
  const ArtistryHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ArtistryHub',
          theme: themeProvider.isDarkMode
              ? themeProvider.darkTheme
              : themeProvider.lightTheme,
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
          routes: {
            '/feed': (context) => const FeedPage(),
            '/search': (context) => const SearchPage(),
            '/post': (context) => const PostPage(),
            '/profile': (context) => const ProfilePage(),
            '/settings': (context) => const SettingsPage(),
          },
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const FeedPage(),
    const SearchPage(),
    const PostPage(),
    const ProfilePage(),
    const SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        elevation: 0,
        destinations: [
          _buildDestination(
            context,
            index: 0,
            icon: Icons.feed_outlined,
            selectedIcon: Icons.feed,
            label: 'Feed',
          ),
          _buildDestination(
            context,
            index: 1,
            icon: Icons.search_outlined,
            selectedIcon: Icons.search,
            label: 'Search',
          ),
          _buildDestination(
            context,
            index: 2,
            icon: Icons.add_outlined,
            selectedIcon: Icons.add,
            label: 'Post',
          ),
          _buildDestination(
            context,
            index: 3,
            icon: Icons.person_outlined,
            selectedIcon: Icons.person,
            label: 'Profile',
          ),
          _buildDestination(
            context,
            index: 4,
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDestination(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.navigationBarTheme.surfaceTintColor
                : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  size: isSelected ? 32 : 28,
                  color: isSelected
                      ? theme.navigationBarTheme.iconTheme!
                          .resolve({MaterialState.selected})!.color
                      : theme.navigationBarTheme.iconTheme!
                          .resolve({})!.color,
                ),
              ),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  label,
                  style: isSelected
                      ? theme.navigationBarTheme.labelTextStyle!
                          .resolve({MaterialState.selected})
                      : theme.navigationBarTheme.labelTextStyle!.resolve({}),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: isSelected ? 24 : 0,
                color: isSelected ? theme.primaryColor : Colors.transparent,
                margin: const EdgeInsets.only(top: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}