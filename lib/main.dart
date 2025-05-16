import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/post_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/feed_page.dart';
import 'screens/profile_page.dart';
import 'screens/post_page.dart';
import 'screens/search_page.dart';
import 'screens/map_view_page.dart';
import 'screens/settings_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/signin_page.dart';
import 'screens/signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://hnwvrycxqtytoqkpubha.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhud3ZyeWN4cXR5dG9xa3B1YmhhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY5ODkxMjQsImV4cCI6MjA2MjU2NTEyNH0.NBGliFeQ-2rWiFg7ioQtK9yjXKDgj4qwL8QxgfVxXkU',
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const ArtistryHubApp(),
    ),
  );
}

class ArtistryHubApp extends StatelessWidget {
  const ArtistryHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, authProvider, themeProvider, child) {
        final isLoggedIn = authProvider.user != null;
        return MaterialApp(
          title: 'ArtistryHub',
          theme: themeProvider.lightTheme.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(themeProvider.lightTheme.textTheme),
          ),
          darkTheme: themeProvider.darkTheme.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(themeProvider.darkTheme.textTheme),
          ),
          themeMode: ThemeMode.system,
          home: isLoggedIn ? const MainScreen() : const SignInPage(),
          routes: {
            '/signin': (context) => const SignInPage(),
            '/signup': (context) => const SignUpPage(),
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
    const MapViewPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        elevation: 0,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Post',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}