import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import '../widgets/home_app_bar.dart';
import '../models/post_model.dart';
import '../services/session_service.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final PostService postService = PostService();

  /// 🔹 Tracks posts already viewed in this session
  final Set<String> _viewedPostIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: buildHomeAppBar(context),
      body: FutureBuilder(
        future: SessionService.getSession(),
        builder: (context, sessionSnap) {
          if (!sessionSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUserId = sessionSnap.data!['phone']!;

          return StreamBuilder<List<PostModel>>(
            stream: postService.streamPosts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = snapshot.data!;

              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];

                  /// ✅ VIEW COUNT FIX (Instagram-style)
                  if (!_viewedPostIds.contains(post.id)) {
                    _viewedPostIds.add(post.id);
                    postService.incrementView(post.id);
                  }

                  return PostCard(
                    postId: post.id,
                    currentUserId: currentUserId,
                    authorName: post.authorName,
                    authorAvatar: post.authorAvatar,
                    caption: post.caption,
                    imageUrl:
                        post.imageUrl.isEmpty ? null : post.imageUrl,
                    likes: post.likesCount,
                    comments: post.commentsCount,
                    views: post.viewCount,
                    clubName:
                        post.isClubPost ? post.clubName : null,
                    isLiked: post.isLikedBy(currentUserId),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
