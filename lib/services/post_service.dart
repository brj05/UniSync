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
    }) async {
      final postRef = _postsRef.doc();
      final userRef = _db.collection('users').doc(authorId);

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
          'createdAt': Timestamp.now(), // ✅ FIXED
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
  }) async {
    final postRef = _db.collection('posts').doc(postId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(postRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final List likedBy =
          List.from(data['likedBy'] ?? []);

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
  /// INCREMENT VIEW COUNT (safe, single call)
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

      /// 🔹 Delete post
      transaction.delete(postRef);

      /// 🔹 Decrement NoOfPosts
      transaction.update(userRef, {
        'NoOfPosts': FieldValue.increment(-1),
      });
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
  /// DELETE COMMENT
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

    // 🔹 decrement comment count
    await _postsRef.doc(postId).update({
      'commentsCount': FieldValue.increment(-1),
    });
  }
}
