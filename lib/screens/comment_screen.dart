import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../services/content_moderation_service.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String userId;
  final String username;
  final String avatar;
  final String postAuthorId;

  const CommentScreen({
    super.key,
    required this.postId,
    required this.userId,
    required this.username,
    required this.avatar,
    required this.postAuthorId,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final controller = TextEditingController();
  final service = PostService();
  final moderationService = ContentModerationService();

  void _confirmDelete(String commentId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('Do you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              await service.deleteComment(
                postId: widget.postId,
                commentId: commentId,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text(
              'Yes',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final result = await moderationService.moderate(
      text,
      type: 'comment',
    );

    if (!mounted) return;

    if (result.status == ModerationStatus.blocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            result.message.isNotEmpty
                ? result.message
                : 'This comment contains abusive or offensive language.',
          ),
        ),
      );
      return;
    }

    if (result.status == ModerationStatus.warning) {
      final proceed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Warning'),
              content: Text(
                result.message.isNotEmpty
                    ? result.message
                    : 'This comment may be inappropriate. Post anyway?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Post Anyway'),
                ),
              ],
            ),
          ) ??
          false;

      if (!proceed) return;
    }

    await service.addComment(
      postId: widget.postId,
      userId: widget.userId,
      username: widget.username,
      avatar: widget.avatar,
      text: text,
    );

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: service.streamComments(widget.postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final commentUserId = d['userId'];

                    final canDelete =
                        commentUserId == widget.userId ||
                        widget.userId == widget.postAuthorId;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(d['avatar']),
                      ),
                      title: Text(d['username']),
                      subtitle: Text(d['text']),
                      trailing: canDelete
                          ? IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _confirmDelete(d.id),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
