import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createPost({
    required String authorId,
    required String authorName,
    String? authorAvatar,
    String? text,
    File? mediaFile,
    String? mediaType, // 'image' | 'video'
  }) async {
    await _db.collection('posts').add({
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'text': text,
      'mediaUrl': null, // upload later
      'mediaType': mediaType,
      'likes': 0,
      'comments': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
