import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';
import '../services/session_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _verificationDescriptionController = TextEditingController();
  final PostService _postService = PostService();

  File? _image;
  bool _loading = false;

  String? _authorId;
  String? _authorName;
  String? _authorAvatar;
  String _authorRole = '';
  List<Map<String, String>> _admins = [];
  String? _selectedAdminId;
  String? _selectedAdminName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAdmins();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _verificationDescriptionController.dispose();
    super.dispose();
  }

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
      _authorId = phone;
      _authorName = data['name'] ?? 'User';
      _authorAvatar = data['avatar'] ?? '';
      _authorRole = data['role']?.toString() ?? '';
    });

    if (_authorRole == 'student') {
      await _loadAdmins();
    }
  }

  Future<void> _loadAdmins() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();

    setState(() {
      _admins = snap.docs
          .map(
            (doc) => {
              'id': doc.id,
              'name': (doc.data()['name'] ?? 'Admin').toString(),
            },
          )
          .toList();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  bool get _hasVerificationInput {
    return (_selectedAdminId ?? '').isNotEmpty ||
        _hoursController.text.trim().isNotEmpty ||
        _minutesController.text.trim().isNotEmpty ||
        _verificationDescriptionController.text.trim().isNotEmpty;
  }

  Future<void> _submitPost() async {
    if (_authorId == null || _authorName == null || _authorAvatar == null) {
      return;
    }

    if (_captionController.text.trim().isEmpty && _image == null) {
      return;
    }

    final requestedHours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final requestedMinutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final verificationDescription =
        _verificationDescriptionController.text.trim();

    if (_hasVerificationInput) {
      final hasAdmin = (_selectedAdminId ?? '').isNotEmpty;
      final hasDuration = requestedHours > 0 || requestedMinutes > 0;
      final hasDescription = verificationDescription.isNotEmpty;

      if (!hasAdmin || !hasDuration || !hasDescription) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'To request verification, select an admin, enter hours or minutes, and add a description.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      await _postService.createPost(
        authorId: _authorId!,
        authorName: _authorName!,
        authorAvatar: _authorAvatar!,
        caption: _captionController.text.trim(),
        imageUrl: '',
        taggedAdminId: _hasVerificationInput ? _selectedAdminId : null,
        taggedAdminName: _hasVerificationInput ? _selectedAdminName : null,
        requestedHours: _hasVerificationInput ? requestedHours : null,
        requestedMinutes: _hasVerificationInput ? requestedMinutes : null,
        verificationDescription:
            _hasVerificationInput ? verificationDescription : null,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submitPost,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            if (_image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 220, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image_outlined),
                  onPressed: _pickImage,
                ),
                const Text('Add Image'),
              ],
            ),
            if (_authorRole == 'student') ...[
              const SizedBox(height: 20),
              const Text(
                'Verification Request (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedAdminId,
                decoration: _fieldDecoration('Tagged Admin'),
                items: _admins
                    .map(
                      (admin) => DropdownMenuItem<String>(
                        value: admin['id'],
                        child: Text(admin['name'] ?? 'Admin'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  final selectedAdmin = _admins.firstWhere(
                    (admin) => admin['id'] == value,
                    orElse: () => {},
                  );
                  setState(() {
                    _selectedAdminId = value;
                    _selectedAdminName = selectedAdmin['name'];
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration('Requested Hours'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _minutesController,
                      keyboardType: TextInputType.number,
                      decoration: _fieldDecoration('Requested Minutes'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _verificationDescriptionController,
                maxLines: 4,
                decoration: _fieldDecoration(
                  'Verification Description',
                  hintText: 'Why should this post be verified?',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
