import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/post_service.dart';
import '../services/session_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final PostService _postService = PostService();

  File? _image;
  bool _loading = false;

  String? _authorId;
  String? _authorName;
  String? _authorAvatar;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 🔹 Fetch logged-in user from users collection
  Future<void> _loadUserData() async {
    final session = await SessionService.getSession();
    if (session == null) return;

    final phone = session['phone']!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(phone)
        .get();

    if (!userDoc.exists) return;

    final data = userDoc.data()!;

    setState(() {
      _authorId = phone; // ✅ users document ID
      _authorName = data['name'];
      _authorAvatar = data['avatar'] ?? '';
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submitPost() async {
    if (_authorId == null) return;
    if (_captionController.text.trim().isEmpty && _image == null) return;

    setState(() => _loading = true);

    await _postService.createPost(
      authorId: _authorId!,          // ✅ from users
      authorName: _authorName!,      // ✅ from users
      authorAvatar: _authorAvatar!,  // ✅ from users
      caption: _captionController.text.trim(),
      imageUrl: '', // Firebase Storage later
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submitPost,
            child: const Text('Post'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _captionController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 12),

            if (_image != null)
              Image.file(_image!, height: 220, fit: BoxFit.cover),

            const Spacer(),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: _pickImage,
                ),
                const Text('Add Image'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
