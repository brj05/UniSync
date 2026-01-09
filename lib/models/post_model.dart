import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final String? clubId;
  final String? clubName;
  final bool isClubPost;
  final bool aiApproved;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final Timestamp createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    this.clubId,
    this.clubName,
    required this.isClubPost,
    required this.aiApproved,
    required this.likesCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.createdAt,
  });

  factory PostModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'],
      authorName: data['authorName'],
      authorAvatar: data['authorAvatar'],
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      clubId: data['clubId'],
      clubName: data['clubName'],
      isClubPost: data['isClubPost'],
      aiApproved: data['aiApproved'],
      likesCount: data['likesCount'],
      commentsCount: data['commentsCount'],
      viewsCount: data['viewsCount'],
      createdAt: data['createdAt'],
    );
  }
}
