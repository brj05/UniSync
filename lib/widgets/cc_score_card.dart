import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CCScoreCard extends StatelessWidget {
  final String profileUserId;
  final bool canView;

  const CCScoreCard({
    super.key,
    required this.profileUserId,
    required this.canView,
  });

  @override
  Widget build(BuildContext context) {
    if (!canView) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(profileUserId)
          .collection('approved_hours')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCard(
            context,
            heading: 'CC Score',
            subtitle: 'Loading progress...',
            progress: 0,
            percentage: 0,
            isCompleted: false,
          );
        }

        final docs = snapshot.data?.docs ?? [];
        int totalHoursOnly = 0;
        int totalMinutesOnly = 0;

        for (final doc in docs) {
          final data = doc.data();
          totalHoursOnly += (data['hours'] ?? data['approvedHours'] ?? 0) as int;
          totalMinutesOnly +=
              (data['minutes'] ?? data['approvedMinutes'] ?? 0) as int;
        }

        totalHoursOnly += totalMinutesOnly ~/ 60;
        totalMinutesOnly = totalMinutesOnly % 60;

        final totalHours = totalHoursOnly + (totalMinutesOnly / 60);
        final progress = (totalHours / 30).clamp(0.0, 1.0);
        final percentage = (progress * 100).round();
        final isCompleted = totalHours >= 30;

        return _buildCard(
          context,
          heading: isCompleted ? 'CC Completed' : 'CC Score',
          subtitle: isCompleted
              ? '30h completed successfully'
              : '${totalHoursOnly}h ${totalMinutesOnly}m out of 30h completed',
          progress: progress,
          percentage: percentage,
          isCompleted: isCompleted,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String heading,
    required String subtitle,
    required double progress,
    required int percentage,
    required bool isCompleted,
  }) {
    final fillColor =
        isCompleted ? const Color(0xFF7C3AED) : const Color(0xFF8B5CF6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF6F0FF),
            Color(0xFFEEE6FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E1065),
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7EE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF1F9D55),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: Color(0xFF1F9D55),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 13,
                    color: const Color(0xFFDCCFFB),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      tween: Tween<double>(begin: 0, end: progress),
                      builder: (context, animatedProgress, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: animatedProgress,
                            child: Container(color: fillColor),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: fillColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
