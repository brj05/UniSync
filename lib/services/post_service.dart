import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference _postsRef =
      FirebaseFirestore.instance.collection('posts');

  /// CREATE POST + INCREMENT USER NoOfPosts
  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String caption,
    required String imageUrl,
  }) async {
    final userRef = _db.collection('users').doc(authorId);

    await _db.runTransaction((transaction) async {
      final postRef = _postsRef.doc();

      transaction.set(postRef, {
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'caption': caption,
        'imageUrl': imageUrl,
        'likesCount': 0,
        'likedBy': [], // 🔥 UNIQUE LIKE TRACKING
        'commentsCount': 0,
        'viewCount': 0,
        'isClubPost': false,
        'clubName': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(userRef, {
        'NoOfPosts': FieldValue.increment(1),
      });
    });
  }

  /// TOGGLE LIKE (UNIQUE PER USER)
  Future<void> toggleLike({
    required String postId,
    required String userId,
    required bool isLiked,
  }) async {
    final postRef = _postsRef.doc(postId);

    await _db.runTransaction((transaction) async {
      if (isLiked) {
        transaction.update(postRef, {
          'likedBy': FieldValue.arrayRemove([userId]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        transaction.update(postRef, {
          'likedBy': FieldValue.arrayUnion([userId]),
          'likesCount': FieldValue.increment(1),
        });
      }
    });
  }

  /// INCREMENT VIEW COUNT (safe, single call)
  Future<void> incrementView(String postId) async {
    await _postsRef.doc(postId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  /// STREAM POSTS
  Stream<List<PostModel>> streamPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }
}
