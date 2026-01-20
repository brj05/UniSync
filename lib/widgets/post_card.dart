import '../screens/profile.dart';
import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../screens/comment_screen.dart';

class PostCard extends StatelessWidget {
  final String postId;
  final String authorId;
  final String currentUserId;

  final String currentUserName;
  final String currentUserAvatar;

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
    required this.authorId,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserAvatar,
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

  void _openOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// SHARE (everyone)
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Share logic later
                },
              ),

              /// DELETE (owner only)
              if (currentUserId == authorId)
                ListTile(
                  leading:
                      const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm =
                        await _confirmDelete(context);
                    if (confirm) {
                      await PostService().deletePost(postId);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete post?'),
            content:
                const Text('Do you really want to delete this post?'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, true),
                child: const Text(
                  'Yes',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(userId: authorId),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage:
                  NetworkImage(authorAvatar),
                ),
              ),
             const SizedBox(width: 10),

             Expanded(
               child: GestureDetector(
                 onTap: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (_) => ProfileScreen(userId: authorId),
                     ),
                   );
                 },
                 child: Text(
                   authorName,
                   style: const TextStyle(
                     fontWeight: FontWeight.w600,
                   ),
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
             ),
             IconButton(
               icon: const Icon(Icons.more_vert),
               onPressed: () => _openOptions(context),
             ),
            ],
          ),

          if (caption.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(caption),
          ],

          if (imageUrl != null && imageUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(); // silently ignore broken images
                },
              ),
            ),
          ],
          const SizedBox(height: 10),

          /// ACTION ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  PostService().toggleLike(
                    postId: postId,
                    userId: currentUserId,
                  );
                },
                child: _action(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  likes,
                  color: isLiked ? Colors.red : Colors.black,
                ),
              ),

              /// COMMENTS
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentScreen(
                        postId: postId,
                        userId: currentUserId,
                        username: currentUserName,
                        avatar: currentUserAvatar,
                        postAuthorId: authorId,
                      ),
                    ),
                  );
                },
                child: _action(
                    Icons.chat_bubble_outline, comments),
              ),

              _action(Icons.remove_red_eye_outlined, views),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, int count, {Color color = Colors.black }) {
    return Row(
      children: [
        Icon(icon, size: 20, color:color),
        const SizedBox(width: 4),
        Text(count.toString()),
      ],
    );
  }
}
