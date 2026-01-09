import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String username;
  final String caption;
  final String? imageUrl;
  final int likes;
  final int comments;
  final int views;

  const PostCard({
    super.key,
    required this.username,
    required this.caption,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.views,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF8B5CF6),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.more_vert),
              ],
            ),
          ),

          /// IMAGE
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          /// CAPTION
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              caption,
              style: const TextStyle(fontSize: 15),
            ),
          ),

          /// ACTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _iconText(Icons.favorite_border, likes.toString()),
                const SizedBox(width: 16),
                _iconText(Icons.comment_outlined, comments.toString()),
                const SizedBox(width: 16),
                _iconText(Icons.share_outlined, ''),
                const Spacer(),
                _iconText(Icons.remove_red_eye_outlined, views.toString()),
              ],
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
