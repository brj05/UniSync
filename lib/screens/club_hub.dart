import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'create_club.dart';
import 'club_profile_screen.dart';
import '../widgets/home_app_bar.dart';
import '../services/session_service.dart';

class ClubHubScreen extends StatefulWidget {
  const ClubHubScreen({super.key});

  @override
  State<ClubHubScreen> createState() => _ClubHubScreenState();
}

class _ClubHubScreenState extends State<ClubHubScreen> {
  String? myPhone;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    myPhone = await SessionService.getPhone();
    setState(() {});
  }

  Future<void> _joinClub(DocumentSnapshot club) async {
    if (myPhone == null) return;

    final members = List<String>.from(club['members'] ?? []);

    if (!members.contains(myPhone)) {
      members.add(myPhone!);

      await FirebaseFirestore.instance
          .collection('clubs')
          .doc(club.id)
          .update({'members': members});
    }
  }

  Future<void> _leaveClub(DocumentSnapshot club) async {
    if (myPhone == null) return;

    final members = List<String>.from(club['members'] ?? []);
    members.remove(myPhone);

    await FirebaseFirestore.instance
        .collection('clubs')
        .doc(club.id)
        .update({'members': members});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildHomeAppBar(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B5CF6),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateClubScreen(),
            ),
          );
        },
      ),
      body: myPhone == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clubs')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clubs = snapshot.data!.docs;

                final myClubs = clubs.where((club) {
                  final members = List<String>.from(club['members'] ?? []);
                  return members.contains(myPhone);
                }).toList();

                final discoverClubs = clubs.where((club) {
                  final members = List<String>.from(club['members'] ?? []);
                  return !members.contains(myPhone);
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'My Clubs',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (myClubs.isEmpty)
                      const Text('You have not joined any club yet.'),

                    ...myClubs.map(
                      (club) => _clubTile(
                        club,
                        joined: true,
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'Discover Clubs',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...discoverClubs.map(
                      (club) => _clubTile(
                        club,
                        joined: false,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _clubTile(DocumentSnapshot club, {required bool joined}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: const CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFF8B5CF6),
          child: Icon(Icons.groups, color: Colors.white),
        ),
        title: Text(
          club['name'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        subtitle: Text(joined ? 'Member' : 'Public Club'),
        trailing: joined
            ? const Icon(Icons.chevron_right)
            : IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _joinClub(club),
              ),
        onTap: joined
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClubProfileScreen(
                      clubId: club.id,
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }
}