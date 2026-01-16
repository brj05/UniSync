import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_service.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/post_card.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // null → current user

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String? currentUserId;
  Map<String, dynamic>? currentUserData;

  late TabController _tabController; // ✅ REQUIRED

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // ✅ REQUIRED
    _loadSession();
  }

  @override
  void dispose() {
    _tabController.dispose(); // ✅ REQUIRED
    super.dispose();
  }

  Future<void> _loadSession() async {
    final session = await SessionService.getSession();
    if (session == null) return;

    currentUserId = session['phone'];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (!userDoc.exists) return;

    currentUserData = userDoc.data();

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profileUserId = widget.userId ?? currentUserId;

    if (profileUserId == null || currentUserData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: buildHomeAppBar(context),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(profileUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isOwnProfile = profileUserId == currentUserId;

          final avatar = data['avatar'] ?? '';
          final name =
              (data['profileName']?.toString().isNotEmpty ?? false)
                  ? data['profileName']
                  : data['name'];
          final bio = data['bio'] ?? '';

          return Column(
            children: [
              /// PROFILE HEADER
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          avatar.toString().isNotEmpty
                              ? NetworkImage(avatar)
                              : null,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat('Posts', data['NoOfPosts'] ?? 0),
                          _stat('Followers', data['followersCount'] ?? 0),
                          _stat('Following', data['followingCount'] ?? 0),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// NAME + BIO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (bio.toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(bio, style: const TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              /// ACTION BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isOwnProfile
                    ? SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(
                                  userId: profileUserId,
                                  currentName: name ?? '',
                                  currentBio: bio,
                                ),
                              ),
                            );
                          },
                          child: const Text('Edit Profile'),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              child: const Text('Follow'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              child: const Text('Message'),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 12),

              /// TAB BAR (RESTORED)
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.black,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(icon: Icon(Icons.person_pin_outlined)),
                ],
              ),

              /// TAB CONTENT
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _userPosts(profileUserId),
                    const Center(child: Text('Tagged posts')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  /// USER POSTS (LIST ONLY)
  Widget _userPosts(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }

        final posts = snapshot.data!.docs.toList();

        posts.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;
          return (bTime?.millisecondsSinceEpoch ?? 0)
              .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
        });

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final data = post.data() as Map<String, dynamic>;

            return PostCard(
              postId: post.id,
              authorId: data['authorId'],
              currentUserId: currentUserId!,
              currentUserName: currentUserData!['name'],
              currentUserAvatar: currentUserData!['avatar'],
              authorName: data['authorName'],
              authorAvatar: data['authorAvatar'],
              caption: data['caption'],
              imageUrl: data['imageUrl'],
              likes: data['likesCount'] ?? 0,
              comments: data['commentsCount'] ?? 0,
              views: data['viewCount'] ?? 0,
              clubName: data['clubName'],
              isLiked:
                  (data['likedBy'] ?? []).contains(currentUserId),
            );
          },
        );
      },
    );
  }
}
