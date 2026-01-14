import 'package:flutter/material.dart';
import '../services/post_service.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final String currentUserId;
  final String authorName;
  final String authorAvatar;
  final String caption;
  final String? imageUrl;
  final int likes;
  final int comments;
  final int views;
  final String? clubName;
  final bool isLiked;

  const PostCard({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.authorName,
    required this.authorAvatar,
    required this.caption,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.views,
    this.clubName,
    required this.isLiked,
  });

  @override
  Widget build(BuildContext context) {
    final postService = PostService();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(authorAvatar),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  authorName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          if (caption.isNotEmpty) Text(caption),

          if (imageUrl != null) ...[
            const SizedBox(height: 10),
            Image.network(imageUrl!, height: 220, fit: BoxFit.cover),
          ],

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  postService.toggleLike(
                    postId: postId,
                    userId: currentUserId,
                    isLiked: isLiked,
                  );
                },
                child: _action(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  likes,
                  color: isLiked ? Colors.red : Colors.grey.shade700,
                ),
              ),
              _action(Icons.chat_bubble_outline, comments),
              _action(Icons.remove_red_eye_outlined, views),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, int count, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(count.toString()),
      ],
    );
  }
}
