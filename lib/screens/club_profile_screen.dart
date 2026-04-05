import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/app_notification_service.dart';
import '../services/mention_service.dart';
import '../services/session_service.dart';
import '../widgets/mention_text_field.dart';
import 'club_public_profile_screen.dart';
import 'personal_chat_screen.dart';
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
  final TextEditingController memberController = TextEditingController();
  final MentionService _mentionService = MentionService();
  final AppNotificationService _notificationService =
      AppNotificationService();

  String? myPhone;
  String myName = 'You';
  String myRole = '';
  String _clubName = 'Club';
  List<MentionCandidate> _clubMentionCandidates = [];
  String _memberSignature = '';

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
        myRole = userDoc.data()?['role']?.toString() ?? '';
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    messageController.dispose();
    postController.dispose();
    announcementController.dispose();
    memberController.dispose();
    super.dispose();
  }

  Future<void> _syncClubMentionCandidates(
    List<String> memberIds,
    String clubName,
  ) async {
    final signature = [...memberIds]..sort();
    final nextSignature = signature.join('|');

    if (_memberSignature == nextSignature && _clubName == clubName) {
      return;
    }

    _memberSignature = nextSignature;
    _clubName = clubName;

    final users = await _mentionService.fetchUsersByIds(memberIds);
    if (!mounted) {
      return;
    }

    setState(() {
      _clubMentionCandidates = users;
      _clubName = clubName;
    });
  }

  Future<void> _sendChatMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || myPhone == null) return;

    final mentionedUsers = _mentionService.extractMentions(
      text: text,
      candidates: _clubMentionCandidates,
      excludeUserId: myPhone,
    );
    final messageRef = FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.clubId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'message': text,
      'senderPhone': myPhone,
      'senderName': myName,
      'taggedUsers': mentionedUsers.map((user) => user.userId).toList(),
      'time': FieldValue.serverTimestamp(),
    });

    await _notificationService.sendMentionNotifications(
      mentionedUsers: mentionedUsers,
      senderId: myPhone!,
      senderName: myName,
      sourceType: 'club_chat',
      sourceId: messageRef.id,
      sourceText: text,
      senderIsAdmin: myRole == 'admin',
      clubId: widget.clubId,
      clubName: _clubName,
    );

    messageController.clear();
  }

  Future<void> _sharePost() async {
    final text = postController.text.trim();
    if (text.isEmpty || myPhone == null) return;

    final mentionedUsers = _mentionService.extractMentions(
      text: text,
      candidates: _clubMentionCandidates,
      excludeUserId: myPhone,
    );
    final postRef = FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.clubId)
        .collection('posts')
        .doc();

    await postRef.set({
      'text': text,
      'senderPhone': myPhone,
      'senderName': myName,
      'taggedUsers': mentionedUsers.map((user) => user.userId).toList(),
      'time': FieldValue.serverTimestamp(),
    });

    await _notificationService.sendMentionNotifications(
      mentionedUsers: mentionedUsers,
      senderId: myPhone!,
      senderName: myName,
      sourceType: 'club_post',
      sourceId: postRef.id,
      sourceText: text,
      senderIsAdmin: myRole == 'admin',
      clubId: widget.clubId,
      clubName: _clubName,
    );

    postController.clear();
  }

  Future<void> _postAnnouncement() async {
    final text = announcementController.text.trim();
    if (text.isEmpty || myPhone == null) return;

    final mentionedUsers = _mentionService.extractMentions(
      text: text,
      candidates: _clubMentionCandidates,
      excludeUserId: myPhone,
    );
    final announcementRef = FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.clubId)
        .collection('announcements')
        .doc();

    await announcementRef.set({
      'text': text,
      'senderPhone': myPhone,
      'senderName': myName,
      'taggedUsers': mentionedUsers.map((user) => user.userId).toList(),
      'time': FieldValue.serverTimestamp(),
    });

    await _notificationService.sendClubAnnouncementNotification(
      memberIds: _clubMentionCandidates.map((user) => user.userId).toList(),
      senderId: myPhone!,
      senderName: myName,
      clubId: widget.clubId,
      clubName: _clubName,
      announcementId: announcementRef.id,
      announcementText: text,
    );

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

  Future<void> _addMember(String memberId) async {
    final clubRef = FirebaseFirestore.instance.collection('clubs').doc(widget.clubId);
    final clubDoc = await clubRef.get();
    final members = List<String>.from(clubDoc.data()?['members'] ?? []);

    if (!members.contains(memberId)) {
      members.add(memberId);
      await clubRef.update({'members': members});
    }
  }

  Future<void> _removeMember(String memberId) async {
    final clubRef = FirebaseFirestore.instance.collection('clubs').doc(widget.clubId);
    final clubDoc = await clubRef.get();
    final members = List<String>.from(clubDoc.data()?['members'] ?? []);
    members.remove(memberId);
    await clubRef.update({'members': members});
  }

  Future<void> _showAddMemberDialog(List<String> admins) async {
    final clubDoc = await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.clubId)
        .get();
    final existingMembers = List<String>.from(clubDoc.data()?['members'] ?? []);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Member'),
        content: TypeAheadField<Map<String, dynamic>>(
          controller: memberController,
          suggestionsCallback: (pattern) async {
            final query = pattern.trim().toLowerCase();
            if (query.isEmpty) {
              return const <Map<String, dynamic>>[];
            }

            final snap = await FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .get();

            return snap.docs
                .where((doc) => !existingMembers.contains(doc.id))
                .where((doc) => !admins.contains(doc.id))
                .where((doc) {
                  final name = (doc.data()['name'] ?? '').toString().toLowerCase();
                  return name.contains(query);
                })
                .map(
                  (doc) => {
                    'id': doc.id,
                    'name': (doc.data()['name'] ?? 'Student').toString(),
                  },
                )
                .take(6)
                .toList();
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              title: Text(suggestion['name'].toString()),
              subtitle: Text(suggestion['id'].toString()),
            );
          },
          onSelected: (suggestion) async {
            await _addMember(suggestion['id'].toString());
            memberController.clear();
            if (!mounted) return;
            Navigator.pop(dialogContext);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${suggestion['name']} added to the club'),
              ),
            );
          },
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Search a student',
                border: OutlineInputBorder(),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPersonalChat({
    required String receiverId,
    required String receiverName,
    required String? receiverPhotoUrl,
  }) {
    if (myPhone == null || receiverId == myPhone) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalChatScreen(
          receiverId: receiverId,
          receiverName: receiverName,
          receiverPhotoUrl: receiverPhotoUrl,
        ),
      ),
    );
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
        final members = List<String>.from(clubData['members'] ?? []);
        final clubName = (clubData['name'] ?? 'Club').toString();

        _syncClubMentionCandidates(members, clubName);

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
                 clubName,
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
                  child: MentionTextField(
                    controller: messageController,
                    candidates: _clubMentionCandidates,
                    excludeUserId: myPhone,
                    decoration: InputDecoration(
                      hintText: 'Type a message... Use @ to tag a member',
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

        final canManageMembers = myPhone == creatorPhone;

        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: members.length + (canManageMembers ? 1 : 0),
          itemBuilder: (_, index) {
            if (canManageMembers && index == 0) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF8B5CF6),
                    child: Icon(Icons.person_add, color: Colors.white),
                  ),
                  title: const Text('Add Member'),
                  subtitle: const Text('Creator can add non-admin members'),
                  onTap: () => _showAddMemberDialog(admins),
                ),
              );
            }

            final memberPhone = members[canManageMembers ? index - 1 : index];

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
                final avatar = userData['avatar']?.toString();
                final isCurrentUser = memberPhone == myPhone;

                String role = '';
                if (memberPhone == creatorPhone) {
                  role = 'Creator';
                } else if (admins.contains(memberPhone)) {
                  role = 'Admin';
                }
                final canRemove = canManageMembers &&
                    memberPhone != creatorPhone &&
                    !admins.contains(memberPhone);

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
                    trailing: isCurrentUser
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.message_outlined,
                                  color: Color(0xFF8B5CF6),
                                ),
                                onPressed: () => _openPersonalChat(
                                  receiverId: memberPhone,
                                  receiverName: name.toString(),
                                  receiverPhotoUrl: avatar,
                                ),
                              ),
                              if (canRemove)
                                IconButton(
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _removeMember(memberPhone),
                                ),
                            ],
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
                child: MentionTextField(
                  controller: announcementController,
                  candidates: _clubMentionCandidates,
                  excludeUserId: myPhone,
                  decoration: InputDecoration(
                    hintText: 'Write announcement... Use @ to tag members',
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
                        const Row(
                          children: [
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
