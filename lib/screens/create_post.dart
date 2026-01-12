import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  final String authorId;
  final String authorName;
  final String authorAvatar;

  const CreatePostScreen({
    super.key,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final PostService _postService = PostService();

  File? _image;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submitPost() async {
    if (_captionController.text.trim().isEmpty && _image == null) return;

    setState(() => _loading = true);

    await _postService.createPost(
      authorId: widget.authorId,
      authorName: widget.authorName,
      authorAvatar: widget.authorAvatar,
      caption: _captionController.text.trim(),
      imageUrl: '', // Firebase Storage upload later
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
