import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'app_notification_service.dart';
import 'mention_service.dart';

class UserCollaboratorInput {
  const UserCollaboratorInput({
    required this.userId,
    required this.name,
  });

  final String userId;
  final String name;
}

class ClubCollaboratorInput {
  const ClubCollaboratorInput({
    required this.clubId,
    required this.clubName,
    required this.creatorId,
  });

  final String clubId;
  final String clubName;
  final String creatorId;
}

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference _postsRef =
      FirebaseFirestore.instance.collection('posts');
  final MentionService _mentionService = MentionService();
  final AppNotificationService _notificationService =
      AppNotificationService();

  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String authorRole,
    required String caption,
    required String imageUrl,
    List<UserCollaboratorInput> userCollaborators = const [],
    List<ClubCollaboratorInput> clubCollaborators = const [],
    String? taggedAdminId,
    String? taggedAdminName,
    int? requestedHours,
    int? requestedMinutes,
    String? verificationDescription,
  }) async {
    final postRef = _postsRef.doc();
    final userRef = _db.collection('users').doc(authorId);
    final hasVerificationRequest = (taggedAdminId ?? '').trim().isNotEmpty;
    final mentionCandidates = await _mentionService.fetchAllUsers();
    final mentionedUsers = _mentionService.extractMentions(
      text: caption,
      candidates: mentionCandidates,
      excludeUserId: authorId,
    );
    final mentionedUserIds = mentionedUsers.map((user) => user.userId).toList();
    final pendingUserCollaborators = userCollaborators
        .where((collaborator) => collaborator.userId != authorId)
        .toList();
    final approvedClubCollaborators = clubCollaborators
        .where((club) => club.creatorId == authorId)
        .toList();
    final pendingClubCollaborators = clubCollaborators
        .where((club) => club.creatorId != authorId)
        .toList();
    final collaboratorNames = [
      ...approvedClubCollaborators.map((club) => club.clubName),
    ];

    await _db.runTransaction((transaction) async {
      transaction.set(postRef, {
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'caption': caption,
        'imageUrl': imageUrl,
        'likesCount': 0,
        'likedBy': [],
        'commentsCount': 0,
        'viewCount': 0,
        'isClubPost': false,
        'clubName': '',
        'collaboratorNames': collaboratorNames,
        'userCollaboratorIds': <String>[],
        'userCollaboratorNames': <String>[],
        'pendingUserCollaboratorIds':
            pendingUserCollaborators.map((user) => user.userId).toList(),
        'pendingUserCollaboratorNames':
            pendingUserCollaborators.map((user) => user.name).toList(),
        'approvedClubCollaboratorIds':
            approvedClubCollaborators.map((club) => club.clubId).toList(),
        'approvedClubCollaboratorNames':
            approvedClubCollaborators.map((club) => club.clubName).toList(),
        'pendingClubCollaboratorIds':
            pendingClubCollaborators.map((club) => club.clubId).toList(),
        'pendingClubCollaboratorNames':
            pendingClubCollaborators.map((club) => club.clubName).toList(),
        'taggedAdminId': taggedAdminId ?? '',
        'taggedAdminName': taggedAdminName ?? '',
        'requestedHours': requestedHours ?? 0,
        'requestedMinutes': requestedMinutes ?? 0,
        'verificationDescription': verificationDescription ?? '',
        'verificationStatus': hasVerificationRequest ? 'pending' : '',
        'adminRemark': '',
        'taggedUsers': mentionedUserIds,
        'createdAt': Timestamp.now(),
      });

      transaction.update(userRef, {
        'NoOfPosts': FieldValue.increment(1),
      });
    });

    if (hasVerificationRequest) {
      await _sendPostVerificationNotification(
        adminId: taggedAdminId!,
        postId: postRef.id,
        studentId: authorId,
        studentName: authorName,
        requestedHours: requestedHours ?? 0,
        requestedMinutes: requestedMinutes ?? 0,
        verificationDescription: verificationDescription ?? '',
      );
    }

    await _notificationService.sendMentionNotifications(
      mentionedUsers: mentionedUsers,
      senderId: authorId,
      senderName: authorName,
      sourceType: 'post',
      sourceId: postRef.id,
      sourceText: caption,
      senderIsAdmin: authorRole == 'admin',
    );

    await _sendClubCollaborationRequests(
      postId: postRef.id,
      authorId: authorId,
      authorName: authorName,
      clubs: pendingClubCollaborators,
    );

    await _sendUserCollaborationRequests(
      postId: postRef.id,
      authorId: authorId,
      authorName: authorName,
      collaborators: pendingUserCollaborators,
    );
  }

  Future<void> _sendUserCollaborationRequests({
    required String postId,
    required String authorId,
    required String authorName,
    required List<UserCollaboratorInput> collaborators,
  }) async {
    for (final collaborator in collaborators) {
      await _notificationService.sendNotification(
        userId: collaborator.userId,
        type: 'user_collaboration_request',
        tab: NotificationTab.personal,
        title: '$authorName invited you to collaborate on a post',
        message: 'Approve to show this post on your profile too.',
        extraData: {
          'postId': postId,
          'requesterId': authorId,
          'requesterName': authorName,
          'collaboratorId': collaborator.userId,
          'collaboratorName': collaborator.name,
        },
      );
    }
  }

  Future<void> _sendClubCollaborationRequests({
    required String postId,
    required String authorId,
    required String authorName,
    required List<ClubCollaboratorInput> clubs,
  }) async {
    for (final club in clubs) {
      await _notificationService.sendNotification(
        userId: club.creatorId,
        type: 'club_collaboration_request',
        tab: NotificationTab.clubs,
        title: '$authorName requested collaboration with ${club.clubName}',
        message: 'Approve this request to show the post on the club profile.',
        extraData: {
          'postId': postId,
          'clubId': club.clubId,
          'clubName': club.clubName,
          'requesterId': authorId,
          'requesterName': authorName,
        },
      );
    }
  }

  Future<void> _sendPostVerificationNotification({
    required String adminId,
    required String postId,
    required String studentId,
    required String studentName,
    required int requestedHours,
    required int requestedMinutes,
    required String verificationDescription,
  }) async {
    await _db
        .collection('users')
        .doc(adminId)
        .collection('notifications')
        .add({
      'type': 'post_verification',
      'postId': postId,
      'studentId': studentId,
      'studentName': studentName,
      'requestedHours': requestedHours,
      'requestedMinutes': requestedMinutes,
      'verificationDescription': verificationDescription,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });
  }

  Future<void> approvePostVerification({
    required String postId,
    required String adminId,
    required String adminName,
    required String studentId,
    required String studentName,
    required int requestedHours,
    required int requestedMinutes,
    required String notificationId,
  }) async {
    final postRef = _postsRef.doc(postId);
    final adminNotificationRef = _db
        .collection('users')
        .doc(adminId)
        .collection('notifications')
        .doc(notificationId);
    final approvedHoursRef = _db
        .collection('users')
        .doc(studentId)
        .collection('approved_hours')
        .doc();
    final studentNotificationRef = _db
        .collection('users')
        .doc(studentId)
        .collection('notifications')
        .doc();

    await _db.runTransaction((transaction) async {
      transaction.update(postRef, {
        'verificationStatus': 'approved',
        'adminRemark': '',
      });
      transaction.set(approvedHoursRef, {
        'postId': postId,
        'studentId': studentId,
        'studentName': studentName,
        'approvedHours': requestedHours,
        'approvedMinutes': requestedMinutes,
        'approvedByAdminId': adminId,
        'approvedByAdminName': adminName,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(studentNotificationRef, {
        'type': 'post_approved',
        'postId': postId,
        'studentId': studentId,
        'studentName': studentName,
        'approvedHours': requestedHours,
        'approvedMinutes': requestedMinutes,
        'adminName': adminName,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });
      transaction.delete(adminNotificationRef);
    });
  }

  Future<void> sendPostRemark({
    required String postId,
    required String adminId,
    required String adminName,
    required String studentId,
    required String studentName,
    required String notificationId,
    required String remark,
  }) async {
    final postRef = _postsRef.doc(postId);
    final adminNotificationRef = _db
        .collection('users')
        .doc(adminId)
        .collection('notifications')
        .doc(notificationId);
    final studentNotificationRef = _db
        .collection('users')
        .doc(studentId)
        .collection('notifications')
        .doc();

    await _db.runTransaction((transaction) async {
      transaction.update(postRef, {
        'verificationStatus': 'pending',
        'adminRemark': remark,
      });
      transaction.set(studentNotificationRef, {
        'type': 'post_remark',
        'postId': postId,
        'studentId': studentId,
        'studentName': studentName,
        'remark': remark,
        'adminId': adminId,
        'adminName': adminName,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });
      transaction.delete(adminNotificationRef);
    });
  }

  Future<void> updatePostVerificationRequest({
    required String postId,
    required String studentId,
    required String taggedAdminId,
    required String taggedAdminName,
    required int requestedHours,
    required int requestedMinutes,
    required String verificationDescription,
    required String studentName,
    String? remarkNotificationId,
  }) async {
    final postRef = _postsRef.doc(postId);

    await postRef.update({
      'taggedAdminId': taggedAdminId,
      'taggedAdminName': taggedAdminName,
      'requestedHours': requestedHours,
      'requestedMinutes': requestedMinutes,
      'verificationDescription': verificationDescription,
      'verificationStatus': 'pending',
      'adminRemark': '',
    });

    if ((remarkNotificationId ?? '').isNotEmpty) {
      await _db
          .collection('users')
          .doc(studentId)
          .collection('notifications')
          .doc(remarkNotificationId)
          .delete();
    }

    await _sendPostVerificationNotification(
      adminId: taggedAdminId,
      postId: postId,
      studentId: studentId,
      studentName: studentName,
      requestedHours: requestedHours,
      requestedMinutes: requestedMinutes,
      verificationDescription: verificationDescription,
    );
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final postRef = _db.collection('posts').doc(postId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(postRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final List likedBy = List.from(data['likedBy'] ?? []);

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        likedBy.add(userId);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likesCount': FieldValue.increment(1),
        });
      }
    });
  }

  Future<void> incrementView(String postId) async {
    await _postsRef.doc(postId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  Future<void> deletePost(String postId) async {
    final postRef = _postsRef.doc(postId);

    await _db.runTransaction((transaction) async {
      final postSnap = await transaction.get(postRef);

      if (!postSnap.exists) return;

      final data = postSnap.data() as Map<String, dynamic>;
      final authorId = (data['authorId'] ?? '').toString();
      final userRef = _db.collection('users').doc(authorId);
      final approvedCollaborators =
          List<String>.from(data['userCollaboratorIds'] ?? []);

      transaction.delete(postRef);
      transaction.update(userRef, {
        'NoOfPosts': FieldValue.increment(-1),
      });
      for (final collaboratorId in approvedCollaborators) {
        transaction.update(_db.collection('users').doc(collaboratorId), {
          'NoOfPosts': FieldValue.increment(-1),
        });
      }
    });
  }

  Stream<List<PostModel>> streamPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  Stream<List<PostModel>> streamPostsForUser(String userId) {
    return streamPosts().map(
      (posts) => posts.where((post) {
        return post.authorId == userId ||
            post.userCollaboratorIds.contains(userId);
      }).toList(),
    );
  }

  Stream<List<PostModel>> streamPostsForClub(String clubId) {
    return streamPosts().map(
      (posts) => posts
          .where((post) => post.approvedClubCollaboratorIds.contains(clubId))
          .toList(),
    );
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String username,
    required String avatar,
    required String text,
  }) async {
    final postRef = _postsRef.doc(postId);
    final commentRef = postRef.collection('comments').doc();
    final userDoc = await _db.collection('users').doc(userId).get();
    final senderRole = (userDoc.data()?['role'] ?? '').toString();
    final mentionCandidates = await _mentionService.fetchAllUsers();
    final mentionedUsers = _mentionService.extractMentions(
      text: text,
      candidates: mentionCandidates,
      excludeUserId: userId,
    );

    await _db.runTransaction((tx) async {
      tx.set(commentRef, {
        'userId': userId,
        'username': username,
        'avatar': avatar,
        'text': text,
        'mentionedUserIds':
            mentionedUsers.map((user) => user.userId).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });
    });

    await _notificationService.sendMentionNotifications(
      mentionedUsers: mentionedUsers,
      senderId: userId,
      senderName: username,
      sourceType: 'comment',
      sourceId: commentRef.id,
      sourceText: text,
      senderIsAdmin: senderRole == 'admin',
    );
  }

  Stream<QuerySnapshot> streamComments(String postId) {
    return _postsRef
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();

    await _postsRef.doc(postId).update({
      'commentsCount': FieldValue.increment(-1),
    });
  }

  Future<void> approveClubCollaboration({
    required String postId,
    required String clubId,
    required String clubName,
    required String requesterId,
    required String requesterName,
    required String notificationId,
    required String approverId,
  }) async {
    final postRef = _postsRef.doc(postId);
    final notificationRef = _db
        .collection('users')
        .doc(approverId)
        .collection('notifications')
        .doc(notificationId);

    await _db.runTransaction((transaction) async {
      final postSnap = await transaction.get(postRef);
      if (!postSnap.exists) {
        return;
      }

      final data = postSnap.data() as Map<String, dynamic>;
      final approvedIds =
          List<String>.from(data['approvedClubCollaboratorIds'] ?? []);
      final approvedNames =
          List<String>.from(data['approvedClubCollaboratorNames'] ?? []);
      final pendingIds =
          List<String>.from(data['pendingClubCollaboratorIds'] ?? []);
      final pendingNames =
          List<String>.from(data['pendingClubCollaboratorNames'] ?? []);
      final collaboratorNames =
          List<String>.from(data['collaboratorNames'] ?? []);

      if (!approvedIds.contains(clubId)) {
        approvedIds.add(clubId);
      }
      if (!approvedNames.contains(clubName)) {
        approvedNames.add(clubName);
      }
      pendingIds.remove(clubId);
      pendingNames.remove(clubName);
      if (!collaboratorNames.contains(clubName)) {
        collaboratorNames.add(clubName);
      }

      transaction.update(postRef, {
        'approvedClubCollaboratorIds': approvedIds,
        'approvedClubCollaboratorNames': approvedNames,
        'pendingClubCollaboratorIds': pendingIds,
        'pendingClubCollaboratorNames': pendingNames,
        'collaboratorNames': collaboratorNames,
      });
      transaction.delete(notificationRef);
    });

    await _notificationService.sendNotification(
      userId: requesterId,
      type: 'club_collaboration_approved',
      tab: NotificationTab.personal,
      title: '$clubName approved your collaboration request',
      message: 'Your post is now visible on the club profile.',
      extraData: {
        'postId': postId,
        'clubId': clubId,
        'clubName': clubName,
        'requesterName': requesterName,
      },
    );
  }

  Future<void> rejectClubCollaboration({
    required String postId,
    required String clubId,
    required String clubName,
    required String requesterId,
    required String notificationId,
    required String approverId,
  }) async {
    final postRef = _postsRef.doc(postId);
    final notificationRef = _db
        .collection('users')
        .doc(approverId)
        .collection('notifications')
        .doc(notificationId);

    await _db.runTransaction((transaction) async {
      final postSnap = await transaction.get(postRef);
      if (postSnap.exists) {
        final data = postSnap.data() as Map<String, dynamic>;
        final pendingIds =
            List<String>.from(data['pendingClubCollaboratorIds'] ?? []);
        final pendingNames =
            List<String>.from(data['pendingClubCollaboratorNames'] ?? []);
        pendingIds.remove(clubId);
        pendingNames.remove(clubName);

        transaction.update(postRef, {
          'pendingClubCollaboratorIds': pendingIds,
          'pendingClubCollaboratorNames': pendingNames,
        });
      }

      transaction.delete(notificationRef);
    });

    await _notificationService.sendNotification(
      userId: requesterId,
      type: 'club_collaboration_rejected',
      tab: NotificationTab.personal,
      title: '$clubName declined your collaboration request',
      message: 'The post will stay on your profile only.',
      extraData: {
        'postId': postId,
        'clubId': clubId,
        'clubName': clubName,
      },
    );
  }

  Future<void> approveUserCollaboration({
    required String postId,
    required String collaboratorId,
    required String collaboratorName,
    required String requesterId,
    required String requesterName,
    required String notificationId,
  }) async {
    final postRef = _postsRef.doc(postId);
    final notificationRef = _db
        .collection('users')
        .doc(collaboratorId)
        .collection('notifications')
        .doc(notificationId);
    final collaboratorUserRef = _db.collection('users').doc(collaboratorId);

    await _db.runTransaction((transaction) async {
      final postSnap = await transaction.get(postRef);
      if (!postSnap.exists) {
        return;
      }

      final data = postSnap.data() as Map<String, dynamic>;
      final approvedIds = List<String>.from(data['userCollaboratorIds'] ?? []);
      final approvedNames =
          List<String>.from(data['userCollaboratorNames'] ?? []);
      final pendingIds =
          List<String>.from(data['pendingUserCollaboratorIds'] ?? []);
      final pendingNames =
          List<String>.from(data['pendingUserCollaboratorNames'] ?? []);
      final collaboratorNames =
          List<String>.from(data['collaboratorNames'] ?? []);

      if (!approvedIds.contains(collaboratorId)) {
        approvedIds.add(collaboratorId);
        transaction.update(collaboratorUserRef, {
          'NoOfPosts': FieldValue.increment(1),
        });
      }
      if (!approvedNames.contains(collaboratorName)) {
        approvedNames.add(collaboratorName);
      }
      pendingIds.remove(collaboratorId);
      pendingNames.remove(collaboratorName);
      if (!collaboratorNames.contains(collaboratorName)) {
        collaboratorNames.add(collaboratorName);
      }

      transaction.update(postRef, {
        'userCollaboratorIds': approvedIds,
        'userCollaboratorNames': approvedNames,
        'pendingUserCollaboratorIds': pendingIds,
        'pendingUserCollaboratorNames': pendingNames,
        'collaboratorNames': collaboratorNames,
      });
      transaction.delete(notificationRef);
    });

    await _notificationService.sendNotification(
      userId: requesterId,
      type: 'user_collaboration_approved',
      tab: NotificationTab.personal,
      title: '$collaboratorName accepted your collaboration request',
      message: 'The post now appears on both profiles.',
      extraData: {
        'postId': postId,
        'collaboratorId': collaboratorId,
        'collaboratorName': collaboratorName,
        'requesterName': requesterName,
      },
    );
  }

  Future<void> rejectUserCollaboration({
    required String postId,
    required String collaboratorId,
    required String collaboratorName,
    required String requesterId,
    required String notificationId,
  }) async {
    final postRef = _postsRef.doc(postId);
    final notificationRef = _db
        .collection('users')
        .doc(collaboratorId)
        .collection('notifications')
        .doc(notificationId);

    await _db.runTransaction((transaction) async {
      final postSnap = await transaction.get(postRef);
      if (postSnap.exists) {
        final data = postSnap.data() as Map<String, dynamic>;
        final pendingIds =
            List<String>.from(data['pendingUserCollaboratorIds'] ?? []);
        final pendingNames =
            List<String>.from(data['pendingUserCollaboratorNames'] ?? []);
        pendingIds.remove(collaboratorId);
        pendingNames.remove(collaboratorName);

        transaction.update(postRef, {
          'pendingUserCollaboratorIds': pendingIds,
          'pendingUserCollaboratorNames': pendingNames,
        });
      }

      transaction.delete(notificationRef);
    });

    await _notificationService.sendNotification(
      userId: requesterId,
      type: 'user_collaboration_rejected',
      tab: NotificationTab.personal,
      title: '$collaboratorName declined your collaboration request',
      message: 'The post will stay on your profile only.',
      extraData: {
        'postId': postId,
        'collaboratorId': collaboratorId,
        'collaboratorName': collaboratorName,
      },
    );
  }
}
