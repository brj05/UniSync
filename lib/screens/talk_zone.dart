import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/anonymous_name.dart';

class TalkItOutScreen extends StatefulWidget {
  const TalkItOutScreen({super.key});

  @override
  State<TalkItOutScreen> createState() => _TalkItOutScreenState();
}

class _TalkItOutScreenState extends State<TalkItOutScreen> {
  String? sessionId;
  String? anonName;
  bool inChat = false;
  bool isCreator = true; // creator-side for now

  final TextEditingController _msgCtrl = TextEditingController();

  String get userId => FirebaseAuth.instance.currentUser!.uid;

  // ================= CREATE SESSION =================
  Future<void> _startSession() async {
    anonName = AnonymousName.generate();

    final ref =
        FirebaseFirestore.instance.collection('talkitout_sessions').doc();

    setState(() {
      sessionId = ref.id;
      inChat = true;
    });

    await ref.set({
      'creatorId': userId,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await ref.collection('participants').doc(userId).set({
      'anon': anonName,
    });
  }

  // ================= SEND MESSAGE =================
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

  // ================= END / LEAVE =================
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

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        leading: inChat
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context); // ✅ ONLY NAVIGATION
                },
              )
            : null,
        title: const Text(
          'TALK IT OUT ZONE',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: inChat
            ? [
                TextButton(
                  onPressed: _exitChat,
                  child: Text(
                    isCreator ? 'End' : 'Leave',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ]
            : [],
      ),
      body: inChat ? _chatUI() : _entryUI(),
    );
  }

  // ================= ENTRY =================
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
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= CHAT =================
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
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        // 🔹 Anonymous Name
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2, left: 6, right: 6),
                          child: Text(
                            msg['sender'] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // 🔹 Message Bubble
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFFA5B4FC),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            msg['text'],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // ================= INPUT BAR =================
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFFEDE9FE),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type here...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
