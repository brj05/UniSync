import 'package:flutter/material.dart';
import 'home_feed.dart';
import 'create_post.dart';
import 'talk_zone.dart';
import 'profile.dart';
import '../widgets/home_bottom_nav.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeFeedScreen(),
    SizedBox(), // Explore (later)
    SizedBox(), // + handled via Navigator
    TalkZoneScreen(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    if (index == 2) {
      // 🔥 OPEN CREATE POST SCREEN
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CreatePostScreen(),
        ),
      );
      return;
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
