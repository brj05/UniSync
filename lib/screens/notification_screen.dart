import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../services/session_service.dart';
import '../widgets/home_app_bar.dart';
import 'talk_zone.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PostService _postService = PostService();

  String? _currentUserId;
  String _currentUserName = 'User';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final session = await SessionService.getSession();
    if (session == null) return;

    final userId = session['phone'];
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!mounted) return;

    setState(() {
      _currentUserId = userId;
      _currentUserName = userDoc.data()?['name'] ?? 'User';
    });
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
                  child: Text('- ${member['name']}'),
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
                  const SnackBar(content: Text('Club request rejected')),
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
              final List invitedMembers = requestData['invitedMembers'] ?? [];

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
                  const SnackBar(content: Text('Club approved successfully')),
                );
              }
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPostVerificationDialog(
    Map<String, dynamic> data,
    String notificationId,
  ) async {
    if (_currentUserId == null) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            const Expanded(
              child: Text(
                'Post Verification',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: ${data['studentName'] ?? 'Student'}'),
            const SizedBox(height: 8),
            Text('Hours: ${data['requestedHours'] ?? 0}'),
            const SizedBox(height: 4),
            Text('Minutes: ${data['requestedMinutes'] ?? 0}'),
            const SizedBox(height: 12),
            Text('Description: ${data['verificationDescription'] ?? ''}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await _postService.approvePostVerification(
                postId: data['postId'] ?? '',
                adminId: _currentUserId!,
                adminName: _currentUserName,
                studentId: data['studentId'] ?? '',
                studentName: data['studentName'] ?? 'Student',
                requestedHours: data['requestedHours'] ?? 0,
                requestedMinutes: data['requestedMinutes'] ?? 0,
                notificationId: notificationId,
              );

              if (!mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Post approved successfully')),
              );
            },
            child: const Text('Approve'),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _showPostRemarkInputDialog(data, notificationId);
            },
            child: const Text('Pending'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPostRemarkInputDialog(
    Map<String, dynamic> data,
    String notificationId,
  ) async {
    if (_currentUserId == null) return;

    final remarkController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Remark'),
        content: TextField(
          controller: remarkController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Tell the student what to update',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final remark = remarkController.text.trim();
              if (remark.isEmpty) return;

              await _postService.sendPostRemark(
                postId: data['postId'] ?? '',
                adminId: _currentUserId!,
                adminName: _currentUserName,
                studentId: data['studentId'] ?? '',
                studentName: data['studentName'] ?? 'Student',
                notificationId: notificationId,
                remark: remark,
              );

              if (!mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Remark sent to student')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );

    remarkController.dispose();
  }

  Future<void> _showStudentRemarkDialog(
    Map<String, dynamic> data,
    String notificationId,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            const Expanded(
              child: Text(
                'Admin Remark',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(data['remark'] ?? ''),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _showEditPostDialog(data, notificationId);
            },
            child: const Text('Edit Post'),
          ),
        ],
      ),
    );
  }

  Future<void> _showApprovedDialog(Map<String, dynamic> data) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Post Approved'),
        content: Text(
          'Approved for ${data['approvedHours'] ?? 0} hours and ${data['approvedMinutes'] ?? 0} minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPostDialog(
    Map<String, dynamic> data,
    String notificationId,
  ) async {
    if (_currentUserId == null) return;

    final postDoc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(data['postId'])
        .get();

    if (!postDoc.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post not found')), 
      );
      return;
    }

    final postData = postDoc.data()!;
    final hoursController = TextEditingController(
      text: (postData['requestedHours'] ?? 0).toString(),
    );
    final minutesController = TextEditingController(
      text: (postData['requestedMinutes'] ?? 0).toString(),
    );
    final descriptionController = TextEditingController(
      text: postData['verificationDescription'] ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Verification Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Requested Hours',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Requested Minutes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Verification Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final requestedHours = int.tryParse(hoursController.text.trim()) ?? 0;
              final requestedMinutes = int.tryParse(minutesController.text.trim()) ?? 0;
              final verificationDescription = descriptionController.text.trim();

              if ((requestedHours <= 0 && requestedMinutes <= 0) ||
                  verificationDescription.isEmpty) {
                return;
              }

              await _postService.updatePostVerificationRequest(
                postId: data['postId'] ?? '',
                studentId: _currentUserId!,
                taggedAdminId: (postData['taggedAdminId'] ?? data['adminId'] ?? '').toString(),
                taggedAdminName: (postData['taggedAdminName'] ?? data['adminName'] ?? '').toString(),
                requestedHours: requestedHours,
                requestedMinutes: requestedMinutes,
                verificationDescription: verificationDescription,
                studentName: _currentUserName,
                remarkNotificationId: notificationId,
              );

              if (!mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification request resent')),
              );
            },
            child: const Text('Resend'),
          ),
        ],
      ),
    );

    hoursController.dispose();
    minutesController.dispose();
    descriptionController.dispose();
  }

  Widget _buildPersonalList(List<QueryDocumentSnapshot> docs) {
    final personalDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['type'] != 'club_request';
    }).toList();

    if (personalDocs.isEmpty) {
      return const Center(child: Text('No personal notifications'));
    }

    return ListView.builder(
      itemCount: personalDocs.length,
      itemBuilder: (context, index) {
        final doc = personalDocs[index];
        final data = doc.data() as Map<String, dynamic>;
        final type = (data['type'] ?? '').toString();

        if (data['sessionId'] != null) {
          return ListTile(
            title: Text('${data['creatorAnon']} started a TalkItOut'),
            trailing: TextButton(
              child: const Text('Join'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TalkItOutScreen(
                      sessionIdFromNotification: data['sessionId'],
                    ),
                  ),
                );
              },
            ),
          );
        }

        if (type == 'post_verification') {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text('${data['studentName'] ?? 'Student'} requested post verification'),
              subtitle: Text(
                '${data['requestedHours'] ?? 0}h ${data['requestedMinutes'] ?? 0}m',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showPostVerificationDialog(data, doc.id),
            ),
          );
        }

        if (type == 'post_remark') {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: const Text('Admin left a remark on your post'),
              subtitle: Text(data['remark'] ?? ''),
              trailing: const Icon(Icons.edit_note),
              onTap: () => _showStudentRemarkDialog(data, doc.id),
            ),
          );
        }

        if (type == 'post_approved') {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: const Text('Your post was approved'),
              subtitle: Text(
                '${data['approvedHours'] ?? 0}h ${data['approvedMinutes'] ?? 0}m approved',
              ),
              trailing: const Icon(Icons.check_circle_outline),
              onTap: () => _showApprovedDialog(data),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildClubList(List<QueryDocumentSnapshot> docs) {
    final clubDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['type'] == 'club_request';
    }).toList();

    if (clubDocs.isEmpty) {
      return const Center(child: Text('No club notifications'));
    }

    return ListView.builder(
      itemCount: clubDocs.length,
      itemBuilder: (context, index) {
        final doc = clubDocs[index];
        final data = doc.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(data['clubName'] ?? 'Club Request'),
            subtitle: Text('${data['creatorName']} sent a club request'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showClubRequestDialog(
              context,
              data,
              doc.id,
              _currentUserId!,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminTab(List<QueryDocumentSnapshot> docs) {
    final adminDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['type'] == 'post_verification';
    }).toList();

    if (adminDocs.isEmpty) {
      return const Center(child: Text('No admin notifications'));
    }

    return ListView.builder(
      itemCount: adminDocs.length,
      itemBuilder: (context, index) {
        final doc = adminDocs[index];
        final data = doc.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text('${data['studentName'] ?? 'Student'} requested verification'),
            subtitle: Text(data['verificationDescription'] ?? ''),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showPostVerificationDialog(data, doc.id),
          ),
        );
      },
    );
  }

  Widget _buildTabBody() {
    if (_currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        final docs = snap.data?.docs ?? [];

        if (_tabController.index == 0) {
          return _buildPersonalList(docs);
        }

        if (_tabController.index == 1) {
          return _buildClubList(docs);
        }

        return _buildAdminTab(docs);
      },
    );
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
          Expanded(child: _buildTabBody()),
        ],
      ),
    );
  }
}
