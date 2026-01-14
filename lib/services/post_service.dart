import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference _postsRef =
      FirebaseFirestore.instance.collection('posts');

  /// CREATE POST + INCREMENT USER NoOfPosts
  Future<void> createPost({
    required String authorId,      // users doc id (phone)
    required String authorName,
    required String authorAvatar,
    required String caption,
    required String imageUrl,
  }) async {
    final userRef = _db.collection('users').doc(authorId);

    await _db.runTransaction((transaction) async {
      // 🔹 Create post
      final postRef = _postsRef.doc();

      transaction.set(postRef, {
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'caption': caption,
        'imageUrl': imageUrl,
        'likesCount': 0,
        'commentsCount': 0,
        'viewCount': 0,
        'isClubPost': false,
        'clubName': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔹 Increment user's NoOfPosts
      transaction.update(userRef, {
        'NoOfPosts': FieldValue.increment(1),
      });
    });
  }

  /// STREAM POSTS
  Stream<List<PostModel>> streamPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }
}
