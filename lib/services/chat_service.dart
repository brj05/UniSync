import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String generateChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<String> getOrCreateChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final participants = [currentUserId, otherUserId]..sort();
    final chatId = generateChatId(currentUserId, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(chatRef);

      if (!snapshot.exists) {
        transaction.set(chatRef, {
          'participants': participants,
          'lastMessage': '',
          'lastMessageTime': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final data = snapshot.data();
      final existingParticipants = List<String>.from(
        data?['participants'] ?? const <String>[],
      )..sort();

      if (existingParticipants.length != 2 ||
          existingParticipants[0] != participants[0] ||
          existingParticipants[1] != participants[1]) {
        transaction.set(
          chatRef,
          {'participants': participants},
          SetOptions(merge: true),
        );
      }
    });

    return chatId;
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    final chatId = await getOrCreateChat(
      currentUserId: senderId,
      otherUserId: receiverId,
    );

    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    // Enable Firestore TTL later in Firebase Console:
    // Firestore -> TTL Policies -> messages.expiresAt
    final expiresAt = Timestamp.fromDate(
      now.add(const Duration(hours: 24)),
    );

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': trimmedText,
      'timestamp': timestamp,
      'createdAt': timestamp,
      'expiresAt': expiresAt,
    };

    final chatData = {
      'participants': ([senderId, receiverId]..sort()),
      'lastMessage': trimmedText,
      'lastMessageTime': timestamp,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();
    batch.set(messageRef, messageData);
    batch.set(chatRef, chatData, SetOptions(merge: true));
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
