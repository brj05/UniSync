import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';
import '../models/post_model.dart';
import '../services/session_service.dart';
import 'club_public_profile_screen.dart';
import '../screens/profile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final PostService postService = PostService();

  String query = "";

  final Set<String> _viewedPostIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: _searchField(),
      ),

      body: query.isEmpty ? _defaultFeed() : _searchResults(),
    );
  }

  // ================= SEARCH FIELD =================
  Widget _searchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (val) {
        setState(() {
          query = val.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: "Search users, clubs...",
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.search),
      ),
    );
  }

  // ================= DEFAULT FEED (🔥 SAME AS HOME) =================
  Widget _defaultFeed() {
    return FutureBuilder(
      future: SessionService.getSession(),
      builder: (context, sessionSnap) {
        if (!sessionSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId = sessionSnap.data!['phone']!;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .snapshots(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData =
                userSnap.data!.data() as Map<String, dynamic>;

            final currentUserName =
                userData['name'] ?? 'User';
            final currentUserAvatar =
                userData['avatar'] ??
                'https://ui-avatars.com/api/?name=User';

            return StreamBuilder<List<PostModel>>(
              stream: postService.streamPosts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final posts = snapshot.data!;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];

                    if (!_viewedPostIds.contains(post.id)) {
                      _viewedPostIds.add(post.id);
                      postService.incrementView(post.id);
                    }

                    return PostCard(
                      postId: post.id,
                      authorId: post.authorId,
                      currentUserId: currentUserId,
                      currentUserName: currentUserName,
                      currentUserAvatar: currentUserAvatar,
                      authorName: post.authorName,
                      authorAvatar: post.authorAvatar,
                      caption: post.caption,
                      imageUrl: post.imageUrl.isEmpty
                          ? null
                          : post.imageUrl,
                      likes: post.likesCount,
                      comments: post.commentsCount,
                      views: post.viewCount,
                      clubName: post.isClubPost
                          ? post.clubName
                          : null,
                      isLiked: post.isLikedBy(currentUserId),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // ================= SEARCH RESULTS =================
  Widget _searchResults() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _usersResult(),
          _clubsResult(),
        ],
      ),
    );
  }

  // ================= USERS =================
  Widget _usersResult() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        final results = snap.data!.docs.where((doc) {
          final name = (doc['name'] ?? "").toString().toLowerCase();
          return name.contains(query);
        }).toList();

        if (results.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text("Users",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            ...results.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['avatar'] != null
                      ? NetworkImage(data['avatar'])
                      : null,
                  child: data['avatar'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(data['name'] ?? ""),

                onTap: () {
                  // 🔥 FIXED NAVIGATION
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(
                        userId: doc.id, // 🔥 IMPORTANT
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  // ================= CLUBS =================
  Widget _clubsResult() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('clubs').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();

        final results = snap.data!.docs.where((doc) {
          final name = (doc['name'] ?? "").toString().toLowerCase();
          return name.contains(query);
        }).toList();

        if (results.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text("Clubs",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            ...results.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: data['image'] != null
                      ? NetworkImage(data['image'])
                      : null,
                  child: data['image'] == null
                      ? const Icon(Icons.group)
                      : null,
                ),
                title: Text(data['name'] ?? ""),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClubPublicProfileScreen(
                        clubId: doc.id,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }
}