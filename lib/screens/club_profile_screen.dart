import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'club_public_profile_screen.dart';
class ClubProfileScreen extends StatefulWidget {
  final String clubId;

  const ClubProfileScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<ClubProfileScreen> createState() => _ClubProfileScreenState();
}

class _ClubProfileScreenState extends State<ClubProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController messageController = TextEditingController();
  final TextEditingController postController = TextEditingController();
  final TextEditingController announcementController = TextEditingController();

  String? myPhone;
  String myName = 'You';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    myPhone = await SessionService.getPhone();

    if (myPhone != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(myPhone)
          .get();

      if (userDoc.exists) {
        myName = userDoc.data()?['name'] ?? 'You';
      }
    }

    setState(() {});
  }

  Future<void> _sendChatMessage() async {
    if (messageController.text.trim().isEmpty || myPhone == null) return;

    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.clubId)
        .collection('messages')
        .add({
      'message': messageController.text.trim(),
      'senderPhone': myPhone,
      'senderName': myName,
      'time': FieldValue.serverTimestamp(),
    });

    messageController.clear();
  }

  Future<void> _sharePost() async {
    if (postController.text.trim().isEmpty || myPhone == null) return;

    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.clubId)
        .collection('posts')
        .add({
      'text': postController.text.trim(),
      'senderPhone': myPhone,
      'senderName': myName,
      'time': FieldValue.serverTimestamp(),
    });

    postController.clear();
  }

  Future<void> _postAnnouncement() async {
    if (announcementController.text.trim().isEmpty || myPhone == null) return;

    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.clubId)
        .collection('announcements')
        .add({
      'text': announcementController.text.trim(),
      'senderPhone': myPhone,
      'senderName': myName,
      'time': FieldValue.serverTimestamp(),
    });

    announcementController.clear();
  }

  Future<void> _exitClub() async {
    final clubDoc = await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.clubId)
        .get();

    final members = List<String>.from(clubDoc['members'] ?? []);
    members.remove(myPhone);

    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.clubId)
        .update({'members': members});

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showClubMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Exit Club',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _exitClub();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final club = snapshot.data!;
        final clubData = club.data() as Map<String, dynamic>;

        final creatorPhone = clubData['createdBy'] ?? '';
        final admins = clubData['admins'] is List
            ? List<String>.from(clubData['admins'])
            : <String>[];

        return Scaffold(
          backgroundColor: const Color(0xFFF4F1F8),
          appBar: AppBar(
            backgroundColor: const Color(0xFF8B5CF6),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: GestureDetector(
               onTap: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (_) => ClubPublicProfileScreen(
                       clubId: widget.clubId,
                     ),
                   ),
                 );
               },
               child: Text(
                 clubData['name'] ?? 'Club',
                 style: const TextStyle(
                   color: Colors.white,
                   fontWeight: FontWeight.bold,
                 ),
               ),
             ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: _showClubMenu,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Chat'),
                Tab(text: 'Members'),
                Tab(text: 'Notice'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _chatTab(),
              _membersTab(creatorPhone, admins),
              _noticeTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _chatTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clubs')
                .doc(widget.clubId)
                .collection('messages')
                .orderBy('time', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: docs.length,
                itemBuilder: (_, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final isMine = data['senderPhone'] == myPhone;

                  return Align(
                    alignment:
                        isMine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: isMine
                            ? const Color(0xFF9BC6F8)
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft:
                              Radius.circular(isMine ? 18 : 4),
                          bottomRight:
                              Radius.circular(isMine ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['senderName'] ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['message'] ?? '',
                            style: const TextStyle(fontSize: 16),
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
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: const Color(0xFFF3F3F3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF8B5CF6),
                  child: IconButton(
                    onPressed: _sendChatMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _membersTab(String creatorPhone, List<String> admins) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubId)
          .get(),
      builder: (context, clubSnapshot) {
        if (!clubSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final clubData = clubSnapshot.data!.data() as Map<String, dynamic>;
        final members = List<String>.from(clubData['members'] ?? []);

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: members.length,
          itemBuilder: (_, index) {
            final memberPhone = members[index];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(memberPhone)
                  .get(),
              builder: (_, userSnapshot) {
                final userData = userSnapshot.data?.data()
                        as Map<String, dynamic>? ??
                    {};

                final name = userData['name'] ?? memberPhone;

                String role = '';
                if (memberPhone == creatorPhone) {
                  role = 'Creator';
                } else if (admins.contains(memberPhone)) {
                  role = 'Admin';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF8B5CF6),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(name),
                    subtitle: role.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9DDFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.message_outlined,
                        color: Color(0xFF8B5CF6),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Open chat with $name'),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _noticeTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: announcementController,
                  decoration: InputDecoration(
                    hintText: 'Write announcement...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                ),
                onPressed: _postAnnouncement,
                child: const Text('Send'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clubs')
                .doc(widget.clubId)
                .collection('announcements')
                .orderBy('time', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1CC),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.campaign,
                                color: Color(0xFFB7791F)),
                            SizedBox(width: 8),
                            Text(
                              'Announcement',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(data['text'] ?? ''),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}