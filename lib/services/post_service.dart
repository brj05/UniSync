import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference _postsRef =
      FirebaseFirestore.instance.collection('posts');

  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String caption,
    required String imageUrl,
    String? taggedAdminId,
    String? taggedAdminName,
    int? requestedHours,
    int? requestedMinutes,
    String? verificationDescription,
  }) async {
    final postRef = _postsRef.doc();
    final userRef = _db.collection('users').doc(authorId);
    final hasVerificationRequest = (taggedAdminId ?? '').trim().isNotEmpty;

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
        'taggedAdminId': taggedAdminId ?? '',
        'taggedAdminName': taggedAdminName ?? '',
        'requestedHours': requestedHours ?? 0,
        'requestedMinutes': requestedMinutes ?? 0,
        'verificationDescription': verificationDescription ?? '',
        'verificationStatus': hasVerificationRequest ? 'pending' : '',
        'adminRemark': '',
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

      final authorId = postSnap['authorId'];
      final userRef = _db.collection('users').doc(authorId);

      transaction.delete(postRef);
      transaction.update(userRef, {
        'NoOfPosts': FieldValue.increment(-1),
      });
    });
  }

  Stream<List<PostModel>> streamPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  Future<void> addComment({
    required String postId,
    required String userId,
    required String username,
    required String avatar,
    required String text,
  }) async {
    final postRef = _postsRef.doc(postId);

    await _db.runTransaction((tx) async {
      tx.set(
        postRef.collection('comments').doc(),
        {
          'userId': userId,
          'username': username,
          'avatar': avatar,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      tx.update(postRef, {
        'commentsCount': FieldValue.increment(1),
      });
    });
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
}
