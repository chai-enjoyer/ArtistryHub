import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/post_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/feed_page.dart';
import 'screens/profile_page.dart';
import 'screens/post_page.dart';
import 'screens/search_page.dart';
import 'screens/map_view_page.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as perm;

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
            '/map': (context) => const MapViewPage(),
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
    const MapViewPage(),
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
            icon: Icons.map_outlined,
            selectedIcon: Icons.map,
            label: 'Map',
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.navigationBarTheme.surfaceTintColor?.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: AnimatedScale(
            scale: isSelected ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
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
                            .resolve({WidgetState.selected})!.color
                        : theme.navigationBarTheme.iconTheme!
                            .resolve({})!.color,
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: isSelected
                      ? theme.navigationBarTheme.labelTextStyle!
                          .resolve({WidgetState.selected})!
                      : theme.navigationBarTheme.labelTextStyle!
                          .resolve({})!,
                  child: Text(label),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 2,
                  width: isSelected ? 32 : 0,
                  color: isSelected ? theme.primaryColor : Colors.transparent,
                  margin: const EdgeInsets.only(top: 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}