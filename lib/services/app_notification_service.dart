import 'package:cloud_firestore/cloud_firestore.dart';

import 'mention_service.dart';

class NotificationTab {
  static const String personal = 'personal';
  static const String clubs = 'clubs';
  static const String admin = 'admin';
}

class AppNotificationService {
  AppNotificationService({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> sendNotification({
    required String userId,
    required String type,
    required String tab,
    required String title,
    required String message,
    Map<String, dynamic>? extraData,
  }) async {
    final payload = <String, dynamic>{
      'type': type,
      'tab': tab,
      'title': title,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
      ...?extraData,
    };

    await _db.collection('users').doc(userId).collection('notifications').add(
          payload,
        );
  }

  Future<void> sendMentionNotifications({
    required List<MentionCandidate> mentionedUsers,
    required String senderId,
    required String senderName,
    required String sourceType,
    required String sourceId,
    required String sourceText,
    required bool senderIsAdmin,
    String? clubId,
    String? clubName,
  }) async {
    if (mentionedUsers.isEmpty) {
      return;
    }

    final isClubContext = (clubId ?? '').trim().isNotEmpty;
    final tab = isClubContext
        ? NotificationTab.clubs
        : senderIsAdmin
            ? NotificationTab.admin
            : NotificationTab.personal;
    final type = isClubContext
        ? 'club_mention'
        : senderIsAdmin
            ? 'admin_mention'
            : 'mention';
    final title = _mentionTitle(
      senderName: senderName,
      sourceType: sourceType,
      isClubContext: isClubContext,
    );

    final batch = _db.batch();

    for (final user in mentionedUsers) {
      if (user.userId == senderId) {
        continue;
      }

      final notificationRef = _db
          .collection('users')
          .doc(user.userId)
          .collection('notifications')
          .doc();

      batch.set(notificationRef, {
        'type': type,
        'tab': tab,
        'title': title,
        'message': sourceText,
        'senderId': senderId,
        'senderName': senderName,
        'sourceType': sourceType,
        'sourceId': sourceId,
        'clubId': clubId ?? '',
        'clubName': clubName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });
    }

    await batch.commit();
  }

  Future<void> sendClubAnnouncementNotification({
    required List<String> memberIds,
    required String senderId,
    required String senderName,
    required String clubId,
    required String clubName,
    required String announcementId,
    required String announcementText,
  }) async {
    final recipients = memberIds.where((id) => id != senderId).toSet().toList();
    if (recipients.isEmpty) {
      return;
    }

    final batch = _db.batch();

    for (final memberId in recipients) {
      final notificationRef = _db
          .collection('users')
          .doc(memberId)
          .collection('notifications')
          .doc();

      batch.set(notificationRef, {
        'type': 'club_notice',
        'tab': NotificationTab.clubs,
        'title': '$senderName posted a club notice',
        'message': announcementText,
        'senderId': senderId,
        'senderName': senderName,
        'clubId': clubId,
        'clubName': clubName,
        'sourceType': 'announcement',
        'sourceId': announcementId,
        'createdAt': FieldValue.serverTimestamp(),
        'seen': false,
      });
    }

    await batch.commit();
  }

  String _mentionTitle({
    required String senderName,
    required String sourceType,
    required bool isClubContext,
  }) {
    switch (sourceType) {
      case 'post':
        return '$senderName mentioned you in a post';
      case 'comment':
        return '$senderName mentioned you in a comment';
      case 'club_post':
        return '$senderName mentioned you in a club post';
      case 'club_chat':
        return '$senderName mentioned you in club chat';
      case 'announcement':
        return '$senderName mentioned you in a club notice';
      default:
        return isClubContext
            ? '$senderName mentioned you in a club update'
            : '$senderName mentioned you';
    }
  }
}
