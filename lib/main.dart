import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
import 'screens/login_page.dart';
import 'screens/settings_page.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://sazlrtzirvbmuesbfxez.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNhemxydHppcnZibXVlc2JmeGV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0NjI5ODQsImV4cCI6MjA2MjAzODk4NH0.rnoWfWhEDTHVuPIGz3cnBlrTosas612tQThgZQHz_s0',
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
        return MaterialApp(
          title: 'ArtistryHub',
          theme: themeProvider.lightTheme.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(themeProvider.lightTheme.textTheme),
          ),
          darkTheme: themeProvider.darkTheme.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(themeProvider.darkTheme.textTheme),
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: authProvider.user == null ? const LoginPage() : const MainScreen(),
          debugShowCheckedModeBanner: false,
          onGenerateRoute: (settings) {
            WidgetBuilder builder;
            switch (settings.name) {
              case '/feed':
                builder = (context) => const FeedPage();
                break;
              case '/search':
                builder = (context) => const SearchPage();
                break;
              case '/post':
                builder = (context) => const PostPage();
                break;
              case '/profile':
                builder = (context) => const ProfilePage();
                break;
              case '/map':
                builder = (context) => const MapViewPage();
                break;
              case '/login':
                builder = (context) => const LoginPage();
                break;
              case '/settings':
                builder = (context) => const SettingsPage();
                break;
              default:
                builder = (context) => const FeedPage();
            }
            // Alternate between slide and fade transitions
            if (settings.name == '/search' || settings.name == '/settings') {
              // Fade transition
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => builder(context),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                settings: settings,
              );
            } else {
              // Slide transition
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => builder(context),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                  return SlideTransition(position: animation.drive(tween), child: child);
                },
                settings: settings,
              );
            }
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
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: isSelected
                      ? (theme.navigationBarTheme.labelTextStyle?.resolve({WidgetState.selected}) ??
                          theme.textTheme.labelMedium ??
                          const TextStyle())
                      : (theme.navigationBarTheme.labelTextStyle?.resolve({}) ??
                          theme.textTheme.labelMedium ??
                          const TextStyle()),
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