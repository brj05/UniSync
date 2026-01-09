import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../widgets/home_app_bar.dart';
class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: buildHomeAppBar(context),
      body: ListView(
        children: const [
          PostCard(
            username: 'Aarav Sharma',
            caption:
                'Just performed at the open mic 🎤🔥 What an amazing crowd!',
            imageUrl:
                'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4',
            likes: 120,
            comments: 18,
            views: 890,
          ),

          PostCard(
            username: 'Priya Verma',
            caption:
                'Trying food photography 📸 Let me know how it looks!',
            imageUrl:
                'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
            likes: 98,
            comments: 12,
            views: 640,
          ),

          PostCard(
            username: 'Rohit Mehta',
            caption:
                'Learning Flutter 🚀 Slowly falling in love with app dev.',
            likes: 76,
            comments: 9,
            views: 430,
          ),
        ],
      ),
    );
  }
}
