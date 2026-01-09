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
  final TextEditingController _textController = TextEditingController();
  final PostService _postService = PostService();

  File? _selectedImage;
  bool _posting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _submitPost() async {
    if (_textController.text.trim().isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something or add an image')),
      );
      return;
    }

    setState(() => _posting = true);

    try {
      await _postService.createPost(
        authorId: widget.authorId,
        authorName: widget.authorName,
        authorAvatar: widget.authorAvatar,
        text: _textController.text.trim(),
        mediaFile: _selectedImage,
        mediaType: _selectedImage != null ? 'image' : null,
      );

      Navigator.pop(context); // back to feed
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post')),
      );
    }

    setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _posting ? null : _submitPost,
            child: _posting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Post',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // USER ROW
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.authorAvatar),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.authorName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // TEXT INPUT
            TextField(
              controller: _textController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'What’s on your mind?',
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 12),

            // IMAGE PREVIEW
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

            const Spacer(),

            // ACTION ROW
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: _pickImage,
                ),
                const SizedBox(width: 6),
                const Text('Add Image'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
