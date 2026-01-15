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
  late TabController _tabController;

  String? currentUserId;
  Map<String, dynamic>? currentUserData;

  bool gridView = true;

  Stream<QuerySnapshot>? _userPostsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await SessionService.getSession();
    if (session == null) return;

    currentUserId = session['phone'];

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    currentUserData = userDoc.data();

    final profileUserId = widget.userId ?? currentUserId;

    _userPostsStream = FirebaseFirestore.instance
        .collection('posts')
        .where('authorId', isEqualTo: profileUserId)
        .orderBy('createdAt', descending: true)
        .snapshots();

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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final isOwnProfile = profileUserId == currentUserId;

          final avatar = data['avatar'] ?? '';
          final name = (data['profileName']?.toString().isNotEmpty ?? false)
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
                          avatar.isNotEmpty ? NetworkImage(avatar) : null,
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

              /// NAME + BIO (LEFT ALIGNED)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (bio.toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(bio, style: const TextStyle(fontSize: 13)),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              /// ACTION BUTTONS
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

              const SizedBox(height: 10),

              /// TAB BAR (DOUBLE TAP GRID)
              TabBar(
                controller: _tabController,
                tabs: [
                  GestureDetector(
                    onDoubleTap: () {
                      setState(() {
                        gridView = !gridView;
                      });
                    },
                    child: const Tab(icon: Icon(Icons.grid_on)),
                  ),
                  const Tab(icon: Icon(Icons.person_pin_outlined)),
                ],
              ),

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

  /// STATS
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

  /// USER POSTS (NO RELOAD, SINGLE STREAM)
  Widget _userPosts(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _userPostsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }

        /// LIST VIEW
        if (!gridView) {
          return ListView.builder(
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
                likes: data['likesCount'],
                comments: data['commentsCount'],
                views: data['viewCount'],
                clubName: data['clubName'],
                isLiked:
                    (data['likedBy'] ?? []).contains(currentUserId),
              );
            },
          );
        }

        /// GRID VIEW
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final data = posts[index].data() as Map<String, dynamic>;

            return data['imageUrl'] != null &&
                    data['imageUrl'].toString().isNotEmpty
                ? Image.network(
                    data['imageUrl'],
                    fit: BoxFit.cover,
                  )
                : Container(color: Colors.grey.shade300);
          },
        );
      },
    );
  }
}
