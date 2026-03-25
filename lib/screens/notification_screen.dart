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

  List<Widget> _buildNotifications() {
    if (_tabController.index != 0) {
      return const [Center(child: Text("No data"))];
    }

    return [
      FutureBuilder<Map<String, String>?>(
        future: SessionService.getSession(),
        builder: (context, sessionSnap) {
          if (!sessionSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final session = sessionSnap.data;
          if (session == null) {
            return const Center(child: Text("User not logged in"));
          }

          final userId = session['phone'];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Center(child: Text("No notifications"));
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return ListTile(
                    title: Text(
                      '${data['creatorAnon']} started a TalkItOut',
                    ),
                    trailing: TextButton(
                      child: const Text("Join"),
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