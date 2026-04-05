import 'package:cloud_firestore/cloud_firestore.dart';

class MentionCandidate {
  const MentionCandidate({
    required this.userId,
    required this.name,
    required this.role,
  });

  final String userId;
  final String name;
  final String role;
}

class MentionService {
  MentionService({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<List<MentionCandidate>> fetchAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs
        .map(
          (doc) => MentionCandidate(
            userId: doc.id,
            name: (doc.data()['name'] ?? 'User').toString(),
            role: (doc.data()['role'] ?? '').toString(),
          ),
        )
        .toList();
  }

  Future<List<MentionCandidate>> fetchUsersByIds(List<String> userIds) async {
    final uniqueIds = userIds.toSet().where((id) => id.trim().isNotEmpty).toList();
    if (uniqueIds.isEmpty) {
      return const [];
    }

    final users = <MentionCandidate>[];

    for (final userId in uniqueIds) {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) {
        continue;
      }

      final data = doc.data()!;
      users.add(
        MentionCandidate(
          userId: doc.id,
          name: (data['name'] ?? 'User').toString(),
          role: (data['role'] ?? '').toString(),
        ),
      );
    }

    return users;
  }

  List<MentionCandidate> extractMentions({
    required String text,
    required List<MentionCandidate> candidates,
    String? excludeUserId,
  }) {
    final matched = <String, MentionCandidate>{};
    final lowerText = text.toLowerCase();
    final sortedCandidates = [...candidates]
      ..sort((a, b) => b.name.length.compareTo(a.name.length));

    for (final candidate in sortedCandidates) {
      if (candidate.userId == excludeUserId) {
        continue;
      }

      final patterns = _buildPatterns(candidate.name);
      final hasMatch = patterns.any((pattern) {
        final index = lowerText.indexOf(pattern);
        if (index == -1) {
          return false;
        }

        final endIndex = index + pattern.length;
        if (endIndex >= lowerText.length) {
          return true;
        }

        return _isBoundary(lowerText[endIndex]);
      });

      if (hasMatch) {
        matched[candidate.userId] = candidate;
      }
    }

    return matched.values.toList();
  }

  List<String> extractMentionedUserIds({
    required String text,
    required List<MentionCandidate> candidates,
    String? excludeUserId,
  }) {
    return extractMentions(
      text: text,
      candidates: candidates,
      excludeUserId: excludeUserId,
    ).map((user) => user.userId).toList();
  }

  List<String> buildSuggestions({
    required String query,
    required List<MentionCandidate> candidates,
    String? excludeUserId,
  }) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) {
      return candidates
          .where((candidate) => candidate.userId != excludeUserId)
          .map((candidate) => candidate.userId)
          .take(5)
          .toList();
    }

    return candidates
        .where((candidate) {
          if (candidate.userId == excludeUserId) {
            return false;
          }

          final normalizedName = _normalize(candidate.name);
          return normalizedName.contains(normalizedQuery);
        })
        .map((candidate) => candidate.userId)
        .take(5)
        .toList();
  }

  static String currentMentionQuery(String text, int cursorIndex) {
    if (cursorIndex < 0 || cursorIndex > text.length) {
      return '';
    }

    final uptoCursor = text.substring(0, cursorIndex);
    final atIndex = uptoCursor.lastIndexOf('@');

    if (atIndex == -1) {
      return '';
    }

    final query = uptoCursor.substring(atIndex + 1);
    if (query.contains(RegExp(r'[\s.,!?;:()\[\]{}]'))) {
      return '';
    }

    return query;
  }

  static String insertMention({
    required String text,
    required int cursorIndex,
    required String mentionName,
  }) {
    final safeCursor = cursorIndex < 0
        ? 0
        : (cursorIndex > text.length ? text.length : cursorIndex);
    final uptoCursor = text.substring(0, safeCursor);
    final atIndex = uptoCursor.lastIndexOf('@');

    if (atIndex == -1) {
      return text;
    }

    final before = text.substring(0, atIndex);
    final after = text.substring(safeCursor);
    return '$before@$mentionName $after';
  }

  List<String> _buildPatterns(String name) {
    final patterns = <String>{
      '@${name.toLowerCase()}',
      '@${_normalize(name)}',
    };

    return patterns.where((pattern) => pattern.length > 1).toList();
  }

  bool _isBoundary(String char) {
    return RegExp(r'[^a-z0-9_]').hasMatch(char);
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
