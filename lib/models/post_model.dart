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
  final List<String> likedBy;
  final String taggedAdminId;
  final String taggedAdminName;
  final int requestedHours;
  final int requestedMinutes;
  final String verificationDescription;
  final String verificationStatus;
  final String adminRemark;

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
    required this.likedBy,
    required this.taggedAdminId,
    required this.taggedAdminName,
    required this.requestedHours,
    required this.requestedMinutes,
    required this.verificationDescription,
    required this.verificationStatus,
    required this.adminRemark,
  });

  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  factory PostModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return PostModel(
      id: id,
      authorId: data['authorId']?.toString() ?? '',
      authorName: data['authorName']?.toString() ?? 'Unknown',
      authorAvatar: data['authorAvatar']?.toString() ??
          'https://ui-avatars.com/api/?name=User&background=0D8ABC&color=fff',
      caption: data['caption']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      likesCount: (data['likesCount'] ?? 0) as int,
      commentsCount: (data['commentsCount'] ?? 0) as int,
      viewCount: (data['viewCount'] ?? 0) as int,
      isClubPost: data['isClubPost'] == true,
      clubName: data['clubName']?.toString() ?? '',
      likedBy: List<String>.from(data['likedBy'] ?? []),
      taggedAdminId: data['taggedAdminId']?.toString() ?? '',
      taggedAdminName: data['taggedAdminName']?.toString() ?? '',
      requestedHours: (data['requestedHours'] ?? 0) as int,
      requestedMinutes: (data['requestedMinutes'] ?? 0) as int,
      verificationDescription:
          data['verificationDescription']?.toString() ?? '',
      verificationStatus: data['verificationStatus']?.toString() ?? '',
      adminRemark: data['adminRemark']?.toString() ?? '',
    );
  }

  factory PostModel.fromFirestore(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
<<<<<<< HEAD
    return PostModel.fromMap(data, id: doc.id);
=======

    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorAvatar: data['authorAvatar'] ??
          'https://ui-avatars.com/api/?name=User&background=0D8ABC&color=fff',
      caption: data['caption'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      isClubPost: data['isClubPost'] ?? false,
      clubName: data['clubName'] ?? '',
      likedBy: List<String>.from(data['likedBy'] ?? []),
      taggedAdminId: data['taggedAdminId'] ?? '',
      taggedAdminName: data['taggedAdminName'] ?? '',
      requestedHours: data['requestedHours'] ?? 0,
      requestedMinutes: data['requestedMinutes'] ?? 0,
      verificationDescription: data['verificationDescription'] ?? '',
      verificationStatus: data['verificationStatus'] ?? '',
      adminRemark: data['adminRemark'] ?? '',
    );
>>>>>>> b6afb048734d7750405735341072352abf5adc9f
  }
}
