import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String caption;
  final String imageUrl;
  final int likesCount;
  final int commentsCount;
  final int viewCount;
  final bool isClubPost;
  final String clubName;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.caption,
    required this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.viewCount,
    required this.isClubPost,
    required this.clubName,
  });

  factory PostModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorAvatar: data['authorAvatar'] ??
          'https://i.pravatar.cc/150?img=3', // ✅ fallback
      caption: data['caption'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      isClubPost: data['isClubPost'] ?? false,
      clubName: data['clubName'] ?? '',
    );
  }
}
