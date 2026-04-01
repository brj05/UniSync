import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/chat_service.dart';
import '../services/session_service.dart';

class PersonalChatScreen extends StatefulWidget {
  const PersonalChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
  });

  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;

  @override
  State<PersonalChatScreen> createState() => _PersonalChatScreenState();
}

class _PersonalChatScreenState extends State<PersonalChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _currentUserId;
  String? _chatId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    final currentUserId = await SessionService.getPhone();
    if (currentUserId == null) {
      return;
    }

    final chatId = await _chatService.getOrCreateChat(
      currentUserId: currentUserId,
      otherUserId: widget.receiverId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUserId = currentUserId;
      _chatId = chatId;
    });
  }

  Future<void> _sendMessage() async {
    final currentUserId = _currentUserId;
    final text = _messageController.text.trim();

    if (currentUserId == null || text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendMessage(
        senderId: currentUserId,
        receiverId: widget.receiverId,
        text: text,
      );

      _messageController.clear();
      _scrollToBottom(animated: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollController.hasClients) {
      return;
    }

    final offset = _scrollController.position.maxScrollExtent;

    if (animated) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    _scrollController.jumpTo(offset);
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final dateTime = timestamp.toDate();
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.receiverPhotoUrl?.trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFEFE7DD),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F8C7B),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              backgroundImage:
                  photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      widget.receiverName.isNotEmpty
                          ? widget.receiverName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.receiverName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _currentUserId == null || _chatId == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _chatService.getMessages(_chatId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Unable to load messages'),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      if (docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'No messages yet. Start the conversation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final isMe = data['senderId'] == _currentUserId;
                          final messageText = data['text']?.toString() ?? '';
                          final timestamp = data['timestamp'] as Timestamp?;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFFDCF7C5)
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 18),
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x14000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      messageText,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(timestamp),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    color: const Color(0xFFF7F7F7),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Type a message',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF0F8C7B),
                          child: IconButton(
                            onPressed: _isSending ? null : _sendMessage,
                            icon: Icon(
                              _isSending ? Icons.hourglass_top : Icons.send,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
