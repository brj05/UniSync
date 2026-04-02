import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';
import '../services/session_service.dart';
import '../services/content_moderation_service.dart';

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
  final ContentModerationService _moderationService =
      ContentModerationService();

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

    setState(() => _loading = true);

    try {
      // CONTENT MODERATION FOR POST CAPTION
      final moderation = await _moderationService.moderate(
        _captionController.text.trim(),
        type: 'post',
      );

      if (!mounted) return;

      if (moderation.status == ModerationStatus.blocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              moderation.message.isNotEmpty
                  ? moderation.message
                  : 'This post contains offensive or abusive language and cannot be posted.',
            ),
          ),
        );

        setState(() => _loading = false);
        return;
      }

      if (moderation.status == ModerationStatus.warning) {
        final proceed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Warning'),
                content: Text(
                  moderation.message.isNotEmpty
                      ? moderation.message
                      : 'This post may contain harsh or inappropriate language. Do you still want to post it?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Post Anyway'),
                  ),
                ],
              ),
            ) ??
            false;

        if (!proceed) {
          setState(() => _loading = false);
          return;
        }
      }

      final requestedHours = int.tryParse(_hoursController.text.trim()) ?? 0;
      final requestedMinutes =
          int.tryParse(_minutesController.text.trim()) ?? 0;
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
          setState(() => _loading = false);
          return;
        }
      }

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
          ],
        ),
      ),
    );
  }
}
