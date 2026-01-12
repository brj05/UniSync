import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String authorName;
  final String authorAvatar;
  final String caption;
  final String? imageUrl;
  final int likes;
  final int comments;
  final int views;
  final String? clubName;

  const PostCard({
    super.key,
    required this.authorName,
    required this.authorAvatar,
    required this.caption,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.views,
    this.clubName,
  });

  @override
  Widget build(BuildContext context) {
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

          /// 🔹 HEADER ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(authorAvatar),
                backgroundColor: Colors.grey.shade300,
              ),
              const SizedBox(width: 10),

              /// NAME + CLUB
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (clubName != null)
                      Text(
                        'in collaboration with $clubName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),

              /// 3 DOT MENU
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // TODO: Post options (delete/report/etc)
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// 🔹 CAPTION
          if (caption.isNotEmpty)
            Text(
              caption,
              style: const TextStyle(fontSize: 14),
            ),

          /// 🔹 IMAGE
          if (imageUrl != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          /// 🔹 ACTION ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _action(Icons.favorite_border, likes),
              _action(Icons.chat_bubble_outline, comments),
              _action(Icons.remove_red_eye_outlined, views),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}
