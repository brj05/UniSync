import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import 'club_profile_screen.dart';

class ClubPublicProfileScreen extends StatefulWidget {
  final String clubId;

  const ClubPublicProfileScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<ClubPublicProfileScreen> createState() =>
      _ClubPublicProfileScreenState();
}

class _ClubPublicProfileScreenState extends State<ClubPublicProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? myPhone;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    myPhone = await SessionService.getPhone();
    setState(() {
      loading = false;
    });
  }

  Future<void> _joinClub(Map<String, dynamic> clubData) async {
    if (myPhone == null) return;

    final members = List<String>.from(clubData['members'] ?? []);

    if (!members.contains(myPhone)) {
      members.add(myPhone!);

      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(widget.clubId)
          .update({'members': members});
    }
  }

  Future<void> _toggleFollow(Map<String, dynamic> clubData) async {
    if (myPhone == null) return;

    final followers = List<String>.from(clubData['followers'] ?? []);

    if (followers.contains(myPhone)) {
      followers.remove(myPhone);
    } else {
      followers.add(myPhone!);
    }

    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(widget.clubId)
        .update({'followers': followers});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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

        final clubData = snapshot.data!.data() as Map<String, dynamic>;

        final clubName = clubData['name'] ?? 'Club';
        final about = clubData['about'] ?? '';
        final adminName = clubData['adminName'] ?? 'Club Admin';

        final members = List<String>.from(clubData['members'] ?? []);
        final followers = List<String>.from(clubData['followers'] ?? []);

        final isJoined = members.contains(myPhone);
        final isFollowing = followers.contains(myPhone);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),

                CircleAvatar(
                  radius: 45,
                  backgroundColor: const Color(0xFF8B5CF6),
                  child: Text(
                    clubName.isNotEmpty
                        ? clubName[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  clubName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  adminName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${members.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Members'),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '${followers.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Followers'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing
                                  ? Colors.grey.shade200
                                  : const Color(0xFF8B5CF6),
                              foregroundColor: isFollowing
                                  ? Colors.black
                                  : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _toggleFollow(clubData),
                            child: Text(
                              isFollowing ? 'Unfollow' : 'Follow',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (!isJoined) {
                                await _joinClub(clubData);
                              } else {
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClubProfileScreen(
                                      clubId: widget.clubId,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              isJoined ? 'Message' : 'Join',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      about,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF8B5CF6),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF8B5CF6),
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.person_pin_outlined)),
                  ],
                ),

                SizedBox(
                  height: 500,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('clubs')
                            .doc(widget.clubId)
                            .collection('posts')
                            .orderBy('time', descending: true)
                            .snapshots(),
                        builder: (context, postSnapshot) {
                          if (!postSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final posts = postSnapshot.data!.docs;

                          if (posts.isEmpty) {
                            return const Center(
                              child: Text('No posts yet'),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: posts.length,
                            itemBuilder: (_, index) {
                              final data = posts[index].data()
                                  as Map<String, dynamic>;

                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDE7F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: Text(
                                    data['text'] ?? '',
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('clubs')
                            .doc(widget.clubId)
                            .collection('posts')
                            .where('taggedUsers',
                                arrayContains: myPhone ?? '')
                            .snapshots(),
                        builder: (context, taggedSnapshot) {
                          if (!taggedSnapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final tagged = taggedSnapshot.data!.docs;

                          if (tagged.isEmpty) {
                            return const Center(
                              child: Text('No tagged posts'),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(10),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: tagged.length,
                            itemBuilder: (_, index) {
                              final data = tagged[index].data()
                                  as Map<String, dynamic>;

                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCEBFF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: Text(
                                    data['text'] ?? '',
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}