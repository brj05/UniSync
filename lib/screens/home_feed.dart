import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import '../widgets/home_app_bar.dart';
import '../models/post_model.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final postService = PostService();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: buildHomeAppBar(context),
      body: StreamBuilder<List<PostModel>>(
        stream: postService.streamPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts yet'));
          }

          final posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              return PostCard(
                authorName: post.authorName,
                authorAvatar: post.authorAvatar,
                caption: post.caption,
                imageUrl: post.imageUrl.isEmpty ? null : post.imageUrl,
                likes: post.likesCount,
                comments: post.commentsCount,
                views: post.viewCount,
                clubName: post.isClubPost ? post.clubName : null,
              );
            },
          );
        },
      ),
    );
  }
}
