import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Follow a user
  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final targetUserRef = _db.collection('users').doc(targetUserId);

    await _db.runTransaction((transaction) async {
      transaction.set(
        currentUserRef.collection('following').doc(targetUserId),
        {'followedAt': FieldValue.serverTimestamp()},
      );

      transaction.set(
        targetUserRef.collection('followers').doc(currentUserId),
        {'followedAt': FieldValue.serverTimestamp()},
      );

      transaction.update(currentUserRef, {
        'followingCount': FieldValue.increment(1),
      });

      transaction.update(targetUserRef, {
        'followersCount': FieldValue.increment(1),
      });
    });
  }

  /// Unfollow a user
  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final currentUserRef = _db.collection('users').doc(currentUserId);
    final targetUserRef = _db.collection('users').doc(targetUserId);

    await _db.runTransaction((transaction) async {
      transaction.delete(
        currentUserRef.collection('following').doc(targetUserId),
      );

      transaction.delete(
        targetUserRef.collection('followers').doc(currentUserId),
      );

      transaction.update(currentUserRef, {
        'followingCount': FieldValue.increment(-1),
      });

      transaction.update(targetUserRef, {
        'followersCount': FieldValue.increment(-1),
      });
    });
  }

  /// Check if current user follows target user
  Stream<bool> isFollowing({
    required String currentUserId,
    required String targetUserId,
  }) {
    return _db
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((doc) => doc.exists);
  }
}
