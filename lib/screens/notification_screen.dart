import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_service.dart';
import 'talk_zone.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _showClubRequestDialog(
    BuildContext context,
    Map<String, dynamic> data,
    String notificationId,
    String userId,
  ) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['clubName'] ?? 'Club Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Creator: ${data['creatorName'] ?? ''}'),
              const SizedBox(height: 10),
              Text('About: ${data['about'] ?? ''}'),
              const SizedBox(height: 14),
              const Text(
                'Members:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(List.from(data['members'] ?? [])).map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${member['name']}'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final requestId = data['clubRequestId'];

              await FirebaseFirestore.instance
                  .collection('club_requests')
                  .doc(requestId)
                  .delete();

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('notifications')
                  .doc(notificationId)
                  .delete();

              if (mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Club request rejected'),
                  ),
                );
              }
            },
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () async {
              final requestId = data['clubRequestId'];

              final requestDoc = await FirebaseFirestore.instance
                  .collection('club_requests')
                  .doc(requestId)
                  .get();

              if (!requestDoc.exists) return;

              final requestData = requestDoc.data()!;

              final List invitedMembers =
                  requestData['invitedMembers'] ?? [];

              await FirebaseFirestore.instance.collection('clubs').add({
                'name': requestData['name'],
                'about': requestData['about'],
                'createdBy': requestData['createdBy'],
                'adminName': requestData['createdByName'],
                'members': [
                  requestData['createdBy'],
                  ...invitedMembers,
                ],
                'followers': [],
                'createdAt': FieldValue.serverTimestamp(),
              });

              await FirebaseFirestore.instance
                  .collection('club_requests')
                  .doc(requestId)
                  .delete();

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('notifications')
                  .doc(notificationId)
                  .delete();

              if (mounted) {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Club approved successfully'),
                  ),
                );
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNotifications() {
    return [
      FutureBuilder<Map<String, String>?>(
        future: SessionService.getSession(),
        builder: (context, sessionSnap) {
          if (sessionSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = sessionSnap.data;

          if (session == null) {
            return const Center(child: Text('User not logged in'));
          }

          final userId = session['phone'];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snap.hasError) {
                return Center(
                  child: Text('Error: ${snap.error}'),
                );
              }

              if (!snap.hasData) {
                return const Center(child: Text('No notifications'));
              }

              final docs = snap.data!.docs;

              if (_tabController.index == 0) {
                final personalDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['sessionId'] != null;
                }).toList();

                if (personalDocs.isEmpty) {
                  return const Center(
                    child: Text('No personal notifications'),
                  );
                }

                return Column(
                  children: personalDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(
                        '${data['creatorAnon']} started a TalkItOut',
                      ),
                      trailing: TextButton(
                        child: const Text('Join'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TalkItOutScreen(
                                sessionIdFromNotification:
                                    data['sessionId'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              }

              if (_tabController.index == 1) {
                final clubDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['type'] == 'club_request';
                }).toList();

                if (clubDocs.isEmpty) {
                  return const Center(
                    child: Text('No club notifications'),
                  );
                }

                return Column(
                  children: clubDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(
                          data['clubName'] ?? 'Club Request',
                        ),
                        subtitle: Text(
                          '${data['creatorName']} sent a club request',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showClubRequestDialog(
                          context,
                          data,
                          doc.id,
                          userId!,
                        ),
                      ),
                    );
                  }).toList(),
                );
              }

              return const Center(
                child: Text('No admin notifications'),
              );
            },
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildHomeAppBar(context),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            tabs: const [
              Tab(text: 'Personal'),
              Tab(text: 'Clubs'),
              Tab(text: 'Admin'),
            ],
          ),
          Expanded(
            child: ListView(
              children: _buildNotifications(),
            ),
          ),
        ],
      ),
    );
  }
}
