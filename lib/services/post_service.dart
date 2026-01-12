import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class PostService {
  final _postsRef = FirebaseFirestore.instance.collection('posts');

  /// CREATE POST
  Future<void> createPost({
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String caption,
    required String imageUrl,
  }) async {
    await _postsRef.add({
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'caption': caption,
      'imageUrl': imageUrl,
      'likes': 0,
      'comments': 0,
      'views': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// STREAM POSTS (🔥 THIS FIXES "NO POSTS YET")
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
