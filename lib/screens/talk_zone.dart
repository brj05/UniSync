import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/anonymous_name.dart';
import '../services/session_service.dart';

class TalkItOutScreen extends StatefulWidget {
  final String? sessionIdFromNotification;

  const TalkItOutScreen({super.key, this.sessionIdFromNotification});

  @override
  State<TalkItOutScreen> createState() => _TalkItOutScreenState();
}

class _TalkItOutScreenState extends State<TalkItOutScreen> {
  String? sessionId;
  String? anonName;
  bool inChat = false;
  bool isCreator = false;

  String userId = "";

  final TextEditingController _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final session = await SessionService.getSession();
    userId = session?['phone'] ?? "";

    if (widget.sessionIdFromNotification != null) {
      await joinSession(widget.sessionIdFromNotification!);
    } else {
      await _restoreSession();
    }
  }

  // ================= RESTORE SESSION =================
  Future<void> _restoreSession() async {
    if (userId.isEmpty) return;

    final sessions = await FirebaseFirestore.instance
        .collection('talkitout_sessions')
        .where('active', isEqualTo: true)
        .get();

    for (var doc in sessions.docs) {
      final data = doc.data();

      if (data['creatorId'] == userId) {
        final participantDoc = await doc.reference
            .collection('participants')
            .doc(userId)
            .get();

        setState(() {
          sessionId = doc.id;
          anonName = participantDoc.data()?['anon'];
          inChat = true;
          isCreator = true;
        });
        return;
      }

      final participantDoc = await doc.reference
          .collection('participants')
          .doc(userId)
          .get();

      if (participantDoc.exists) {
        setState(() {
          sessionId = doc.id;
          anonName = participantDoc.data()?['anon'];
          inChat = true;
          isCreator = false;
        });
        return;
      }
    }
  }

  // ================= CREATE SESSION =================
  Future<void> _startSession() async {
    if (userId.isEmpty) return;

    anonName = AnonymousName.generate();

    final ref =
        FirebaseFirestore.instance.collection('talkitout_sessions').doc();

    setState(() {
      sessionId = ref.id;
      inChat = true;
      isCreator = true;
    });

    await ref.set({
      'creatorId': userId,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await ref.collection('participants').doc(userId).set({
      'anon': anonName,
    });

    final usersSnapshot =
        await FirebaseFirestore.instance.collection('users').get();

    for (var user in usersSnapshot.docs) {
      final targetUserId = user.id;

      if (targetUserId == userId) continue;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('notifications')
          .add({
        'type': 'talkitout_invite',
        'sessionId': sessionId,
        'creatorAnon': anonName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ================= JOIN (FIXED) =================
  Future<void> joinSession(String id) async {
    if (userId.isEmpty) return;

    final sessionRef = FirebaseFirestore.instance
        .collection('talkitout_sessions')
        .doc(id);

    final sessionDoc = await sessionRef.get();

    // 🔥 CHECK IF SESSION EXISTS
    if (!sessionDoc.exists || sessionDoc.data()?['active'] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This session no longer exists."),
          ),
        );
      }
      return;
    }

    final participantRef =
        sessionRef.collection('participants').doc(userId);

    final doc = await participantRef.get();

    if (doc.exists) {
      anonName = doc.data()?['anon'];
    } else {
      anonName = AnonymousName.generate();

      await participantRef.set({
        'anon': anonName,
      });
    }

    setState(() {
      sessionId = id;
      inChat = true;
      isCreator = false;
    });
  }

  // ================= SEND =================
  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty || sessionId == null) return;

    await FirebaseFirestore.instance
        .collection('talkitout_sessions')
        .doc(sessionId)
        .collection('messages')
        .add({
      'text': _msgCtrl.text.trim(),
      'sender': anonName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _msgCtrl.clear();
  }

  // ================= EXIT =================
  Future<void> _exitChat() async {
    if (sessionId == null) return;

    final ref = FirebaseFirestore.instance
        .collection('talkitout_sessions')
        .doc(sessionId);

    if (isCreator) {
      final msgs = await ref.collection('messages').get();
      for (var d in msgs.docs) {
        await d.reference.delete();
      }
      await ref.delete();
    } else {
      await ref.collection('participants').doc(userId).delete();
    }

    setState(() {
      sessionId = null;
      anonName = null;
      inChat = false;
    });
  }

  // ================= SAFE BACK =================
  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home'); // 🔥 change if your route differs
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        title: const Text(
          'TALK IT OUT ZONE',
          style: TextStyle(color: Colors.white),
        ),
        leading: inChat
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _handleBack, // 🔥 FIXED
              )
            : null,
        actions: inChat
            ? [
                TextButton(
                  onPressed: _exitChat,
                  child: Text(
                    isCreator ? 'End' : 'Leave',
                    style: const TextStyle(color: Colors.white),
                  ),
                )
              ]
            : [],
      ),
      body: inChat ? _chatUI() : _entryUI(),
    );
  }

  Widget _entryUI() {
    return Center(
      child: GestureDetector(
        onTap: _startSession,
        child: Container(
          width: 220,
          height: 220,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF60A5FA), Color(0xFF818CF8)],
            ),
          ),
          child: const Center(
            child: Text(
              "Let's Talk",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chatUI() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('talkitout_sessions')
                .doc(sessionId)
                .collection('messages')
                .orderBy('createdAt')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final msg = docs[i].data() as Map<String, dynamic>;
                  final isMe = msg['sender'] == anonName;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(msg['sender'] ?? '',
                            style: const TextStyle(fontSize: 11)),
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFFA5B4FC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(msg['text'] ?? ''),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: 'Type here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}